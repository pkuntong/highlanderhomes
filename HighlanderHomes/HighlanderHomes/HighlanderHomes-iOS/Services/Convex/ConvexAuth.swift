import Foundation
import Combine
import AuthenticationServices
import CryptoKit

/// Convex Authentication Service
/// Handles email/password and Apple Sign-In authentication
@MainActor
class ConvexAuth: ObservableObject {
    static let shared = ConvexAuth()

    // MARK: - Published State
    @Published var currentUser: ConvexUser?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    @Published var authError: String?

    // MARK: - Private
    private let client = ConvexClient.shared
    private let tokenKey = "convex_auth_token"
    private let userKey = "convex_user"

    private init() {
        loadStoredAuth()
    }

    // MARK: - Stored Auth
    private func loadStoredAuth() {
        if let token = UserDefaults.standard.string(forKey: tokenKey),
           let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(ConvexUser.self, from: userData) {
            client.setAuthToken(token)
            currentUser = user
            isAuthenticated = true

            // Verify token is still valid
            Task {
                await verifyToken()
            }
        }
        isLoading = false
    }

    private func saveAuth(token: String, user: ConvexUser) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
        client.setAuthToken(token)
        currentUser = user
        isAuthenticated = true
    }

    private func clearAuth() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: ConvexConfig.dataOwnerUserIdDefaultsKey)
        client.clearAuth()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Email Authentication
    func signUp(email: String, password: String, name: String) async throws -> Bool {
        authError = nil

        let response: SignUpResponse = try await client.action(
            "auth:signUp",
            args: [
                "email": email,
                "password": password,
                "name": name
            ]
        )

        let verificationSent = response.verificationSent ?? false
        if !verificationSent {
            saveAuth(token: response.token, user: response.user)
        }
        HapticManager.shared.success()
        return verificationSent
    }

    func signIn(email: String, password: String) async throws {
        authError = nil

        let response: AuthResponse = try await client.action(
            "auth:signIn",
            args: [
                "email": email,
                "password": password
            ]
        )

        saveAuth(token: response.token, user: response.user)
        HapticManager.shared.success()
    }

    func signOut() {
        clearAuth()
        HapticManager.shared.impact(.medium)
    }

    func resetPassword(email: String) async throws {
        try await client.action(
            "auth:resetPassword",
            args: ["email": email]
        ) as EmptyConvexResponse

        HapticManager.shared.success()
    }

    // MARK: - Apple Sign In
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String) async throws {
        _ = nonce // Nonce is used for the Apple request itself; backend does not require it

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw ConvexError.notAuthenticated
        }

        // Extract name from Apple credential (only available on first sign-in)
        var name: String?
        if let fullName = credential.fullName {
            name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
        }

        let response: AuthResponse = try await client.action(
            "auth:signInWithApple",
            args: [
                "identityToken": tokenString,
                "name": name ?? "",
                "email": credential.email ?? ""
            ]
        )

        saveAuth(token: response.token, user: response.user)
        HapticManager.shared.success()
    }

    // MARK: - Token Verification
    private func verifyToken() async {
        guard let userId = currentUser?.id else {
            clearAuth()
            return
        }

        do {
            let user: ConvexUser? = try await client.query(
                ConvexConfig.Functions.getCurrentUser,
                args: ["userId": userId]
            )

            if let user {
                currentUser = user
                isAuthenticated = true
            } else {
                clearAuth()
            }
        } catch {
            // Token invalid, clear auth
            clearAuth()
        }
    }

    // MARK: - Update Profile
    func updateProfile(name: String?, email: String?, avatarURL: String?) async throws {
        guard let userId = currentUser?.id else {
            throw ConvexError.notAuthenticated
        }

        var args: [String: Any] = ["userId": userId]
        if let name = name { args["name"] = name }
        if let email = email { args["email"] = email }
        if let avatarURL = avatarURL { args["avatarURL"] = avatarURL }

        let user: ConvexUser = try await client.mutation(
            ConvexConfig.Functions.updateUser,
            args: args
        )

        currentUser = user

        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }

    func deleteAccount() async throws {
        guard let userId = currentUser?.id else {
            throw ConvexError.notAuthenticated
        }

        try await client.mutation(
            ConvexConfig.Functions.deleteUser,
            args: ["userId": userId]
        ) as EmptyConvexResponse

        clearAuth()
    }

    // MARK: - Email Verification
    func sendVerificationEmail(email: String) async throws {
        try await client.action(
            "auth:sendVerificationEmail",
            args: ["email": email]
        ) as EmptyConvexResponse
    }

    func verifyEmail(code: String, email: String) async throws {
        let response: AuthResponse = try await client.action(
            "auth:verifyEmail",
            args: [
                "email": email,
                "code": code
            ]
        )
        saveAuth(token: response.token, user: response.user)
    }
}

// MARK: - Auth Models
struct AuthResponse: Decodable {
    let token: String
    let user: ConvexUser
}

struct SignUpResponse: Decodable {
    let token: String
    let user: ConvexUser
    let verificationSent: Bool?
}

struct ConvexUser: Codable, Identifiable {
    let id: String
    var name: String
    var email: String
    var avatarURL: String?
    var isPremium: Bool
    var emailVerified: Bool?
    var createdAt: Date
    var lastLoginAt: Date?

    // Computed
    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, email, avatarURL, isPremium, emailVerified, createdAt, lastLoginAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
        emailVerified = try container.decodeIfPresent(Bool.self, forKey: .emailVerified)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        lastLoginAt = try container.decodeIfPresent(Date.self, forKey: .lastLoginAt)
    }

    init(
        id: String,
        name: String,
        email: String,
        avatarURL: String?,
        isPremium: Bool,
        emailVerified: Bool?,
        createdAt: Date,
        lastLoginAt: Date?
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.isPremium = isPremium
        self.emailVerified = emailVerified
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
}

// MARK: - Apple Sign In Helpers
extension ConvexAuth {
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

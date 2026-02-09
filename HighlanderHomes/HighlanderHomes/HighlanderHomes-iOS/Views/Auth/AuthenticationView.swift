import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit

struct AuthenticationView: View {
    @StateObject private var convexAuth = ConvexAuth.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showForgotPassword = false
    @State private var showVerifyEmail = false
    @State private var currentNonce: String?
    @State private var showTerms = false
    @State private var showPrivacy = false

    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.xxl) {
                    // Logo & Welcome
                    VStack(spacing: Theme.Spacing.md) {
                        // App Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Theme.Gradients.emeraldGlow)
                                .frame(width: 76, height: 76)
                                .shadow(color: Theme.Colors.emerald.opacity(0.35), radius: 14, y: 6)

                            Image("HighlanderLogo")
                                .resizable()
                                .scaledToFit()
                                .padding(10)
                        }
                        .padding(.top, Theme.Spacing.xl)

                        Text("Highlander Homes")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text("Property management, reimagined")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }

                    // Auth Form
                    VStack(spacing: Theme.Spacing.lg) {
                        // Tab Selector
                        AuthTabSelector(isSignUp: $isSignUp)

                        // Form Fields
                        VStack(spacing: Theme.Spacing.md) {
                            if isSignUp {
                                AuthTextField(
                                    icon: "person.fill",
                                    placeholder: "Full Name",
                                    text: $name,
                                    isSecure: false
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            AuthTextField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $email,
                                isSecure: false,
                                keyboardType: .emailAddress
                            )

                            AuthTextField(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $password,
                                isSecure: true
                            )

                            if !isSignUp {
                                HStack {
                                    Spacer()
                                    Button("Forgot Password?") {
                                        showForgotPassword = true
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.Colors.emerald)
                                }
                            }
                        }

                        // Error Message
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Theme.Colors.alertRed)
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.alertRed)
                            }
                            .padding(Theme.Spacing.sm)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                    .fill(Theme.Colors.alertRed.opacity(0.1))
                            }
                        }

                        if let success = successMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.Colors.emerald)
                                Text(success)
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.emerald)
                            }
                            .padding(Theme.Spacing.sm)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                    .fill(Theme.Colors.emerald.opacity(0.1))
                            }
                        }

                        // Submit Button
                        Button {
                            Task { await handleEmailAuth() }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background {
                                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                    .fill(Theme.Gradients.emeraldGlow)
                            }
                            .shadow(color: Theme.Colors.emerald.opacity(0.4), radius: 12, y: 4)
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)

                        // Verify Email (if needed)
                        Button("Verify Email") {
                            showVerifyEmail = true
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.emerald)

                        // Divider
                        HStack(spacing: Theme.Spacing.md) {
                            Rectangle()
                                .fill(Theme.Colors.slate700)
                                .frame(height: 1)
                            Text("or")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textMuted)
                            Rectangle()
                                .fill(Theme.Colors.slate700)
                                .frame(height: 1)
                        }

                        // Apple Sign In
                        #if targetEnvironment(simulator)
                        Text("Sign in with Apple is unavailable on Simulator. Use email sign in.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        #else
                        SignInWithAppleButton(
                            onRequest: configureAppleRequest,
                            onCompletion: handleAppleSignIn
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 54)
                        .cornerRadius(Theme.Radius.medium)
                        #endif
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Terms
                    VStack(spacing: 8) {
                        Text("By continuing, you agree to our")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textMuted)

                        HStack(spacing: 4) {
                            Button("Terms of Service") { showTerms = true }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.emerald)

                            Text("and")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.textMuted)

                            Button("Privacy Policy") { showPrivacy = true }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.emerald)
                        }
                    }
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSignUp)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(email: $email)
        }
        .sheet(isPresented: $showVerifyEmail) {
            VerifyEmailFromAuthSheet(email: $email)
        }
        .sheet(isPresented: $showTerms) {
            LegalDocumentSheet(
                title: "Terms of Service",
                bodyText: LegalDocuments.terms
            )
        }
        .sheet(isPresented: $showPrivacy) {
            LegalDocumentSheet(
                title: "Privacy Policy",
                bodyText: LegalDocuments.privacy
            )
        }
    }

    // MARK: - Form Validation
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = isPasswordValid(password)

        if isSignUp {
            return emailValid && passwordValid && !name.isEmpty
        }
        return emailValid && passwordValid
    }

    private func isPasswordValid(_ value: String) -> Bool {
        guard value.count >= 8 else { return false }
        let hasLetter = value.rangeOfCharacter(from: .letters) != nil
        let hasNumber = value.rangeOfCharacter(from: .decimalDigits) != nil
        return hasLetter && hasNumber
    }

    // MARK: - Email Auth
    private func handleEmailAuth() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        HapticManager.shared.impact(.medium)

        do {
            if isSignUp {
                let verificationSent = try await convexAuth.signUp(email: email, password: password, name: name)
                if verificationSent {
                    successMessage = "Verification code sent to your email."
                    showVerifyEmail = true
                } else {
                    errorMessage = "Couldn't send verification email. You can resend it from Profile."
                    showVerifyEmail = true
                }
            } else {
                try await convexAuth.signIn(email: email, password: password)
            }
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }

    // MARK: - Apple Sign In
    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce else {
                errorMessage = "Failed to get Apple credentials"
                return
            }

            Task {
                isLoading = true
                do {
                    try await convexAuth.signInWithApple(credential: appleIDCredential, nonce: nonce)
                    HapticManager.shared.success()
                } catch {
                    errorMessage = error.localizedDescription
                    HapticManager.shared.error()
                }
                isLoading = false
            }

        case .failure(let error):
            let nsError = error as NSError
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                errorMessage = appleSignInErrorMessage(for: nsError)
            }
        }
    }

    private func appleSignInErrorMessage(for error: NSError) -> String {
        if error.domain == ASAuthorizationError.errorDomain,
           let code = ASAuthorizationError.Code(rawValue: error.code) {
            switch code {
            case .canceled:
                return "Sign in was canceled."
            case .failed, .invalidResponse, .notHandled, .unknown:
                return "Sign in with Apple failed. Make sure the Sign in with Apple capability is enabled for this bundle ID and try again."
            @unknown default:
                return "Sign in with Apple failed. Please try again."
            }
        }

        if error.domain == "AKAuthenticationError" {
            return "Sign in with Apple requires a device passcode and a valid Apple ID on this device."
        }

        return error.localizedDescription
    }

    // MARK: - Crypto Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Auth Tab Selector
struct AuthTabSelector: View {
    @Binding var isSignUp: Bool
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Sign In", isSelected: !isSignUp, namespace: animation) {
                isSignUp = false
            }

            TabButton(title: "Sign Up", isSelected: isSignUp, namespace: animation) {
                isSignUp = true
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate800)
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .fill(Theme.Colors.emerald)
                            .matchedGeometryEffect(id: "authTab", in: namespace)
                    }
                }
        }
    }
}

// MARK: - Auth Text Field
struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool
    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isFocused ? Theme.Colors.emerald : Theme.Colors.textMuted)
                .frame(width: 24)

            if isSecure && !showPassword {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }

            if isSecure {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
        }
        .font(.system(size: 16))
        .foregroundColor(Theme.Colors.textPrimary)
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate800)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .stroke(isFocused ? Theme.Colors.emerald : Theme.Colors.slate700, lineWidth: 1)
                }
        }
    }
}

// MARK: - Forgot Password Sheet
struct ForgotPasswordSheet: View {
    @Binding var email: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.lg) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Theme.Gradients.emeraldGlow)
                        .padding(.top, Theme.Spacing.xl)

                    Text("Reset Password")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("Enter your email and we'll send you a link to reset your password")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    AuthTextField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email,
                        isSecure: false,
                        keyboardType: .emailAddress
                    )
                    .padding(.horizontal, Theme.Spacing.lg)

                    if let success = successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(success)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.emerald)
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .fill(Theme.Colors.emerald.opacity(0.1))
                        }
                        .padding(.horizontal)
                    }

                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.alertRed)
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .fill(Theme.Colors.alertRed.opacity(0.1))
                        }
                        .padding(.horizontal)
                    }

                    Button {
                        Task { await resetPassword() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Reset Link")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .fill(Theme.Gradients.emeraldGlow)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .disabled(email.isEmpty || isLoading)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
    }

    private func resetPassword() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            try await ConvexAuth.shared.resetPassword(email: email)
            successMessage = "Reset link sent to \(email)"
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }
}

// MARK: - Verify Email Sheet (Auth)
struct VerifyEmailFromAuthSheet: View {
    @Binding var email: String
    @EnvironmentObject var convexAuth: ConvexAuth
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.lg) {
                    Text("Enter the 6‑digit code sent to:")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)

                    AuthTextField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email,
                        isSecure: false,
                        keyboardType: .emailAddress
                    )
                    .padding(.horizontal, Theme.Spacing.lg)

                    AuthTextField(
                        icon: "key.fill",
                        placeholder: "Verification Code",
                        text: $code,
                        isSecure: false,
                        keyboardType: .numberPad
                    )
                    .padding(.horizontal, Theme.Spacing.lg)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.alertRed)
                    }

                    Button {
                        Task {
                            isLoading = true
                            errorMessage = nil
                            do {
                                try await convexAuth.verifyEmail(code: code, email: email)
                                HapticManager.shared.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.shared.error()
                            }
                            isLoading = false
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Verify Email")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .fill(Theme.Gradients.emeraldGlow)
                        }
                    }
                    .disabled(email.isEmpty || code.isEmpty || isLoading)
                    .opacity((email.isEmpty || code.isEmpty) ? 0.6 : 1)

                    Button("Resend Code") {
                        Task {
                            do {
                                try await convexAuth.sendVerificationEmail(email: email)
                                errorMessage = "Verification code sent."
                                HapticManager.shared.success()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.shared.error()
                            }
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.emerald)
                }
                .padding(.vertical, Theme.Spacing.xl)
            }
            .navigationTitle("Verify Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
}

struct LegalDocumentSheet: View {
    let title: String
    let bodyText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(bodyText)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
    }
}

enum LegalDocuments {
    static let terms = """
Effective date: February 9, 2026

1. Acceptance of Terms
By accessing or using Highlander Homes, you agree to these Terms of Service.

2. Use of the Service
You agree to use the service only for lawful purposes and in compliance with applicable laws.

3. Accounts
You are responsible for maintaining the confidentiality of your account credentials.

4. Subscription & Billing
Paid plans are billed on a recurring basis. You can cancel at any time.

5. Termination
We may suspend or terminate access if you violate these terms.

6. Contact
Questions? Email highlanderhomes22@gmail.com.
"""

    static let privacy = """
Effective date: February 9, 2026

1. Information We Collect
We collect information you provide directly, such as account and property data.

2. How We Use Information
We use your information to provide, maintain, and improve the service.

3. Sharing
We do not sell your personal information.

4. Data Security
We take reasonable measures to protect your information.

5. Contact
Questions? Email highlanderhomes22@gmail.com.
"""
}

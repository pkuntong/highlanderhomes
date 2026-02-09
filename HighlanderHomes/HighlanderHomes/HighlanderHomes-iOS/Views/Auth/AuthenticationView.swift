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
    @State private var animateGradient = false
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Premium Animated Gradient Background
            AnimatedGradientBackground(animate: $animateGradient)
                .ignoresSafeArea()

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Section with Logo
                    HeroSection()
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : -30)
                    
                    // Auth Card
                    AuthCardView(
                        isSignUp: $isSignUp,
                        email: $email,
                        password: $password,
                        name: $name,
                        isLoading: $isLoading,
                        errorMessage: $errorMessage,
                        successMessage: $successMessage,
                        showForgotPassword: $showForgotPassword,
                        showVerifyEmail: $showVerifyEmail,
                        currentNonce: $currentNonce,
                        onSubmit: { Task { await handleEmailAuth() } },
                        onAppleRequest: configureAppleRequest,
                        onAppleCompletion: handleAppleSignIn
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    
                    // Terms Footer
                    TermsFooter(showTerms: $showTerms, showPrivacy: $showPrivacy)
                        .opacity(showContent ? 1 : 0)
                        .padding(.top, Theme.Spacing.xl)
                        .padding(.bottom, Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateGradient = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                showContent = true
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isSignUp)
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

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @Binding var animate: Bool
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "0A0F1C"),
                    Color(hex: "0D1525"),
                    Color(hex: "111B2E")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Floating orbs
            GeometryReader { geo in
                // Top-left blue orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "3B82F6").opacity(0.4),
                                Color(hex: "3B82F6").opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(
                        x: animate ? -50 : -80,
                        y: animate ? -30 : -60
                    )
                    .blur(radius: 60)
                
                // Top-right emerald orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.Colors.emerald.opacity(0.35),
                                Theme.Colors.emerald.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 250, height: 250)
                    .offset(
                        x: geo.size.width - 120,
                        y: animate ? 80 : 50
                    )
                    .blur(radius: 50)
                
                // Bottom center purple orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "8B5CF6").opacity(0.3),
                                Color(hex: "8B5CF6").opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .frame(width: 350, height: 350)
                    .offset(
                        x: geo.size.width / 2 - 175,
                        y: geo.size.height - (animate ? 200 : 250)
                    )
                    .blur(radius: 70)
                    .animation(
                        .easeInOut(duration: 4).repeatForever(autoreverses: true),
                        value: animate
                    )
            }
            
            // Subtle grid pattern
            GeometryReader { geo in
                Path { path in
                    let gridSize: CGFloat = 40
                    for x in stride(from: 0, to: geo.size.width, by: gridSize) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, to: geo.size.height, by: gridSize) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.02), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - Hero Section
struct HeroSection: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: CGFloat = 0
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Premium Logo Container
            ZStack {
                // Glow effect
                Circle()
                    .fill(Theme.Colors.emerald.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                
                // Logo background
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1E293B"),
                                Color(hex: "0F172A")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.emerald.opacity(0.5),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(color: Theme.Colors.emerald.opacity(0.3), radius: 20, y: 8)

                Image("HighlanderLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
            }
            .padding(.top, Theme.Spacing.xxl)

            // Brand Name with gradient
            VStack(spacing: 6) {
                Text("Highlander Homes")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "CBD5E1")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Property management, reimagined")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.emeraldLight, Theme.Colors.emerald],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .padding(.bottom, Theme.Spacing.xl)
    }
}

// MARK: - Auth Card View
struct AuthCardView: View {
    @Binding var isSignUp: Bool
    @Binding var email: String
    @Binding var password: String
    @Binding var name: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    @Binding var successMessage: String?
    @Binding var showForgotPassword: Bool
    @Binding var showVerifyEmail: Bool
    @Binding var currentNonce: String?
    
    let onSubmit: () -> Void
    let onAppleRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onAppleCompletion: (Result<ASAuthorization, Error>) -> Void
    
    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 8 &&
            password.rangeOfCharacter(from: .letters) != nil &&
            password.rangeOfCharacter(from: .decimalDigits) != nil
        
        if isSignUp {
            return emailValid && passwordValid && !name.isEmpty
        }
        return emailValid && passwordValid
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Premium Tab Selector
            PremiumTabSelector(isSignUp: $isSignUp)
            
            // Form Fields
            VStack(spacing: Theme.Spacing.md) {
                if isSignUp {
                    PremiumTextField(
                        icon: "person.fill",
                        placeholder: "Full Name",
                        text: $name,
                        isSecure: false
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }

                PremiumTextField(
                    icon: "envelope.fill",
                    placeholder: "Email Address",
                    text: $email,
                    isSecure: false,
                    keyboardType: .emailAddress
                )

                PremiumTextField(
                    icon: "lock.fill",
                    placeholder: "Password",
                    text: $password,
                    isSecure: true
                )

                if !isSignUp {
                    HStack {
                        Spacer()
                        Button {
                            HapticManager.shared.selection()
                            showForgotPassword = true
                        } label: {
                            Text("Forgot Password?")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.Colors.emeraldLight, Theme.Colors.emerald],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .padding(.top, -Theme.Spacing.xs)
                }
            }

            // Error/Success Messages
            if let error = errorMessage {
                MessageBanner(message: error, type: .error)
            }

            if let success = successMessage {
                MessageBanner(message: success, type: .success)
            }

            // Submit Button
            PremiumButton(
                title: isSignUp ? "Create Account" : "Sign In",
                isLoading: isLoading,
                isEnabled: isFormValid
            ) {
                onSubmit()
            }
            
            // Verify Email Link
            Button {
                HapticManager.shared.selection()
                showVerifyEmail = true
            } label: {
                Text("Already have a verification code?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textMuted)
            }

            // Divider
            PremiumDivider()

            // Apple Sign In
            #if targetEnvironment(simulator)
            Text("Sign in with Apple is unavailable on Simulator")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            #else
            SignInWithAppleButton(
                onRequest: onAppleRequest,
                onCompletion: onAppleCompletion
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 56)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
            #endif
        }
        .padding(Theme.Spacing.lg)
        .background {
            // Glass morphism card
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial.opacity(0.8))
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "1E293B").opacity(0.9),
                                    Color(hex: "0F172A").opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
        }
    }
}

// MARK: - Premium Tab Selector
struct PremiumTabSelector: View {
    @Binding var isSignUp: Bool
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            PremiumTabButton(
                title: "Sign In",
                isSelected: !isSignUp,
                namespace: animation
            ) {
                isSignUp = false
            }

            PremiumTabButton(
                title: "Sign Up",
                isSelected: isSignUp,
                namespace: animation
            ) {
                isSignUp = true
            }
        }
        .padding(5)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "0F172A").opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.Colors.slate700.opacity(0.5), lineWidth: 1)
                }
        }
    }
}

struct PremiumTabButton: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : Theme.Colors.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Gradients.emeraldGlow)
                            .matchedGeometryEffect(id: "authTab", in: namespace)
                            .shadow(color: Theme.Colors.emerald.opacity(0.4), radius: 8, y: 2)
                    }
                }
        }
    }
}

// MARK: - Premium Text Field
struct PremiumTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool
    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 14) {
            // Icon with glow effect when focused
            ZStack {
                if isFocused {
                    Circle()
                        .fill(Theme.Colors.emerald.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .blur(radius: 8)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isFocused ? Theme.Colors.emerald : Theme.Colors.textMuted)
                    .frame(width: 24)
            }

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
                    HapticManager.shared.selection()
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
        }
        .font(.system(size: 17))
        .foregroundColor(Theme.Colors.textPrimary)
        .padding(.horizontal, 18)
        .frame(height: 60)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "0F172A").opacity(0.7))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused ?
                                AnyShapeStyle(Theme.Gradients.emeraldGlow) :
                                AnyShapeStyle(Theme.Colors.slate700.opacity(0.6)),
                            lineWidth: isFocused ? 2 : 1
                        )
                }
                .shadow(color: isFocused ? Theme.Colors.emerald.opacity(0.2) : .clear, radius: 12, y: 4)
        }
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Premium Button
struct PremiumButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            HapticManager.shared.impact(.medium)
            action()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                        .offset(x: isPressed ? 4 : 0)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background {
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Gradients.emeraldGlow)
                    
                    // Shine effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                }
            }
            .shadow(color: Theme.Colors.emerald.opacity(isEnabled ? 0.5 : 0.2), radius: 15, y: 6)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .disabled(isLoading || !isEnabled)
        .opacity(isEnabled ? 1 : 0.6)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .pressEvents {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }
}

// MARK: - Press Events Modifier
struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Premium Divider
struct PremiumDivider: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Theme.Colors.slate600],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            Text("or continue with")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.Colors.textMuted)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.slate600, Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Message Banner
struct MessageBanner: View {
    let message: String
    let type: MessageType
    
    enum MessageType {
        case error, success
        
        var color: Color {
            switch self {
            case .error: return Theme.Colors.alertRed
            case .success: return Theme.Colors.emerald
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.icon)
                .font(.system(size: 16))
            Text(message)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(type.color)
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(type.color.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

// MARK: - Terms Footer
struct TermsFooter: View {
    @Binding var showTerms: Bool
    @Binding var showPrivacy: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text("By continuing, you agree to our")
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textMuted)

            HStack(spacing: 4) {
                Button("Terms of Service") {
                    HapticManager.shared.selection()
                    showTerms = true
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.emerald)

                Text("and")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textMuted)

                Button("Privacy Policy") {
                    HapticManager.shared.selection()
                    showPrivacy = true
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.emerald)
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
                    // Icon with glow
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.emerald.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .blur(radius: 30)
                        
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Theme.Gradients.emeraldGlow)
                    }
                    .padding(.top, Theme.Spacing.xl)

                    VStack(spacing: 8) {
                        Text("Reset Password")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text("Enter your email and we'll send you\na link to reset your password")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    PremiumTextField(
                        icon: "envelope.fill",
                        placeholder: "Email Address",
                        text: $email,
                        isSecure: false,
                        keyboardType: .emailAddress
                    )
                    .padding(.horizontal, Theme.Spacing.lg)

                    if let success = successMessage {
                        MessageBanner(message: success, type: .success)
                            .padding(.horizontal)
                    }

                    if let error = errorMessage {
                        MessageBanner(message: error, type: .error)
                            .padding(.horizontal)
                    }

                    PremiumButton(
                        title: "Send Reset Link",
                        isLoading: isLoading,
                        isEnabled: !email.isEmpty
                    ) {
                        Task { await resetPassword() }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 17, weight: .semibold))
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
                    // Icon with glow
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.emerald.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .blur(radius: 30)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Theme.Gradients.emeraldGlow)
                    }
                    .padding(.top, Theme.Spacing.lg)
                    
                    VStack(spacing: 8) {
                        Text("Verify Email")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text("Enter the 6-digit code sent to your email")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: Theme.Spacing.md) {
                        PremiumTextField(
                            icon: "envelope.fill",
                            placeholder: "Email Address",
                            text: $email,
                            isSecure: false,
                            keyboardType: .emailAddress
                        )

                        PremiumTextField(
                            icon: "key.fill",
                            placeholder: "Verification Code",
                            text: $code,
                            isSecure: false,
                            keyboardType: .numberPad
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    if let error = errorMessage {
                        MessageBanner(message: error, type: error.contains("sent") ? .success : .error)
                            .padding(.horizontal)
                    }

                    PremiumButton(
                        title: "Verify Email",
                        isLoading: isLoading,
                        isEnabled: !email.isEmpty && !code.isEmpty
                    ) {
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
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    Button {
                        Task {
                            do {
                                try await convexAuth.sendVerificationEmail(email: email)
                                errorMessage = "Verification code sent!"
                                HapticManager.shared.success()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.shared.error()
                            }
                        }
                    } label: {
                        Text("Resend Code")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.Colors.emeraldLight, Theme.Colors.emerald],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    Spacer()
                }
            }
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
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 17, weight: .semibold))
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

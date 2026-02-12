import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var convexAuth: ConvexAuth
    @EnvironmentObject var dataService: ConvexDataService
    @Environment(\.dismiss) private var dismiss

    @AppStorage("app_appearance") private var appAppearanceRaw: String = AppAppearance.light.rawValue

    @State private var editedName = ""
    @State private var editedEmail = ""
    @State private var isSaving = false
    @State private var saveMessage: String?
    @State private var showDeleteConfirm = false
    @State private var showVerifySheet = false
    @State private var verificationMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var isUploadingAvatar = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isChangingPassword = false
    @State private var passwordMessage: String?
    @State private var showingPricing = false

    #if DEBUG
    @AppStorage(ConvexConfig.dataOwnerUserIdDefaultsKey) private var dataOwnerUserId: String = ""
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Profile Section
                        profileSection

                        // Plan Section
                        planSection

                        // Appearance Section
                        appearanceSection

                        // Account Section
                        accountSection

                        // Security Section
                        securitySection

                        // Email Verification
                        if convexAuth.currentUser?.emailVerified != true {
                            verificationSection
                        }

                        #if DEBUG
                        developerSection
                        #endif

                        // Danger Zone
                        dangerSection
                    }
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
        .onAppear {
            if let user = convexAuth.currentUser {
                editedName = user.name
                editedEmail = user.email
                if let avatarURL = user.avatarURL, let image = imageFromDataURL(avatarURL) {
                    avatarImage = image
                }
            }
        }
        .sheet(isPresented: $showVerifySheet) {
            if let email = convexAuth.currentUser?.email {
                VerifyEmailSheet(email: email)
            }
        }
        .sheet(isPresented: $showingPricing) {
            PricingView()
        }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await convexAuth.deleteAccount()
                        dismiss()
                    } catch {
                        HapticManager.shared.error()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data. This cannot be undone.")
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack {
                    Circle()
                        .fill(Theme.Gradients.emeraldGlow)
                        .frame(width: 100, height: 100)

                    if let avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                    } else if let user = convexAuth.currentUser {
                        Text(user.initials)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }

                    if isUploadingAvatar {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 100, height: 100)
                            .overlay(ProgressView().tint(.white))
                    }

                    // Camera badge
                    Circle()
                        .fill(Theme.Colors.slate800)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.emerald)
                        }
                        .offset(x: 35, y: 35)
                }
            }
            .onChange(of: selectedPhotoItem) { _ in
                Task { await updateAvatarFromSelection() }
            }

            if let user = convexAuth.currentUser {
                Text(user.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(user.email)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)

                if user.isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("Premium")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(Theme.Colors.gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background { Capsule().fill(Theme.Colors.gold.opacity(0.15)) }
                }
            }
        }
        .padding(.top, Theme.Spacing.xl)
    }

    // MARK: - Plan Section
    private var planSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Plan")

            let isPremium = convexAuth.currentUser?.isPremium == true

            VStack(alignment: .leading, spacing: 6) {
                Text(isPremium ? "Pro Plan" : "Free Plan")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text(isPremium ? "Unlimited properties" : "Up to 3 properties")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .fill(Theme.Colors.slate800)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium)
                            .stroke(Theme.Colors.slate700, lineWidth: 1)
                    }
            }

            Button(isPremium ? "Manage Subscription" : "Upgrade to Pro") {
                showingPricing = true
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isPremium ? Theme.Colors.textSecondary : Theme.Colors.emerald)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(Theme.Colors.slate600, lineWidth: isPremium ? 1 : 0)
                    .fill(isPremium ? Color.clear : Theme.Colors.emerald.opacity(0.15))
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Appearance Section
    private var appearanceSection: some View {
        let selected = AppAppearance(rawValue: appAppearanceRaw) ?? .light

        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Appearance")

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(AppAppearance.allCases) { appearance in
                    Button {
                        HapticManager.shared.selection()
                        appAppearanceRaw = appearance.rawValue
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: appearance.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(appearance.label)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(selected == appearance ? .white : Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .fill(selected == appearance ? Theme.Colors.emerald : Theme.Colors.slate800)
                                .overlay {
                                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                        .stroke(Theme.Colors.slate700, lineWidth: selected == appearance ? 0 : 1)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Default is Light. Switch to Dark anytime in Settings.")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textMuted)
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Account")

            FormField(label: "Full Name", text: $editedName, placeholder: "Your name")
            FormField(label: "Email", text: $editedEmail, placeholder: "you@example.com", keyboard: .emailAddress)

            Button {
                Task { await saveProfile() }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save Changes")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .fill(Theme.Colors.emerald)
                }
            }

            if let message = saveMessage {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(message.contains("updated") ? Theme.Colors.emerald : Theme.Colors.alertRed)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Security")

            SecureField("Current Password", text: $currentPassword)
                .textFieldStyle(.roundedBorder)

            SecureField("New Password", text: $newPassword)
                .textFieldStyle(.roundedBorder)

            SecureField("Confirm New Password", text: $confirmPassword)
                .textFieldStyle(.roundedBorder)

            Button {
                Task { await changePassword() }
            } label: {
                HStack {
                    if isChangingPassword {
                        ProgressView().tint(Theme.Colors.textPrimary)
                    } else {
                        Text("Update Password")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .fill(Theme.Colors.slate700)
                }
            }
            .disabled(!canChangePassword || isChangingPassword)
            .opacity(canChangePassword ? 1 : 0.6)

            if let message = passwordMessage {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(message.contains("updated") ? Theme.Colors.emerald : Theme.Colors.alertRed)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Verification Section
    private var verificationSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Theme.Colors.warningAmber)
                Text("Email not verified")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.warningAmber)
            }

            if let msg = verificationMessage {
                Text(msg)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            HStack(spacing: Theme.Spacing.md) {
                Button {
                    Task {
                        do {
                            try await convexAuth.sendVerificationEmail(email: convexAuth.currentUser?.email ?? "")
                            verificationMessage = "Code sent."
                            HapticManager.shared.success()
                        } catch {
                            verificationMessage = error.localizedDescription
                        }
                    }
                } label: {
                    Text("Resend Code")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .fill(Theme.Colors.slate700)
                        }
                }

                Button {
                    showVerifySheet = true
                } label: {
                    Text("Enter Code")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.emerald)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .stroke(Theme.Colors.emerald, lineWidth: 1)
                        }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.warningAmber.opacity(0.1))
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Danger Section
    private var dangerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Sign Out
            Button {
                HapticManager.shared.impact(.medium)
                convexAuth.signOut()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .fill(Theme.Colors.slate700)
                }
            }

            // Delete Account
            Button {
                showDeleteConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Account")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.alertRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .stroke(Theme.Colors.alertRed.opacity(0.5), lineWidth: 1)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    #if DEBUG
    // MARK: - Developer Section
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Developer")

            FormField(label: "Data Owner User ID", text: $dataOwnerUserId, placeholder: "Convex user _id")

            Text("Use the user _id from Convex dashboard to load existing data.")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textMuted)

            Button {
                Task { await dataService.loadAllData() }
            } label: {
                Text("Reload Data")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium)
                            .fill(Theme.Colors.slate700)
                    }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }
    #endif

    // MARK: - Actions
    private func saveProfile() async {
        isSaving = true
        saveMessage = nil
        do {
            try await convexAuth.updateProfile(
                name: editedName.isEmpty ? nil : editedName,
                email: editedEmail.isEmpty ? nil : editedEmail,
                avatarURL: nil
            )
            saveMessage = "Profile updated."
            HapticManager.shared.success()
        } catch {
            saveMessage = error.localizedDescription
            HapticManager.shared.error()
        }
        isSaving = false
    }

    private func updateAvatarFromSelection() async {
        guard let item = selectedPhotoItem else { return }
        isUploadingAvatar = true
        defer { isUploadingAvatar = false }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                avatarImage = image
                if let dataURL = dataURLFromImage(image) {
                    try await convexAuth.updateProfile(name: nil, email: nil, avatarURL: dataURL)
                }
            }
        } catch {
            HapticManager.shared.error()
        }
    }

    private func dataURLFromImage(_ image: UIImage) -> String? {
        guard let jpeg = image.jpegData(compressionQuality: 0.7) else { return nil }
        return "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
    }

    private func imageFromDataURL(_ dataURL: String) -> UIImage? {
        guard let commaIndex = dataURL.firstIndex(of: ",") else { return nil }
        let base64 = String(dataURL[dataURL.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    private var canChangePassword: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        newPassword == confirmPassword
    }

    private func changePassword() async {
        guard !isChangingPassword else { return }
        passwordMessage = nil

        guard newPassword == confirmPassword else {
            passwordMessage = "Passwords do not match."
            return
        }

        guard isPasswordValid(newPassword) else {
            passwordMessage = "Password must be at least 8 characters and include letters and numbers."
            return
        }

        isChangingPassword = true
        do {
            try await convexAuth.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            passwordMessage = "Password updated."
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
        } catch {
            passwordMessage = error.localizedDescription
        }
        isChangingPassword = false
    }

    private func isPasswordValid(_ value: String) -> Bool {
        guard value.count >= 8 else { return false }
        let hasLetter = value.rangeOfCharacter(from: .letters) != nil
        let hasNumber = value.rangeOfCharacter(from: .decimalDigits) != nil
        return hasLetter && hasNumber
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Theme.Colors.textMuted)
            .tracking(1.2)
    }
}

#Preview {
    SettingsView()
        .environmentObject(ConvexAuth.shared)
        .environmentObject(ConvexDataService.shared)
}

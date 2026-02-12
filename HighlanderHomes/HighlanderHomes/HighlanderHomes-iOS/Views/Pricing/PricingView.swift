import SwiftUI
import StoreKit

struct PricingView: View {
    @EnvironmentObject var convexAuth: ConvexAuth
    @Environment(\.dismiss) private var dismiss

    @StateObject private var subscriptions = SubscriptionManager.shared
    @State private var isProcessing = false
    @State private var message: String?

    private let freeLimit = 3
    private let ownerEmail = "highlanderhomes22@gmail.com"
    private let termsURL = URL(string: "https://www.highlanderhomes.org/terms")!
    private let privacyURL = URL(string: "https://www.highlanderhomes.org/privacy")!

    private var isOwner: Bool {
        convexAuth.currentUser?.email.lowercased() == ownerEmail
    }

    private var isPremium: Bool {
        convexAuth.currentUser?.isPremium == true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        VStack(spacing: Theme.Spacing.sm) {
                            Text("Highlander Homes Pro")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text("Unlimited properties and full access.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }

                        PricingCard(title: "Free", subtitle: "Great for getting started", price: "Free", bullets: [
                            "Up to \(freeLimit) properties",
                            "Basic maintenance & transactions",
                            "Email support"
                        ], isHighlighted: false)

                        PricingCard(
                            title: "Pro",
                            subtitle: "For growing portfolios",
                            price: subscriptions.product?.displayPrice ?? "$9.99",
                            priceSuffix: "/month",
                            bullets: [
                                "Unlimited properties",
                                "Full document vault access",
                                "Priority support",
                                "Exports & reports"
                            ],
                            isHighlighted: true
                        )

                        if isOwner {
                            Text("Owner account has full access.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }

                        if let message {
                            Text(message)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.alertRed)
                        }

                        VStack(spacing: Theme.Spacing.md) {
                            if isPremium {
                                Button("Manage Subscription") {
                                    subscriptions.openManageSubscriptions()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            } else {
                                Button {
                                    Task { await startPurchase() }
                                } label: {
                                    if isProcessing {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text("Start Pro Subscription")
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(isProcessing)

                                Button("Restore Purchase") {
                                    Task { await restorePurchase() }
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                .disabled(isProcessing)
                            }

                            VStack(spacing: 8) {
                                Text("Payment will be charged to your Apple ID account. Subscription renews automatically unless canceled at least 24 hours before the end of the current period.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.textMuted)
                                    .multilineTextAlignment(.center)

                                HStack(spacing: 10) {
                                    Link("Terms", destination: termsURL)
                                    Text("•")
                                        .foregroundColor(Theme.Colors.textMuted)
                                    Link("Privacy", destination: privacyURL)
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.emerald)
                            }

                            Button("Close") { dismiss() }
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Pricing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        .task {
            await subscriptions.loadProduct()
            await subscriptions.refreshEntitlements()
        }
    }

    private func startPurchase() async {
        isProcessing = true
        message = nil
        do {
            try await subscriptions.purchase()
            if subscriptions.hasActiveSubscription {
                try await convexAuth.setPremiumStatus(isPremium: true)
                dismiss()
            }
        } catch {
            let description = (error as? SubscriptionError)?.errorDescription ?? error.localizedDescription
            if description != SubscriptionError.cancelled.errorDescription {
                message = description
            }
        }
        isProcessing = false
    }

    private func restorePurchase() async {
        isProcessing = true
        message = nil
        do {
            try await subscriptions.restore()
            if subscriptions.hasActiveSubscription {
                try await convexAuth.setPremiumStatus(isPremium: true)
                dismiss()
            } else {
                message = "No active subscription found."
            }
        } catch {
            message = error.localizedDescription
        }
        isProcessing = false
    }
}

private struct PricingCard: View {
    let title: String
    let subtitle: String
    let price: String
    var priceSuffix: String = ""
    let bullets: [String]
    let isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(price)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    if !priceSuffix.isEmpty {
                        Text(priceSuffix)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }

            ForEach(bullets, id: \.self) { bullet in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.emerald)
                    Text(bullet)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .fill(isHighlighted ? Theme.Colors.slate900 : Theme.Colors.slate800)
                .overlay {
                    if isHighlighted {
                        RoundedRectangle(cornerRadius: Theme.Radius.large)
                            .stroke(Theme.Colors.emerald.opacity(0.4), lineWidth: 1)
                    }
                }
        }
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .fill(Theme.Colors.emerald)
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(Theme.Colors.emerald)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(Theme.Colors.emerald, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview {
    PricingView()
        .environmentObject(ConvexAuth.shared)
}

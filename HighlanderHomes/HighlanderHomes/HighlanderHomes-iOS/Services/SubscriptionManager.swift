import Foundation
import StoreKit
import UIKit
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var product: Product?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasActiveSubscription = false

    private let productId = "highlanderhomes_monthly_999"

    private init() {}

    func loadProduct() async {
        isLoading = true
        errorMessage = nil
        do {
            let products = try await Product.products(for: [productId])
            product = products.first
        } catch {
            errorMessage = "Unable to load subscription details."
        }
        isLoading = false
    }

    func refreshEntitlements() async {
        var isActive = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == productId else { continue }
            if transaction.revocationDate == nil {
                if let expiration = transaction.expirationDate {
                    if expiration > Date() { isActive = true }
                } else {
                    isActive = true
                }
            }
        }
        hasActiveSubscription = isActive
    }

    func purchase() async throws {
        guard let product else {
            throw SubscriptionError.productUnavailable
        }
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled:
            throw SubscriptionError.cancelled
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    func openManageSubscriptions() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        Task {
            try? await AppStore.showManageSubscriptions(in: scene)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.unverified
        case .verified(let safe):
            return safe
        }
    }
}

enum SubscriptionError: LocalizedError {
    case productUnavailable
    case cancelled
    case pending
    case unverified
    case unknown

    var errorDescription: String? {
        switch self {
        case .productUnavailable: return "Subscription product is unavailable."
        case .cancelled: return "Purchase cancelled."
        case .pending: return "Purchase is pending approval."
        case .unverified: return "Purchase could not be verified."
        case .unknown: return "Something went wrong with the purchase."
        }
    }
}

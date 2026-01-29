import Foundation
import SwiftData

@Model
final class RentPayment {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var paymentDate: Date
    var dueDate: Date
    var paymentMethod: PaymentMethod
    var status: PaymentStatus
    var transactionId: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    var property: Property?
    var tenant: Tenant?

    var isLate: Bool {
        paymentDate > dueDate
    }

    var daysLate: Int? {
        guard isLate else { return nil }
        return Calendar.current.dateComponents([.day], from: dueDate, to: paymentDate).day
    }

    enum PaymentMethod: String, Codable, CaseIterable {
        case cash = "Cash"
        case check = "Check"
        case bankTransfer = "Bank Transfer"
        case creditCard = "Credit Card"
        case venmo = "Venmo"
        case zelle = "Zelle"
        case paypal = "PayPal"
        case other = "Other"

        var icon: String {
            switch self {
            case .cash: return "banknote.fill"
            case .check: return "doc.text.fill"
            case .bankTransfer: return "building.columns.fill"
            case .creditCard: return "creditcard.fill"
            case .venmo: return "v.circle.fill"
            case .zelle: return "z.circle.fill"
            case .paypal: return "p.circle.fill"
            case .other: return "dollarsign.circle.fill"
            }
        }
    }

    enum PaymentStatus: String, Codable, CaseIterable {
        case pending
        case processing
        case completed
        case failed
        case refunded

        var label: String {
            rawValue.capitalized
        }

        var color: String {
            switch self {
            case .pending: return "amber"
            case .processing: return "blue"
            case .completed: return "emerald"
            case .failed: return "red"
            case .refunded: return "purple"
            }
        }

        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .processing: return "arrow.2.circlepath"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            case .refunded: return "arrow.uturn.backward.circle.fill"
            }
        }
    }

    init(
        id: UUID = UUID(),
        amount: Double,
        paymentDate: Date = Date(),
        dueDate: Date,
        paymentMethod: PaymentMethod = .bankTransfer,
        status: PaymentStatus = .pending,
        transactionId: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.paymentDate = paymentDate
        self.dueDate = dueDate
        self.paymentMethod = paymentMethod
        self.status = status
        self.transactionId = transactionId
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

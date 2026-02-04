import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var title: String
    var descriptionText: String?
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var isRecurring: Bool
    var recurringFrequency: RecurringFrequency?
    var receiptURL: String?
    var vendor: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    var property: Property?

    enum ExpenseCategory: String, Codable, CaseIterable {
        case maintenance = "Maintenance"
        case utilities = "Utilities"
        case insurance = "Insurance"
        case taxes = "Taxes"
        case mortgage = "Mortgage"
        case management = "Management"
        case marketing = "Marketing"
        case legal = "Legal"
        case supplies = "Supplies"
        case other = "Other"

        var icon: String {
            switch self {
            case .maintenance: return "wrench.fill"
            case .utilities: return "bolt.fill"
            case .insurance: return "shield.fill"
            case .taxes: return "building.columns.fill"
            case .mortgage: return "house.fill"
            case .management: return "person.2.fill"
            case .marketing: return "megaphone.fill"
            case .legal: return "scale.3d"
            case .supplies: return "shippingbox.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .maintenance: return "orange"
            case .utilities: return "yellow"
            case .insurance: return "blue"
            case .taxes: return "red"
            case .mortgage: return "purple"
            case .management: return "cyan"
            case .marketing: return "pink"
            case .legal: return "indigo"
            case .supplies: return "teal"
            case .other: return "gray"
            }
        }
    }

    enum RecurringFrequency: String, Codable, CaseIterable {
        case weekly
        case biweekly
        case monthly
        case quarterly
        case annually

        var label: String {
            rawValue.capitalized
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String? = nil,
        amount: Double,
        category: ExpenseCategory = .other,
        date: Date = Date(),
        isRecurring: Bool = false,
        recurringFrequency: RecurringFrequency? = nil,
        receiptURL: String? = nil,
        vendor: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.amount = amount
        self.category = category
        self.date = date
        self.isRecurring = isRecurring
        self.recurringFrequency = recurringFrequency
        self.receiptURL = receiptURL
        self.vendor = vendor
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

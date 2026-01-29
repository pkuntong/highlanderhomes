import Foundation
import SwiftData

@Model
final class Property {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var propertyType: PropertyType
    var units: Int
    var monthlyRent: Double
    var purchasePrice: Double?
    var currentValue: Double?
    var imageURL: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Tenant.property)
    var tenants: [Tenant]? = []

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceRequest.property)
    var maintenanceRequests: [MaintenanceRequest]? = []

    @Relationship(deleteRule: .cascade, inverse: \Expense.property)
    var expenses: [Expense]? = []

    @Relationship(deleteRule: .cascade, inverse: \RentPayment.property)
    var rentPayments: [RentPayment]? = []

    var healthScore: Int {
        // Calculate property health (0-100)
        var score = 100

        // Deduct for pending maintenance
        let pendingMaintenance = maintenanceRequests?.filter { $0.status != .completed }.count ?? 0
        score -= pendingMaintenance * 10

        // Deduct for vacant units
        let occupiedUnits = tenants?.filter { $0.isActive }.count ?? 0
        let vacancyRate = units > 0 ? Double(units - occupiedUnits) / Double(units) : 0
        score -= Int(vacancyRate * 30)

        return max(0, min(100, score))
    }

    var healthStatus: HealthStatus {
        switch healthScore {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .attention
        default: return .critical
        }
    }

    enum HealthStatus: String, Codable {
        case excellent
        case good
        case attention
        case critical

        var color: String {
            switch self {
            case .excellent: return "emerald"
            case .good: return "blue"
            case .attention: return "amber"
            case .critical: return "red"
            }
        }

        var icon: String {
            switch self {
            case .excellent: return "checkmark.circle.fill"
            case .good: return "hand.thumbsup.fill"
            case .attention: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.octagon.fill"
            }
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        city: String,
        state: String,
        zipCode: String,
        propertyType: PropertyType = .singleFamily,
        units: Int = 1,
        monthlyRent: Double,
        purchasePrice: Double? = nil,
        currentValue: Double? = nil,
        imageURL: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.propertyType = propertyType
        self.units = units
        self.monthlyRent = monthlyRent
        self.purchasePrice = purchasePrice
        self.currentValue = currentValue
        self.imageURL = imageURL
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Property Type
enum PropertyType: String, Codable, CaseIterable {
    case singleFamily = "Single Family"
    case multiFamily = "Multi-Family"
    case apartment = "Apartment"
    case condo = "Condo"
    case townhouse = "Townhouse"
    case commercial = "Commercial"

    var icon: String {
        switch self {
        case .singleFamily: return "house.fill"
        case .multiFamily: return "building.2.fill"
        case .apartment: return "building.fill"
        case .condo: return "building.columns.fill"
        case .townhouse: return "house.and.flag.fill"
        case .commercial: return "storefront.fill"
        }
    }
}

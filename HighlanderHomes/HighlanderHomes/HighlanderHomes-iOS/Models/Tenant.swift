import Foundation
import SwiftData

@Model
final class Tenant {
    @Attribute(.unique) var id: UUID
    var convexId: String? // For syncing with Convex backend
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var unit: String?
    var leaseStart: Date?
    var leaseEnd: Date?
    var leaseStartDate: Date
    var leaseEndDate: Date
    var rentAmount: Double
    var monthlyRent: Double
    var securityDeposit: Double
    var isActive: Bool
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    var notes: String?
    var avatarURL: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    var property: Property?

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceRequest.tenant)
    var maintenanceRequests: [MaintenanceRequest]? = []

    @Relationship(deleteRule: .cascade, inverse: \RentPayment.tenant)
    var rentPayments: [RentPayment]? = []

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }

    var leaseStatus: LeaseStatus {
        let now = Date()
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: now, to: leaseEndDate).day ?? 0

        if !isActive {
            return .inactive
        } else if daysUntilExpiry < 0 {
            return .expired
        } else if daysUntilExpiry <= 30 {
            return .expiringSoon
        } else {
            return .active
        }
    }

    var paymentStatus: PaymentStatus {
        guard let payments = rentPayments else { return .unknown }
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())

        let hasCurrentMonthPayment = payments.contains { payment in
            let paymentMonth = Calendar.current.component(.month, from: payment.paymentDate)
            let paymentYear = Calendar.current.component(.year, from: payment.paymentDate)
            return paymentMonth == currentMonth && paymentYear == currentYear && payment.status == .completed
        }

        if hasCurrentMonthPayment {
            return .current
        } else {
            let dayOfMonth = Calendar.current.component(.day, from: Date())
            return dayOfMonth > 5 ? .late : .pending
        }
    }

    enum LeaseStatus: String, Codable {
        case active
        case expiringSoon
        case expired
        case inactive

        var color: String {
            switch self {
            case .active: return "emerald"
            case .expiringSoon: return "amber"
            case .expired: return "red"
            case .inactive: return "gray"
            }
        }

        var label: String {
            switch self {
            case .active: return "Active"
            case .expiringSoon: return "Expiring Soon"
            case .expired: return "Expired"
            case .inactive: return "Inactive"
            }
        }
    }

    enum PaymentStatus: String, Codable {
        case current
        case pending
        case late
        case unknown

        var color: String {
            switch self {
            case .current: return "emerald"
            case .pending: return "amber"
            case .late: return "red"
            case .unknown: return "gray"
            }
        }

        var icon: String {
            switch self {
            case .current: return "checkmark.circle.fill"
            case .pending: return "clock.fill"
            case .late: return "exclamationmark.circle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }

    init(
        id: UUID = UUID(),
        convexId: String? = nil,
        firstName: String,
        lastName: String,
        email: String,
        phone: String,
        unit: String? = nil,
        leaseStartDate: Date = Date(),
        leaseEndDate: Date = Date().addingTimeInterval(365 * 24 * 60 * 60),
        monthlyRent: Double = 0,
        securityDeposit: Double = 0,
        isActive: Bool = true,
        emergencyContactName: String? = nil,
        emergencyContactPhone: String? = nil,
        notes: String? = nil,
        avatarURL: String? = nil
    ) {
        self.id = id
        self.convexId = convexId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.unit = unit
        self.leaseStart = leaseStartDate
        self.leaseEnd = leaseEndDate
        self.leaseStartDate = leaseStartDate
        self.leaseEndDate = leaseEndDate
        self.rentAmount = monthlyRent
        self.monthlyRent = monthlyRent
        self.securityDeposit = securityDeposit
        self.isActive = isActive
        self.emergencyContactName = emergencyContactName
        self.emergencyContactPhone = emergencyContactPhone
        self.notes = notes
        self.avatarURL = avatarURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Convenience initializer for Convex data (single name field)
    convenience init(
        name: String,
        email: String,
        phone: String,
        convexId: String? = nil
    ) {
        let parts = name.split(separator: " ")
        let firstName = String(parts.first ?? "")
        let lastName = parts.count > 1 ? String(parts.dropFirst().joined(separator: " ")) : ""

        self.init(
            convexId: convexId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone
        )
    }
}

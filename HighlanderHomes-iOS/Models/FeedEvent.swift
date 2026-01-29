import Foundation
import SwiftData

/// Represents an event in the TikTok-style activity feed
@Model
final class FeedEvent {
    @Attribute(.unique) var id: UUID
    var eventType: EventType
    var title: String
    var subtitle: String
    var detail: String?
    var timestamp: Date
    var isRead: Bool
    var isActionRequired: Bool
    var actionLabel: String?
    var priority: Priority

    // Reference IDs for navigation
    var propertyId: UUID?
    var tenantId: UUID?
    var maintenanceRequestId: UUID?
    var contractorId: UUID?
    var rentPaymentId: UUID?

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    enum EventType: String, Codable, CaseIterable {
        case maintenanceNew
        case maintenanceUpdate
        case maintenanceCompleted
        case contractorAssigned
        case contractorOnSite
        case contractorScheduled
        case rentReceived
        case rentLate
        case rentDue
        case leaseExpiring
        case leaseRenewed
        case tenantMessage
        case propertyInspection
        case documentUploaded
        case systemAlert

        var icon: String {
            switch self {
            case .maintenanceNew: return "exclamationmark.bubble.fill"
            case .maintenanceUpdate: return "wrench.and.screwdriver.fill"
            case .maintenanceCompleted: return "checkmark.seal.fill"
            case .contractorAssigned: return "person.badge.plus"
            case .contractorOnSite: return "location.fill"
            case .contractorScheduled: return "calendar.badge.clock"
            case .rentReceived: return "dollarsign.circle.fill"
            case .rentLate: return "exclamationmark.circle.fill"
            case .rentDue: return "calendar.badge.exclamationmark"
            case .leaseExpiring: return "clock.badge.exclamationmark.fill"
            case .leaseRenewed: return "signature"
            case .tenantMessage: return "bubble.left.fill"
            case .propertyInspection: return "magnifyingglass"
            case .documentUploaded: return "doc.badge.plus"
            case .systemAlert: return "bell.badge.fill"
            }
        }

        var category: EventCategory {
            switch self {
            case .maintenanceNew, .maintenanceUpdate, .maintenanceCompleted:
                return .maintenance
            case .contractorAssigned, .contractorOnSite, .contractorScheduled:
                return .contractor
            case .rentReceived, .rentLate, .rentDue:
                return .financial
            case .leaseExpiring, .leaseRenewed, .tenantMessage:
                return .tenant
            case .propertyInspection, .documentUploaded, .systemAlert:
                return .general
            }
        }
    }

    enum EventCategory: String, Codable {
        case maintenance
        case contractor
        case financial
        case tenant
        case general

        var color: String {
            switch self {
            case .maintenance: return "red"
            case .contractor: return "blue"
            case .financial: return "gold"
            case .tenant: return "purple"
            case .general: return "gray"
            }
        }
    }

    enum Priority: Int, Codable, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case urgent = 3

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        eventType: EventType,
        title: String,
        subtitle: String,
        detail: String? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false,
        isActionRequired: Bool = false,
        actionLabel: String? = nil,
        priority: Priority = .normal,
        propertyId: UUID? = nil,
        tenantId: UUID? = nil,
        maintenanceRequestId: UUID? = nil,
        contractorId: UUID? = nil,
        rentPaymentId: UUID? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.timestamp = timestamp
        self.isRead = isRead
        self.isActionRequired = isActionRequired
        self.actionLabel = actionLabel
        self.priority = priority
        self.propertyId = propertyId
        self.tenantId = tenantId
        self.maintenanceRequestId = maintenanceRequestId
        self.contractorId = contractorId
        self.rentPaymentId = rentPaymentId
    }
}

// MARK: - Sample Events Factory
extension FeedEvent {
    static func sampleEvents() -> [FeedEvent] {
        [
            FeedEvent(
                eventType: .maintenanceNew,
                title: "Leak Reported",
                subtitle: "Unit 2B - Kitchen sink leaking",
                detail: "Tenant reports water pooling under the sink. Requesting urgent repair.",
                isActionRequired: true,
                actionLabel: "Assign Contractor",
                priority: .urgent
            ),
            FeedEvent(
                eventType: .contractorOnSite,
                title: "Contractor On-Site",
                subtitle: "Mike's Plumbing at 123 Oak St",
                detail: "Arrived 10 minutes ago. Estimated completion: 2 hours.",
                timestamp: Date().addingTimeInterval(-600),
                priority: .high
            ),
            FeedEvent(
                eventType: .rentReceived,
                title: "Rent Received",
                subtitle: "$2,400 from Sarah Johnson",
                detail: "Unit 1A - March 2024 rent paid on time",
                timestamp: Date().addingTimeInterval(-3600),
                isRead: true,
                priority: .normal
            ),
            FeedEvent(
                eventType: .rentLate,
                title: "Rent Overdue",
                subtitle: "$1,800 from James Wilson",
                detail: "Unit 3C - 5 days late. Grace period ended.",
                isActionRequired: true,
                actionLabel: "Send Reminder",
                priority: .high
            ),
            FeedEvent(
                eventType: .maintenanceCompleted,
                title: "Repair Completed",
                subtitle: "HVAC repair at Maple Complex",
                detail: "AC unit replaced. Total cost: $450",
                timestamp: Date().addingTimeInterval(-7200),
                isRead: true,
                priority: .normal
            ),
            FeedEvent(
                eventType: .leaseExpiring,
                title: "Lease Expiring Soon",
                subtitle: "Emily Chen - Unit 4D",
                detail: "Lease expires in 30 days. Begin renewal conversation.",
                isActionRequired: true,
                actionLabel: "Contact Tenant",
                priority: .normal
            )
        ]
    }
}

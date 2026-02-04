import Foundation
import SwiftData

@Model
final class MaintenanceRequest {
    @Attribute(.unique) var id: UUID
    var title: String
    var descriptionText: String
    var category: MaintenanceCategory
    var priority: Priority
    var status: Status
    var photoURLsCSV: String?
    var scheduledDate: Date?
    var completedDate: Date?
    var estimatedCost: Double?
    var actualCost: Double?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    var property: Property?
    var tenant: Tenant?
    var contractor: Contractor?

    // Computed Properties
    var isUrgent: Bool {
        priority == .urgent || priority == .emergency
    }

    var photoURLs: [String]? {
        get {
            guard let csv = photoURLsCSV, !csv.isEmpty else { return nil }
            let urls = csv.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            return urls.isEmpty ? nil : urls
        }
        set {
            photoURLsCSV = newValue?.joined(separator: ", ")
        }
    }

    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }

    var statusColor: String {
        status.color
    }

    enum MaintenanceCategory: String, Codable, CaseIterable {
        case plumbing = "Plumbing"
        case electrical = "Electrical"
        case hvac = "HVAC"
        case appliance = "Appliance"
        case structural = "Structural"
        case pest = "Pest Control"
        case landscaping = "Landscaping"
        case cleaning = "Cleaning"
        case other = "Other"

        var icon: String {
            switch self {
            case .plumbing: return "drop.fill"
            case .electrical: return "bolt.fill"
            case .hvac: return "thermometer.medium"
            case .appliance: return "washer.fill"
            case .structural: return "hammer.fill"
            case .pest: return "ant.fill"
            case .landscaping: return "leaf.fill"
            case .cleaning: return "sparkles"
            case .other: return "wrench.fill"
            }
        }
    }

    enum Priority: String, Codable, CaseIterable, Comparable {
        case low
        case normal
        case high
        case urgent
        case emergency

        var sortOrder: Int {
            switch self {
            case .low: return 0
            case .normal: return 1
            case .high: return 2
            case .urgent: return 3
            case .emergency: return 4
            }
        }

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.sortOrder < rhs.sortOrder
        }

        var label: String {
            rawValue.capitalized
        }

        var color: String {
            switch self {
            case .low: return "gray"
            case .normal: return "blue"
            case .high: return "amber"
            case .urgent: return "orange"
            case .emergency: return "red"
            }
        }

        var icon: String {
            switch self {
            case .low: return "arrow.down.circle.fill"
            case .normal: return "minus.circle.fill"
            case .high: return "arrow.up.circle.fill"
            case .urgent: return "exclamationmark.circle.fill"
            case .emergency: return "exclamationmark.triangle.fill"
            }
        }
    }

    enum Status: String, Codable, CaseIterable {
        case new
        case acknowledged
        case scheduled
        case inProgress
        case awaitingParts
        case completed
        case cancelled

        var label: String {
            switch self {
            case .new: return "New"
            case .acknowledged: return "Acknowledged"
            case .scheduled: return "Scheduled"
            case .inProgress: return "In Progress"
            case .awaitingParts: return "Awaiting Parts"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            }
        }

        var color: String {
            switch self {
            case .new: return "red"
            case .acknowledged: return "amber"
            case .scheduled: return "blue"
            case .inProgress: return "cyan"
            case .awaitingParts: return "purple"
            case .completed: return "emerald"
            case .cancelled: return "gray"
            }
        }

        var icon: String {
            switch self {
            case .new: return "bell.badge.fill"
            case .acknowledged: return "eye.fill"
            case .scheduled: return "calendar.badge.clock"
            case .inProgress: return "wrench.and.screwdriver.fill"
            case .awaitingParts: return "shippingbox.fill"
            case .completed: return "checkmark.circle.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String,
        category: MaintenanceCategory = .other,
        priority: Priority = .normal,
        status: Status = .new,
        photoURLs: [String]? = nil,
        scheduledDate: Date? = nil,
        estimatedCost: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.category = category
        self.priority = priority
        self.status = status
        self.photoURLsCSV = photoURLs?.joined(separator: ", ")
        self.scheduledDate = scheduledDate
        self.estimatedCost = estimatedCost
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String,
        category: MaintenanceCategory,
        priority: Priority,
        status: Status = .new,
        photoURLsCSV: String? = nil,
        scheduledDate: Date? = nil,
        completedDate: Date? = nil,
        estimatedCost: Double? = nil,
        actualCost: Double? = nil,
        notes: String? = nil,
        property: Property? = nil,
        tenant: Tenant? = nil,
        contractor: Contractor? = nil
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.category = category
        self.priority = priority
        self.status = status
        self.photoURLsCSV = photoURLsCSV
        self.scheduledDate = scheduledDate
        self.completedDate = completedDate
        self.estimatedCost = estimatedCost
        self.actualCost = actualCost
        self.notes = notes
        self.property = property
        self.tenant = tenant
        self.contractor = contractor
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

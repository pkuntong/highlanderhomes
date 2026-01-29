import Foundation
import SwiftData

@Model
final class Contractor {
    @Attribute(.unique) var id: UUID
    var companyName: String
    var contactName: String
    var email: String
    var phone: String
    var specialty: [String]
    var hourlyRate: Double?
    var rating: Double?
    var isPreferred: Bool
    var notes: String?
    var avatarURL: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \MaintenanceRequest.contractor)
    var maintenanceRequests: [MaintenanceRequest]? = []

    var displayName: String {
        companyName.isEmpty ? contactName : companyName
    }

    var initials: String {
        if !companyName.isEmpty {
            let words = companyName.split(separator: " ")
            if words.count >= 2 {
                return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
            }
            return String(companyName.prefix(2)).uppercased()
        }
        let names = contactName.split(separator: " ")
        if names.count >= 2 {
            return "\(names[0].prefix(1))\(names[1].prefix(1))".uppercased()
        }
        return String(contactName.prefix(2)).uppercased()
    }

    var completedJobsCount: Int {
        maintenanceRequests?.filter { $0.status == .completed }.count ?? 0
    }

    var averageJobCost: Double? {
        guard let requests = maintenanceRequests else { return nil }
        let completedWithCost = requests.filter { $0.status == .completed && $0.actualCost != nil }
        guard !completedWithCost.isEmpty else { return nil }
        let total = completedWithCost.compactMap { $0.actualCost }.reduce(0, +)
        return total / Double(completedWithCost.count)
    }

    init(
        id: UUID = UUID(),
        companyName: String = "",
        contactName: String,
        email: String,
        phone: String,
        specialty: [String] = [],
        hourlyRate: Double? = nil,
        rating: Double? = nil,
        isPreferred: Bool = false,
        notes: String? = nil,
        avatarURL: String? = nil
    ) {
        self.id = id
        self.companyName = companyName
        self.contactName = contactName
        self.email = email
        self.phone = phone
        self.specialty = specialty
        self.hourlyRate = hourlyRate
        self.rating = rating
        self.isPreferred = isPreferred
        self.notes = notes
        self.avatarURL = avatarURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

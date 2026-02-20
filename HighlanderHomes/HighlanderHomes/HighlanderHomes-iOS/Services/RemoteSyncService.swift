import Foundation

/// Lightweight stub to satisfy legacy remote sync references.
/// The iOS build currently uses Convex for data, so these
/// implementations are no-ops that return empty data sets.
actor RemoteSyncService {
    static let shared = RemoteSyncService()

    private init() {}

    // MARK: - Fetch
    func fetchProperties() async throws -> [RemotePropertyRecord] { [] }
    func fetchTenants() async throws -> [RemoteTenantRecord] { [] }
    func fetchMaintenanceRequests() async throws -> [RemoteMaintenanceRequestRecord] { [] }
    func fetchContractors() async throws -> [RemoteContractorRecord] { [] }

    // MARK: - Mutations
    func saveProperty(_ property: RemotePropertyRecord) async throws {}
    func updateMaintenanceStatus(id: String, status: String) async throws {}
}

// MARK: - Minimal remote DTOs used by the legacy DataManager
struct RemotePropertyRecord: Codable {
    var id: String?
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var monthlyRent: Double?
    var bedrooms: Int?
    var status: String?
}

struct RemoteTenantRecord: Codable {
    var id: String?
    var name: String
    var email: String
    var phone: String
    var leaseStartDate: String?
    var leaseEndDate: String?
    var monthlyRent: Double?
    var propertyId: String?
}

struct RemoteMaintenanceRequestRecord: Codable {
    var id: String?
    var title: String
    var description: String?
    var status: String
    var priority: String
    var category: String
    var propertyId: String?
}

struct RemoteContractorRecord: Codable {
    var id: String?
    var company: String?
    var name: String
    var email: String?
    var phone: String
    var specialty: String
    var hourlyRate: Double?
}

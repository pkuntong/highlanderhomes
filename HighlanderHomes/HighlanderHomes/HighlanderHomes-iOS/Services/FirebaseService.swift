import Foundation

/// Lightweight stub to satisfy legacy Firebase references.
/// The iOS build currently uses Convex for data, so these
/// implementations are no-ops that return empty data sets.
actor FirebaseService {
    static let shared = FirebaseService()

    private init() {}

    // MARK: - Fetch
    func fetchProperties() async throws -> [PropertyFirestore] { [] }
    func fetchTenants() async throws -> [TenantFirestore] { [] }
    func fetchMaintenanceRequests() async throws -> [MaintenanceRequestFirestore] { [] }
    func fetchContractors() async throws -> [ContractorFirestore] { [] }

    // MARK: - Mutations
    func saveProperty(_ property: PropertyFirestore) async throws {}
    func updateMaintenanceStatus(id: String, status: String) async throws {}
}

// MARK: - Minimal Firestore DTOs used by the legacy DataManager
struct PropertyFirestore: Codable {
    var id: String?
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var monthlyRent: Double?
    var bedrooms: Int?
    var status: String?
}

struct TenantFirestore: Codable {
    var id: String?
    var name: String
    var email: String
    var phone: String
    var leaseStartDate: String?
    var leaseEndDate: String?
    var monthlyRent: Double?
    var propertyId: String?
}

struct MaintenanceRequestFirestore: Codable {
    var id: String?
    var title: String
    var description: String?
    var status: String
    var priority: String
    var category: String
    var propertyId: String?
}

struct ContractorFirestore: Codable {
    var id: String?
    var company: String?
    var name: String
    var email: String?
    var phone: String
    var specialty: String
    var hourlyRate: Double?
}

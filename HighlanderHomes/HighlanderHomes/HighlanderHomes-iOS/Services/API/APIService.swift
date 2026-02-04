import Foundation
import Combine

/// API Service layer prepared for backend integration
/// Currently uses placeholders - ready to connect to your web-based API
actor APIService {
    static let shared = APIService()

    private let baseURL: URL
    private let session: URLSession

    private init() {
        // TODO: Replace with your actual API base URL
        self.baseURL = URL(string: "https://api.highlanderhomes.com/v1")!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        self.session = URLSession(configuration: config)
    }

    // MARK: - Authentication
    private var authToken: String?

    func setAuthToken(_ token: String) {
        self.authToken = token
    }

    func clearAuthToken() {
        self.authToken = nil
    }

    // MARK: - Generic Request Handler
    private func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws -> T {
        var url = baseURL.appendingPathComponent(endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Properties API
    func fetchProperties() async throws -> [PropertyDTO] {
        try await request(endpoint: "properties")
    }

    func createProperty(_ property: PropertyDTO) async throws -> PropertyDTO {
        try await request(endpoint: "properties", method: .post, body: property)
    }

    func updateProperty(_ property: PropertyDTO) async throws -> PropertyDTO {
        try await request(endpoint: "properties/\(property.id)", method: .put, body: property)
    }

    func deleteProperty(id: String) async throws {
        let _: EmptyResponse = try await request(endpoint: "properties/\(id)", method: .delete)
    }

    // MARK: - Tenants API
    func fetchTenants(propertyId: String? = nil) async throws -> [TenantDTO] {
        var endpoint = "tenants"
        if let propertyId = propertyId {
            endpoint += "?propertyId=\(propertyId)"
        }
        return try await request(endpoint: endpoint)
    }

    func createTenant(_ tenant: TenantDTO) async throws -> TenantDTO {
        try await request(endpoint: "tenants", method: .post, body: tenant)
    }

    // MARK: - Maintenance Requests API
    func fetchMaintenanceRequests(status: String? = nil) async throws -> [MaintenanceRequestDTO] {
        var endpoint = "maintenance"
        if let status = status {
            endpoint += "?status=\(status)"
        }
        return try await request(endpoint: endpoint)
    }

    func createMaintenanceRequest(_ request: MaintenanceRequestDTO) async throws -> MaintenanceRequestDTO {
        try await self.request(endpoint: "maintenance", method: .post, body: request)
    }

    func updateMaintenanceStatus(id: String, status: String) async throws -> MaintenanceRequestDTO {
        let body = ["status": status]
        return try await request(endpoint: "maintenance/\(id)/status", method: .patch, body: body)
    }

    func assignContractor(maintenanceId: String, contractorId: String) async throws -> MaintenanceRequestDTO {
        let body = ["contractorId": contractorId]
        return try await request(endpoint: "maintenance/\(maintenanceId)/assign", method: .post, body: body)
    }

    // MARK: - Contractors API
    func fetchContractors(specialty: String? = nil) async throws -> [ContractorDTO] {
        var endpoint = "contractors"
        if let specialty = specialty {
            endpoint += "?specialty=\(specialty)"
        }
        return try await request(endpoint: endpoint)
    }

    // MARK: - Rent Payments API
    func fetchRentPayments(month: Int? = nil, year: Int? = nil) async throws -> [RentPaymentDTO] {
        var endpoint = "payments"
        var queryItems: [String] = []
        if let month = month { queryItems.append("month=\(month)") }
        if let year = year { queryItems.append("year=\(year)") }
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        return try await request(endpoint: endpoint)
    }

    func recordPayment(_ payment: RentPaymentDTO) async throws -> RentPaymentDTO {
        try await request(endpoint: "payments", method: .post, body: payment)
    }

    // MARK: - Activity Feed API
    func fetchFeedEvents(since: Date? = nil, limit: Int = 50) async throws -> [FeedEventDTO] {
        var endpoint = "feed?limit=\(limit)"
        if let since = since {
            let formatter = ISO8601DateFormatter()
            endpoint += "&since=\(formatter.string(from: since))"
        }
        return try await request(endpoint: endpoint)
    }

    // MARK: - Sync
    func syncLocalChanges(_ changes: SyncPayload) async throws -> SyncResponse {
        try await request(endpoint: "sync", method: .post, body: changes)
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case notFound
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error"
        }
    }
}

// MARK: - DTO Models (Data Transfer Objects)
struct PropertyDTO: Codable, Identifiable {
    let id: String
    var name: String
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var propertyType: String
    var units: Int
    var monthlyRent: Double
    var purchasePrice: Double?
    var currentValue: Double?
    var imageURL: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
}

struct TenantDTO: Codable, Identifiable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var unit: String?
    var propertyId: String
    var leaseStartDate: Date
    var leaseEndDate: Date
    var monthlyRent: Double
    var securityDeposit: Double
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
}

struct MaintenanceRequestDTO: Codable, Identifiable {
    let id: String
    var propertyId: String
    var tenantId: String?
    var contractorId: String?
    var title: String
    var description: String
    var category: String
    var priority: String
    var status: String
    var photoURLs: [String]?
    var scheduledDate: Date?
    var completedDate: Date?
    var estimatedCost: Double?
    var actualCost: Double?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
}

struct ContractorDTO: Codable, Identifiable {
    let id: String
    var companyName: String
    var contactName: String
    var email: String
    var phone: String
    var specialty: [String]
    var hourlyRate: Double?
    var rating: Double?
    var isPreferred: Bool
    var createdAt: Date
    var updatedAt: Date
}

struct RentPaymentDTO: Codable, Identifiable {
    let id: String
    var propertyId: String
    var tenantId: String
    var amount: Double
    var paymentDate: Date
    var dueDate: Date
    var paymentMethod: String
    var status: String
    var transactionId: String?
    var notes: String?
    var createdAt: Date
}

struct FeedEventDTO: Codable, Identifiable {
    let id: String
    var eventType: String
    var title: String
    var subtitle: String
    var detail: String?
    var timestamp: Date
    var isRead: Bool
    var isActionRequired: Bool
    var actionLabel: String?
    var priority: Int
    var propertyId: String?
    var tenantId: String?
    var maintenanceRequestId: String?
    var contractorId: String?
}

struct SyncPayload: Codable {
    var properties: [PropertyDTO]?
    var tenants: [TenantDTO]?
    var maintenanceRequests: [MaintenanceRequestDTO]?
    var expenses: [ExpenseDTO]?
    var rentPayments: [RentPaymentDTO]?
    var lastSyncTimestamp: Date
}

struct ExpenseDTO: Codable, Identifiable {
    let id: String
    var propertyId: String?
    var title: String
    var description: String?
    var amount: Double
    var category: String
    var date: Date
    var isRecurring: Bool
    var recurringFrequency: String?
    var receiptURL: String?
    var vendor: String?
    var notes: String?
    var createdAt: Date
}

struct SyncResponse: Codable {
    var success: Bool
    var syncedAt: Date
    var conflicts: [SyncConflict]?
}

struct SyncConflict: Codable {
    var entityType: String
    var entityId: String
    var conflictType: String
    var serverVersion: String
    var localVersion: String
}

struct EmptyResponse: Codable {}

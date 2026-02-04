import Foundation
import Combine
import SwiftData
import UIKit

/// Convex Data Service - handles all CRUD operations with real-time sync
@MainActor
class ConvexDataService: ObservableObject {
    static let shared = ConvexDataService()

    // MARK: - Published Data
    @Published var properties: [ConvexProperty] = []
    @Published var tenants: [ConvexTenant] = []
    @Published var maintenanceRequests: [ConvexMaintenanceRequest] = []
    @Published var contractors: [ConvexContractor] = []
    @Published var feedEvents: [ConvexFeedEvent] = []

    @Published var isLoading: Bool = false
    @Published var error: String?

    // MARK: - Local Cache
    private var modelContext: ModelContext?

    // MARK: - Computed Stats
    var totalMonthlyRevenue: Double {
        properties.reduce(0) { $0 + $1.monthlyRent }
    }

    var occupancyRate: Double {
        // Calculate based on tenants assigned to properties
        let propertiesWithTenants = Set(tenants.filter { $0.isActive }.map { $0.propertyId })
        guard !properties.isEmpty else { return 0 }
        return Double(propertiesWithTenants.count) / Double(properties.count)
    }

    var pendingMaintenanceCount: Int {
        maintenanceRequests.filter { $0.status != "completed" && $0.status != "cancelled" }.count
    }

    var urgentMaintenanceCount: Int {
        maintenanceRequests.filter { $0.priority == "high" && $0.status != "completed" }.count
    }

    var portfolioHealthScore: Int {
        var score = 100

        // Deduct for pending maintenance
        score -= pendingMaintenanceCount * 5

        // Deduct for vacancy
        let vacancyRate = 1 - occupancyRate
        score -= Int(vacancyRate * 30)

        // Deduct for urgent issues
        score -= urgentMaintenanceCount * 10

        return max(0, min(100, score))
    }

    private let client = ConvexClient.shared

    private init() {}

    // MARK: - Configuration
    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Sync All Data
    func syncAllData() async {
        await loadAllData()
        subscribeToUpdates()

        // Optionally cache to local SwiftData for offline support
        await cacheToLocal()
    }

    // MARK: - Cache to Local SwiftData
    private func cacheToLocal() async {
        guard let context = modelContext else { return }

        // Convert Convex models to local SwiftData models
        for convexProperty in properties {
            let property = Property(
                convexId: convexProperty.id,
                name: convexProperty.name,
                address: convexProperty.address,
                city: convexProperty.city,
                state: convexProperty.state,
                zipCode: convexProperty.zipCode,
                units: convexProperty.units,
                monthlyRent: convexProperty.monthlyRent,
                purchasePrice: convexProperty.purchasePrice,
                currentValue: convexProperty.currentValue,
                imageURL: convexProperty.imageURL
            )

            context.insert(property)
        }

        for convexTenant in tenants {
            let tenant = Tenant(
                convexId: convexTenant.id,
                firstName: convexTenant.firstName,
                lastName: convexTenant.lastName,
                email: convexTenant.email,
                phone: convexTenant.phone,
                leaseStartDate: convexTenant.leaseStartDateValue,
                leaseEndDate: convexTenant.leaseEndDateValue,
                monthlyRent: convexTenant.monthlyRent,
                securityDeposit: convexTenant.securityDeposit,
                isActive: convexTenant.isActive
            )

            context.insert(tenant)
        }

        try? context.save()
    }

    // MARK: - Initial Load
    func loadAllData() async {
        isLoading = true
        error = nil

        do {
            // Fetch all data in parallel
            async let props = fetchProperties()
            async let tens = fetchTenants()
            async let reqs = fetchMaintenanceRequests()
            async let cons = fetchContractors()

            properties = try await props
            tenants = try await tens
            maintenanceRequests = try await reqs
            contractors = try await cons

            // Generate feed events
            generateFeedEvents()

            HapticManager.shared.success()
        } catch {
            self.error = error.localizedDescription
            HapticManager.shared.error()
        }

        isLoading = false
    }

    // MARK: - Real-time Subscriptions
    func subscribeToUpdates() {
        guard let userId = effectiveUserId else { return }

        // Subscribe to properties
        client.subscribe(
            to: ConvexConfig.Functions.getProperties,
            args: ["userId": userId]
        ) { [weak self] (props: [ConvexProperty]) in
            self?.properties = props
        }

        // Subscribe to maintenance requests
        client.subscribe(
            to: ConvexConfig.Functions.getMaintenanceRequests,
            args: ["userId": userId]
        ) { [weak self] (reqs: [ConvexMaintenanceRequest]) in
            self?.maintenanceRequests = reqs
            self?.generateFeedEvents()
        }

        // Subscribe to tenants
        client.subscribe(
            to: ConvexConfig.Functions.getTenants,
            args: ["userId": userId]
        ) { [weak self] (tens: [ConvexTenant]) in
            self?.tenants = tens
        }
    }

    func unsubscribeFromUpdates() {
        client.unsubscribe(from: ConvexConfig.Functions.getProperties)
        client.unsubscribe(from: ConvexConfig.Functions.getMaintenanceRequests)
        client.unsubscribe(from: ConvexConfig.Functions.getTenants)
    }

    // MARK: - User ID Helper
    private var currentUserId: String? {
        ConvexAuth.shared.currentUser?.id
    }

    private var effectiveUserId: String? {
        ConvexConfig.dataOwnerUserId.isEmpty ? currentUserId : ConvexConfig.dataOwnerUserId
    }

    // MARK: - Properties
    func fetchProperties() async throws -> [ConvexProperty] {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        return try await client.query(
            ConvexConfig.Functions.getProperties,
            args: ["userId": userId]
        )
    }

    func createProperty(_ property: ConvexPropertyInput) async throws -> ConvexProperty {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        var args = property.toDictionary()
        args["userId"] = userId
        return try await client.mutation(ConvexConfig.Functions.createProperty, args: args)
    }

    func updateProperty(id: String, updates: [String: Any]) async throws -> ConvexProperty {
        var args = updates
        args["id"] = id
        return try await client.mutation(ConvexConfig.Functions.updateProperty, args: args)
    }

    func deleteProperty(id: String) async throws {
        try await client.mutation(ConvexConfig.Functions.deleteProperty, args: ["id": id])
    }

    // MARK: - Tenants
    func fetchTenants() async throws -> [ConvexTenant] {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        return try await client.query(
            ConvexConfig.Functions.getTenants,
            args: ["userId": userId]
        )
    }

    func createTenant(_ tenant: ConvexTenantInput) async throws -> ConvexTenant {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        var args = tenant.toDictionary()
        args["userId"] = userId
        return try await client.mutation(ConvexConfig.Functions.createTenant, args: args)
    }

    func updateTenant(id: String, updates: [String: Any]) async throws -> ConvexTenant {
        var args = updates
        args["id"] = id
        return try await client.mutation(ConvexConfig.Functions.updateTenant, args: args)
    }

    // MARK: - Maintenance Requests
    func fetchMaintenanceRequests() async throws -> [ConvexMaintenanceRequest] {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        return try await client.query(
            ConvexConfig.Functions.getMaintenanceRequests,
            args: ["userId": userId]
        )
    }

    func createMaintenanceRequest(_ request: ConvexMaintenanceRequestInput) async throws -> ConvexMaintenanceRequest {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        var args = request.toDictionary()
        args["userId"] = userId

        let result: ConvexMaintenanceRequest = try await client.mutation(
            ConvexConfig.Functions.createMaintenanceRequest,
            args: args
        )

        // Trigger notification haptic
        HapticManager.shared.notification(.warning)

        return result
    }

    func updateMaintenanceStatus(id: String, status: String) async throws {
        try await client.mutation(
            ConvexConfig.Functions.updateMaintenanceStatus,
            args: ["id": id, "status": status]
        )

        if status == "completed" {
            HapticManager.shared.reward()
            // Trigger celebration
            CelebrationManager.shared.maintenanceCompleted(title: "Issue resolved!")
        }
    }

    func assignContractor(requestId: String, contractorId: String) async throws {
        try await client.mutation(
            ConvexConfig.Functions.assignContractor,
            args: ["requestId": requestId, "contractorId": contractorId]
        )
        HapticManager.shared.success()
    }

    // MARK: - Contractors
    func fetchContractors() async throws -> [ConvexContractor] {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        return try await client.query(
            ConvexConfig.Functions.getContractors,
            args: ["userId": userId]
        )
    }

    func createContractor(_ contractor: ConvexContractorInput) async throws -> ConvexContractor {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        var args = contractor.toDictionary()
        args["userId"] = userId
        return try await client.mutation(ConvexConfig.Functions.createContractor, args: args)
    }

    // MARK: - Feed Events
    private func generateFeedEvents() {
        var events: [ConvexFeedEvent] = []

        // Create events from maintenance requests
        for request in maintenanceRequests where request.status != "completed" && request.status != "cancelled" {
            let needsAction = request.status == "new" && request.contractorId == nil
            let event = ConvexFeedEvent(
                id: request.id,
                type: request.isUrgent ? "maintenanceUrgent" : "maintenance",
                title: request.title,
                subtitle: "\(request.category) - \(request.priority.capitalized)",
                detail: request.description,
                timestamp: request.createdAtDate,
                isActionRequired: needsAction,
                actionLabel: needsAction ? "Assign Contractor" : nil,
                priority: request.isUrgent ? 3 : (request.priority == "high" ? 2 : 1),
                relatedId: request.id
            )
            events.append(event)
        }

        // Sort by priority and timestamp
        feedEvents = events.sorted { event1, event2 in
            if event1.priority != event2.priority {
                return event1.priority > event2.priority
            }
            return event1.timestamp > event2.timestamp
        }
    }
}

// MARK: - Convex Data Models (must match convex/schema.ts)

struct ConvexProperty: Codable, Identifiable {
    let id: String
    var name: String
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var propertyType: String // "Single Family", "Multi-Family", etc.
    var units: Int
    var monthlyRent: Double
    var purchasePrice: Double?
    var currentValue: Double?
    var imageURL: String?
    var notes: String?
    var createdAt: Double // Unix timestamp in ms
    var updatedAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, address, city, state, zipCode, propertyType, units
        case monthlyRent, purchasePrice, currentValue, imageURL, notes
        case createdAt, updatedAt
    }

    var displayAddress: String {
        "\(address), \(city), \(state)"
    }

    var createdAtDate: Date {
        Date(timeIntervalSince1970: createdAt / 1000)
    }

    var updatedAtDate: Date {
        Date(timeIntervalSince1970: updatedAt / 1000)
    }
}

struct ConvexPropertyInput {
    var name: String
    var address: String
    var city: String
    var state: String
    var zipCode: String
    var propertyType: String = "Single Family"
    var units: Int = 1
    var monthlyRent: Double
    var purchasePrice: Double?
    var currentValue: Double?
    var imageURL: String?
    var notes: String?

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "address": address,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "propertyType": propertyType,
            "units": units,
            "monthlyRent": monthlyRent
        ]
        if let price = purchasePrice { dict["purchasePrice"] = price }
        if let value = currentValue { dict["currentValue"] = value }
        if let url = imageURL { dict["imageURL"] = url }
        if let notes = notes { dict["notes"] = notes }
        return dict
    }
}

struct ConvexTenant: Codable, Identifiable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var unit: String?
    var propertyId: String
    var leaseStartDate: Double // Unix timestamp in ms
    var leaseEndDate: Double
    var monthlyRent: Double
    var securityDeposit: Double
    var isActive: Bool
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    var notes: String?
    var avatarURL: String?
    var createdAt: Double
    var updatedAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName, lastName, email, phone, unit, propertyId
        case leaseStartDate, leaseEndDate, monthlyRent, securityDeposit
        case isActive, emergencyContactName, emergencyContactPhone
        case notes, avatarURL, createdAt, updatedAt
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }

    var leaseStartDateValue: Date {
        Date(timeIntervalSince1970: leaseStartDate / 1000)
    }

    var leaseEndDateValue: Date {
        Date(timeIntervalSince1970: leaseEndDate / 1000)
    }

    var leaseStatus: String {
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: leaseEndDateValue).day ?? 0
        if daysUntilExpiry < 0 { return "expired" }
        if daysUntilExpiry <= 30 { return "expiringSoon" }
        return "active"
    }
}

struct ConvexTenantInput {
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
    var isActive: Bool = true
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    var notes: String?
    var avatarURL: String?

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phone": phone,
            "propertyId": propertyId,
            "leaseStartDate": leaseStartDate.timeIntervalSince1970 * 1000,
            "leaseEndDate": leaseEndDate.timeIntervalSince1970 * 1000,
            "monthlyRent": monthlyRent,
            "securityDeposit": securityDeposit,
            "isActive": isActive
        ]
        if let unit = unit { dict["unit"] = unit }
        if let name = emergencyContactName { dict["emergencyContactName"] = name }
        if let phone = emergencyContactPhone { dict["emergencyContactPhone"] = phone }
        if let notes = notes { dict["notes"] = notes }
        if let avatar = avatarURL { dict["avatarURL"] = avatar }
        return dict
    }
}

struct ConvexMaintenanceRequest: Codable, Identifiable {
    let id: String
    var propertyId: String
    var tenantId: String?
    var contractorId: String?
    var title: String
    var description: String? // maps from descriptionText
    var category: String // "Plumbing", "Electrical", "HVAC", etc.
    var priority: String // "low", "normal", "high", "urgent", "emergency"
    var status: String // "new", "acknowledged", "scheduled", "inProgress", "awaitingParts", "completed", "cancelled"
    var photoURLs: [String]?
    var scheduledDate: Double?
    var completedDate: Double?
    var estimatedCost: Double?
    var actualCost: Double?
    var notes: String?
    var createdAt: Double
    var updatedAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case propertyId, tenantId, contractorId, title, description
        case category, priority, status, photoURLs
        case scheduledDate, completedDate, estimatedCost, actualCost
        case notes, createdAt, updatedAt
    }

    var isUrgent: Bool {
        priority == "high" || priority == "urgent" || priority == "emergency"
    }

    var createdAtDate: Date {
        Date(timeIntervalSince1970: createdAt / 1000)
    }

    var scheduledDateValue: Date? {
        guard let ts = scheduledDate else { return nil }
        return Date(timeIntervalSince1970: ts / 1000)
    }
}

struct ConvexMaintenanceRequestInput {
    var propertyId: String
    var tenantId: String?
    var title: String
    var descriptionText: String
    var category: String = "Other"
    var priority: String = "normal"
    var photoURLs: [String]?

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "propertyId": propertyId,
            "title": title,
            "descriptionText": descriptionText,
            "category": category,
            "priority": priority
        ]
        if let tenId = tenantId { dict["tenantId"] = tenId }
        if let photos = photoURLs { dict["photoURLs"] = photos }
        return dict
    }
}

struct ConvexContractor: Codable, Identifiable {
    let id: String
    var companyName: String
    var contactName: String
    var email: String
    var phone: String
    var specialty: [String] // Array of specialties
    var hourlyRate: Double?
    var rating: Double?
    var isPreferred: Bool
    var createdAt: Double
    var updatedAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case companyName, contactName, email, phone
        case specialty, hourlyRate, rating, isPreferred
        case createdAt, updatedAt
    }

    var displayName: String {
        companyName.isEmpty ? contactName : companyName
    }

    var specialtyDisplay: String {
        specialty.joined(separator: ", ")
    }
}

struct ConvexContractorInput {
    var companyName: String
    var contactName: String
    var email: String
    var phone: String
    var specialty: [String]
    var hourlyRate: Double?
    var rating: Double?
    var isPreferred: Bool

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "companyName": companyName,
            "contactName": contactName,
            "email": email,
            "phone": phone,
            "specialty": specialty,
            "isPreferred": isPreferred
        ]
        if let hourlyRate = hourlyRate { dict["hourlyRate"] = hourlyRate }
        if let rating = rating { dict["rating"] = rating }
        return dict
    }
}

struct ConvexFeedEvent: Identifiable {
    let id: String
    var type: String
    var title: String
    var subtitle: String
    var detail: String?
    var timestamp: Date
    var isActionRequired: Bool
    var actionLabel: String?
    var priority: Int
    var relatedId: String?

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

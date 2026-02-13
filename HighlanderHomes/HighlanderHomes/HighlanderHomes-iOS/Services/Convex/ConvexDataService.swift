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
    @Published var rentPayments: [ConvexRentPayment] = []
    @Published var expenses: [ConvexExpense] = []
    @Published var insurancePolicies: [ConvexInsurancePolicy] = []
    @Published var rentalLicenses: [ConvexRentalLicense] = []
    @Published var marketTrends: [ConvexMarketTrend] = []

    @Published var isLoading: Bool = false
    @Published var error: String?

    // MARK: - Local Cache
    private var modelContext: ModelContext?

    // MARK: - Computed Stats
    var totalMonthlyRevenue: Double {
        properties.reduce(0) { $0 + $1.monthlyRent }
    }

    var occupancyRate: Double {
        let totalUnits = properties.reduce(0) { partial, property in
            partial + max(1, property.units)
        }
        guard totalUnits > 0 else { return 0 }
        let occupiedUnits = min(totalUnits, tenants.filter { $0.isActive }.count)
        return Double(occupiedUnits) / Double(totalUnits)
    }

    var pendingMaintenanceCount: Int {
        maintenanceRequests.filter { $0.status != "completed" && $0.status != "cancelled" }.count
    }

    var urgentMaintenanceCount: Int {
        maintenanceRequests.filter {
            ["high", "urgent", "emergency"].contains($0.priority) &&
            $0.status != "completed" &&
            $0.status != "cancelled"
        }.count
    }

    var expiredLeaseCount: Int {
        let now = Date()
        return tenants.filter { $0.isActive && $0.leaseEndDateValue < now }.count
    }

    var expiringLeaseCount: Int {
        let now = Date()
        guard let windowEnd = Calendar.current.date(byAdding: .day, value: 45, to: now) else { return 0 }
        return tenants.filter {
            $0.isActive && $0.leaseEndDateValue >= now && $0.leaseEndDateValue <= windowEnd
        }.count
    }

    var portfolioHealthScore: Int {
        if properties.isEmpty && maintenanceRequests.isEmpty {
            return 0
        }

        let activeMaintenance = maintenanceRequests.filter {
            $0.status != "completed" && $0.status != "cancelled"
        }.count

        let vacancyPenalty = min(35, Int((1 - occupancyRate) * 40))
        let maintenancePenalty = min(28, activeMaintenance * 4)
        let urgentPenalty = min(24, urgentMaintenanceCount * 6)
        let leasePenalty = min(18, expiredLeaseCount * 5 + expiringLeaseCount * 2)

        let score = 100 - vacancyPenalty - maintenancePenalty - urgentPenalty - leasePenalty
        return max(0, min(100, score))
    }

    var portfolioHealthSummary: String {
        let activeIssues = pendingMaintenanceCount
        let urgentIssues = urgentMaintenanceCount
        let expiringLeases = expiringLeaseCount + expiredLeaseCount
        return "Based on occupancy, \(activeIssues) active issues (\(urgentIssues) urgent), and \(expiringLeases) lease risks."
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
                mortgageLoanBalance: convexProperty.mortgageLoanBalance,
                mortgageAPR: convexProperty.mortgageAPR,
                mortgageMonthlyPayment: convexProperty.mortgageMonthlyPayment,
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
            async let rents = fetchRentPayments()
            async let exps = fetchExpenses()
            async let policies = fetchInsurancePolicies()
            async let licenses = fetchRentalLicenses()

            properties = try await props
            tenants = try await tens
            maintenanceRequests = try await reqs
            contractors = try await cons
            rentPayments = try await rents
            expenses = try await exps
            insurancePolicies = try await policies
            rentalLicenses = try await licenses
            marketTrends = (try? await fetchMarketTrends()) ?? []

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
            self?.generateFeedEvents()
        }

        client.subscribe(
            to: ConvexConfig.Functions.getRentPayments,
            args: ["userId": userId]
        ) { [weak self] (payments: [ConvexRentPayment]) in
            self?.rentPayments = payments
        }

        client.subscribe(
            to: ConvexConfig.Functions.getExpenses,
            args: ["userId": userId]
        ) { [weak self] (expenses: [ConvexExpense]) in
            self?.expenses = expenses
        }

        client.subscribe(
            to: ConvexConfig.Functions.getInsurancePolicies,
            args: ["userId": userId]
        ) { [weak self] (policies: [ConvexInsurancePolicy]) in
            self?.insurancePolicies = policies
            self?.generateFeedEvents()
        }

        client.subscribe(
            to: ConvexConfig.Functions.getRentalLicenses,
            args: ["userId": userId]
        ) { [weak self] (licenses: [ConvexRentalLicense]) in
            self?.rentalLicenses = licenses
            self?.generateFeedEvents()
        }

        client.subscribe(
            to: ConvexConfig.Functions.getMarketTrends,
            args: ["userId": userId]
        ) { [weak self] (trends: [ConvexMarketTrend]) in
            self?.marketTrends = trends
        }
    }

    func unsubscribeFromUpdates() {
        client.unsubscribe(from: ConvexConfig.Functions.getProperties)
        client.unsubscribe(from: ConvexConfig.Functions.getMaintenanceRequests)
        client.unsubscribe(from: ConvexConfig.Functions.getTenants)
        client.unsubscribe(from: ConvexConfig.Functions.getRentPayments)
        client.unsubscribe(from: ConvexConfig.Functions.getExpenses)
        client.unsubscribe(from: ConvexConfig.Functions.getInsurancePolicies)
        client.unsubscribe(from: ConvexConfig.Functions.getRentalLicenses)
        client.unsubscribe(from: ConvexConfig.Functions.getMarketTrends)
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

    func updateMaintenanceRequest(
        id: String,
        title: String,
        descriptionText: String,
        category: String,
        priority: String,
        notes: String?,
        estimatedCost: Double?,
        actualCost: Double?,
        scheduledDate: Date?
    ) async throws -> ConvexMaintenanceRequest {
        var args: [String: Any] = [
            "id": id,
            "title": title,
            "descriptionText": descriptionText,
            "category": category,
            "priority": priority
        ]
        if let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            args["notes"] = notes
        }
        if let estimatedCost { args["estimatedCost"] = estimatedCost }
        if let actualCost { args["actualCost"] = actualCost }
        if let scheduledDate {
            args["scheduledDate"] = scheduledDate.timeIntervalSince1970 * 1000
        }
        return try await client.mutation(ConvexConfig.Functions.updateMaintenanceRequest, args: args)
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

    // MARK: - Rent Payments
    func fetchRentPayments() async throws -> [ConvexRentPayment] {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        return try await client.query(
            ConvexConfig.Functions.getRentPayments,
            args: ["userId": userId]
        )
    }

    func createRentPayment(_ payment: ConvexRentPaymentInput) async throws -> ConvexRentPayment {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        var args = payment.toDictionary()
        args["userId"] = userId
        return try await client.mutation(ConvexConfig.Functions.createRentPayment, args: args)
    }

    func updateRentPayment(
        id: String,
        propertyId: String,
        tenantId: String?,
        clearTenantId: Bool,
        amount: Double,
        paymentDate: Date,
        paymentMethod: String,
        status: String,
        transactionId: String,
        notes: String
    ) async throws -> ConvexRentPayment {
        var args: [String: Any] = [
            "id": id,
            "propertyId": propertyId,
            "amount": amount,
            "paymentDate": paymentDate.timeIntervalSince1970 * 1000,
            "status": status,
            "paymentMethod": paymentMethod,
            "transactionId": transactionId,
            "notes": notes
        ]

        if clearTenantId {
            args["clearTenantId"] = true
        } else if let tenantId = tenantId, !tenantId.isEmpty {
            args["tenantId"] = tenantId
        }

        return try await client.mutation(ConvexConfig.Functions.updateRentPayment, args: args)
    }

    func deleteRentPayment(id: String) async throws {
        try await client.mutation(
            ConvexConfig.Functions.deleteRentPayment,
            args: ["id": id]
        )
    }

    // MARK: - Expenses
    func fetchExpenses() async throws -> [ConvexExpense] {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        return try await client.query(
            ConvexConfig.Functions.getExpenses,
            args: ["userId": userId]
        )
    }

    // MARK: - Insurance Policies
    func fetchInsurancePolicies() async throws -> [ConvexInsurancePolicy] {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        return try await client.query(
            ConvexConfig.Functions.getInsurancePolicies,
            args: ["userId": userId]
        )
    }

    // MARK: - Rental Licenses
    func fetchRentalLicenses() async throws -> [ConvexRentalLicense] {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        return try await client.query(
            ConvexConfig.Functions.getRentalLicenses,
            args: ["userId": userId]
        )
    }

    // MARK: - Market Trends
    func fetchMarketTrends(propertyId: String? = nil) async throws -> [ConvexMarketTrend] {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        var args: [String: Any] = ["userId": userId]
        if let propertyId, !propertyId.isEmpty {
            args["propertyId"] = propertyId
        }
        return try await client.query(
            ConvexConfig.Functions.getMarketTrends,
            args: args
        )
    }

    func refreshLiveMarketTrend(propertyId: String) async throws -> ConvexLiveMarketRefreshResult {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        let result: ConvexLiveMarketRefreshResult = try await client.action(
            ConvexConfig.Functions.refreshLiveMarketTrend,
            args: ["userId": userId, "propertyId": propertyId]
        )
        marketTrends = try await fetchMarketTrends()
        return result
    }

    func refreshLiveMarketPortfolio() async throws -> ConvexLiveMarketPortfolioResult {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        let result: ConvexLiveMarketPortfolioResult = try await client.action(
            ConvexConfig.Functions.refreshLiveMarketPortfolio,
            args: ["userId": userId]
        )
        marketTrends = try await fetchMarketTrends()
        return result
    }

    func createExpense(_ expense: ConvexExpenseInput) async throws -> ConvexExpense {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        var args = expense.toDictionary()
        args["userId"] = userId
        return try await client.mutation(ConvexConfig.Functions.createExpense, args: args)
    }

    func updateExpense(
        id: String,
        propertyId: String?,
        clearPropertyId: Bool,
        title: String,
        description: String,
        amount: Double,
        category: String,
        date: Date,
        isRecurring: Bool,
        recurringFrequency: String,
        receiptURL: String,
        vendor: String,
        notes: String
    ) async throws -> ConvexExpense {
        var args: [String: Any] = [
            "id": id,
            "title": title,
            "description": description,
            "amount": amount,
            "category": category,
            "date": date.timeIntervalSince1970 * 1000,
            "isRecurring": isRecurring,
            "recurringFrequency": recurringFrequency,
            "receiptURL": receiptURL,
            "vendor": vendor,
            "notes": notes
        ]

        if clearPropertyId {
            args["clearPropertyId"] = true
        } else if let propertyId = propertyId, !propertyId.isEmpty {
            args["propertyId"] = propertyId
        }

        return try await client.mutation(ConvexConfig.Functions.updateExpense, args: args)
    }

    func deleteExpense(id: String) async throws {
        try await client.mutation(
            ConvexConfig.Functions.deleteExpense,
            args: ["id": id]
        )
    }

    func createInsurancePolicy(
        propertyId: String?,
        propertyLabel: String,
        insuranceName: String,
        policyNumber: String,
        termStart: Date,
        termEnd: Date,
        premium: Double,
        notes: String?,
        agent: String?
    ) async throws -> ConvexInsurancePolicy {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        var args: [String: Any] = [
            "propertyLabel": propertyLabel,
            "insuranceName": insuranceName,
            "policyNumber": policyNumber,
            "termStart": termStart.timeIntervalSince1970 * 1000,
            "termEnd": termEnd.timeIntervalSince1970 * 1000,
            "premium": premium,
            "userId": userId
        ]
        if let propertyId = propertyId, !propertyId.isEmpty { args["propertyId"] = propertyId }
        if let notes = notes { args["notes"] = notes }
        if let agent = agent { args["agent"] = agent }
        return try await client.mutation(ConvexConfig.Functions.createInsurancePolicy, args: args)
    }

    func updateInsurancePolicy(
        id: String,
        propertyId: String?,
        propertyLabel: String,
        insuranceName: String,
        policyNumber: String,
        termStart: Date,
        termEnd: Date,
        premium: Double,
        notes: String?,
        agent: String?
    ) async throws -> ConvexInsurancePolicy {
        var args: [String: Any] = [
            "id": id,
            "propertyLabel": propertyLabel,
            "insuranceName": insuranceName,
            "policyNumber": policyNumber,
            "termStart": termStart.timeIntervalSince1970 * 1000,
            "termEnd": termEnd.timeIntervalSince1970 * 1000,
            "premium": premium
        ]
        if let propertyId = propertyId { args["propertyId"] = propertyId }
        if let notes = notes { args["notes"] = notes }
        if let agent = agent { args["agent"] = agent }
        return try await client.mutation(ConvexConfig.Functions.updateInsurancePolicy, args: args)
    }

    func deleteInsurancePolicy(id: String) async throws {
        try await client.mutation(
            ConvexConfig.Functions.deleteInsurancePolicy,
            args: ["id": id]
        )
    }

    func createRentalLicense(
        propertyId: String?,
        propertyLabel: String,
        category: String,
        licenseNumber: String,
        dateFrom: Date,
        dateTo: Date,
        unitFees: Double,
        link: String?,
        notes: String?
    ) async throws -> ConvexRentalLicense {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        var args: [String: Any] = [
            "propertyLabel": propertyLabel,
            "category": category,
            "licenseNumber": licenseNumber,
            "dateFrom": dateFrom.timeIntervalSince1970 * 1000,
            "dateTo": dateTo.timeIntervalSince1970 * 1000,
            "unitFees": unitFees,
            "userId": userId
        ]
        if let propertyId = propertyId, !propertyId.isEmpty { args["propertyId"] = propertyId }
        if let link = link { args["link"] = link }
        if let notes = notes { args["notes"] = notes }
        return try await client.mutation(ConvexConfig.Functions.createRentalLicense, args: args)
    }

    func updateRentalLicense(
        id: String,
        propertyId: String?,
        propertyLabel: String,
        category: String,
        licenseNumber: String,
        dateFrom: Date,
        dateTo: Date,
        unitFees: Double,
        link: String?,
        notes: String?
    ) async throws -> ConvexRentalLicense {
        var args: [String: Any] = [
            "id": id,
            "propertyLabel": propertyLabel,
            "category": category,
            "licenseNumber": licenseNumber,
            "dateFrom": dateFrom.timeIntervalSince1970 * 1000,
            "dateTo": dateTo.timeIntervalSince1970 * 1000,
            "unitFees": unitFees
        ]
        if let propertyId = propertyId { args["propertyId"] = propertyId }
        if let link = link { args["link"] = link }
        if let notes = notes { args["notes"] = notes }
        return try await client.mutation(ConvexConfig.Functions.updateRentalLicense, args: args)
    }

    func deleteRentalLicense(id: String) async throws {
        try await client.mutation(
            ConvexConfig.Functions.deleteRentalLicense,
            args: ["id": id]
        )
    }

    func createMarketTrend(_ trend: ConvexMarketTrendInput) async throws -> ConvexMarketTrend {
        guard let userId = effectiveUserId else {
            throw ConvexError.notAuthenticated
        }
        var args = trend.toDictionary()
        args["userId"] = userId
        return try await client.mutation(
            ConvexConfig.Functions.createMarketTrend,
            args: args
        )
    }

    func updateMarketTrend(_ trend: ConvexMarketTrendUpdateInput) async throws -> ConvexMarketTrend {
        return try await client.mutation(
            ConvexConfig.Functions.updateMarketTrend,
            args: trend.toDictionary()
        )
    }

    func deleteMarketTrend(id: String) async throws {
        try await client.mutation(
            ConvexConfig.Functions.deleteMarketTrend,
            args: ["id": id]
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

    func updateContractor(
        id: String,
        companyName: String,
        contactName: String,
        address: String?,
        website: String?,
        notes: String?,
        email: String,
        phone: String,
        specialty: [String],
        hourlyRate: Double?,
        rating: Double?,
        isPreferred: Bool
    ) async throws -> ConvexContractor {
        var args: [String: Any] = [
            "id": id,
            "companyName": companyName,
            "contactName": contactName,
            "email": email,
            "phone": phone,
            "specialty": specialty,
            "isPreferred": isPreferred
        ]
        if let address = address { args["address"] = address }
        if let website = website { args["website"] = website }
        if let notes = notes { args["notes"] = notes }
        if let hourlyRate = hourlyRate { args["hourlyRate"] = hourlyRate }
        if let rating = rating { args["rating"] = rating }

        return try await client.mutation(ConvexConfig.Functions.updateContractor, args: args)
    }

    // MARK: - Feed Events
    private func generateFeedEvents() {
        var events: [ConvexFeedEvent] = []
        let now = Date()

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

        // Lease expiration alerts (active tenants only)
        for tenant in tenants where tenant.isActive {
            let days = daysUntil(date: tenant.leaseEndDateValue)
            guard days <= 60 else { continue }

            let expired = days < 0
            let absDays = abs(days)
            let urgency = severity(daysUntil: days)
            let subtitle = expired
                ? "Lease expired \(absDays)d ago"
                : "Lease ends in \(days)d"

            let event = ConvexFeedEvent(
                id: "lease-\(tenant.id)",
                type: "leaseExpiry",
                title: "Lease Renewal Alert",
                subtitle: subtitle,
                detail: "\(tenant.fullName) • \(friendlyDate(tenant.leaseEndDateValue))",
                timestamp: tenant.leaseEndDateValue,
                isActionRequired: urgency >= 2,
                actionLabel: urgency >= 2 ? "Review Lease" : nil,
                priority: urgency,
                relatedId: tenant.id
            )
            events.append(event)
        }

        // Insurance expiration alerts
        for policy in insurancePolicies {
            let days = daysUntil(date: policy.termEndDate)
            guard days <= 60 else { continue }

            let expired = days < 0
            let absDays = abs(days)
            let urgency = severity(daysUntil: days)
            let subtitle = expired
                ? "Policy expired \(absDays)d ago"
                : "Policy ends in \(days)d"

            let event = ConvexFeedEvent(
                id: "insurance-\(policy.id)",
                type: "insuranceExpiry",
                title: "Insurance Renewal Alert",
                subtitle: subtitle,
                detail: "\(policy.insuranceName) • \(policy.propertyLabel) • \(friendlyDate(policy.termEndDate))",
                timestamp: policy.termEndDate,
                isActionRequired: urgency >= 2,
                actionLabel: urgency >= 2 ? "Renew Policy" : nil,
                priority: urgency,
                relatedId: policy.id
            )
            events.append(event)
        }

        // Rental license expiration alerts
        for license in rentalLicenses {
            let days = daysUntil(date: license.dateToValue)
            guard days <= 90 else { continue }

            let expired = days < 0
            let absDays = abs(days)
            let urgency = severity(daysUntil: days)
            let subtitle = expired
                ? "License expired \(absDays)d ago"
                : "License ends in \(days)d"

            let event = ConvexFeedEvent(
                id: "license-\(license.id)",
                type: "licenseExpiry",
                title: "Rental License Alert",
                subtitle: subtitle,
                detail: "\(license.category) • \(license.propertyLabel) • \(friendlyDate(license.dateToValue))",
                timestamp: license.dateToValue,
                isActionRequired: urgency >= 2,
                actionLabel: urgency >= 2 ? "Renew License" : nil,
                priority: urgency,
                relatedId: license.id
            )
            events.append(event)
        }

        // Sort by priority, then upcoming deadlines (soonest first), then recent events.
        feedEvents = events.sorted { event1, event2 in
            if event1.priority != event2.priority {
                return event1.priority > event2.priority
            }

            let event1IsFuture = event1.timestamp >= now
            let event2IsFuture = event2.timestamp >= now
            if event1IsFuture && event2IsFuture {
                return event1.timestamp < event2.timestamp
            }
            if event1IsFuture != event2IsFuture {
                return event1IsFuture
            }
            return event1.timestamp > event2.timestamp
        }
    }

    private func daysUntil(date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    private func severity(daysUntil: Int) -> Int {
        if daysUntil < 0 { return 3 }
        if daysUntil <= 14 { return 3 }
        if daysUntil <= 30 { return 2 }
        return 1
    }

    private func friendlyDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Convex Data Models (must match convex/schema.ts)

struct ConvexProperty: Codable, Identifiable, Hashable {
    static func == (lhs: ConvexProperty, rhs: ConvexProperty) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
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
    var mortgageLoanBalance: Double? = nil
    var mortgageAPR: Double? = nil
    var mortgageMonthlyPayment: Double? = nil
    var imageURL: String?
    var notes: String?
    var createdAt: Double // Unix timestamp in ms
    var updatedAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, address, city, state, zipCode, propertyType, units
        case monthlyRent, purchasePrice, currentValue, mortgageLoanBalance, mortgageAPR, mortgageMonthlyPayment, imageURL, notes
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
    var mortgageLoanBalance: Double? = nil
    var mortgageAPR: Double? = nil
    var mortgageMonthlyPayment: Double? = nil
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
        if let mortgageLoanBalance { dict["mortgageLoanBalance"] = mortgageLoanBalance }
        if let mortgageAPR { dict["mortgageAPR"] = mortgageAPR }
        if let mortgageMonthlyPayment { dict["mortgageMonthlyPayment"] = mortgageMonthlyPayment }
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

    var updatedAtDate: Date {
        Date(timeIntervalSince1970: updatedAt / 1000)
    }

    var scheduledDateValue: Date? {
        guard let ts = scheduledDate else { return nil }
        return Date(timeIntervalSince1970: ts / 1000)
    }

    var completedDateValue: Date? {
        guard let ts = completedDate else { return nil }
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

struct ConvexRentPayment: Codable, Identifiable {
    let id: String
    var propertyId: String
    var tenantId: String?
    var amount: Double
    var paymentDate: Double
    var paymentMethod: String?
    var status: String
    var transactionId: String?
    var notes: String?
    var createdAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case propertyId, tenantId, amount, paymentDate, paymentMethod, status, transactionId, notes, createdAt
    }

    var paymentDateValue: Date {
        Date(timeIntervalSince1970: paymentDate / 1000)
    }
}

struct ConvexRentPaymentInput {
    var propertyId: String
    var tenantId: String?
    var amount: Double
    var paymentDate: Date
    var paymentMethod: String?
    var status: String
    var transactionId: String?
    var notes: String?

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "propertyId": propertyId,
            "amount": amount,
            "paymentDate": paymentDate.timeIntervalSince1970 * 1000,
            "status": status
        ]
        if let tenantId { dict["tenantId"] = tenantId }
        if let paymentMethod { dict["paymentMethod"] = paymentMethod }
        if let transactionId { dict["transactionId"] = transactionId }
        if let notes { dict["notes"] = notes }
        return dict
    }
}

struct ConvexExpense: Codable, Identifiable {
    let id: String
    var propertyId: String?
    var title: String
    var description: String?
    var amount: Double
    var category: String
    var date: Double
    var isRecurring: Bool
    var recurringFrequency: String?
    var receiptURL: String?
    var vendor: String?
    var notes: String?
    var createdAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case propertyId, title, description, amount, category, date, isRecurring, recurringFrequency
        case receiptURL, vendor, notes, createdAt
    }

    var dateValue: Date {
        Date(timeIntervalSince1970: date / 1000)
    }
}

struct ConvexExpenseInput {
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

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "amount": amount,
            "category": category,
            "date": date.timeIntervalSince1970 * 1000,
            "isRecurring": isRecurring
        ]
        if let propertyId { dict["propertyId"] = propertyId }
        if let description { dict["description"] = description }
        if let recurringFrequency { dict["recurringFrequency"] = recurringFrequency }
        if let receiptURL { dict["receiptURL"] = receiptURL }
        if let vendor { dict["vendor"] = vendor }
        if let notes { dict["notes"] = notes }
        return dict
    }
}

struct ConvexInsurancePolicy: Codable, Identifiable {
    let id: String
    var propertyId: String?
    var propertyLabel: String
    var insuranceName: String
    var policyNumber: String
    var termStart: Double
    var termEnd: Double
    var premium: Double
    var notes: String?
    var agent: String?
    var createdAt: Double
    var updatedAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case propertyId, propertyLabel, insuranceName, policyNumber
        case termStart, termEnd, premium, notes, agent
        case createdAt, updatedAt
    }

    static let termFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    static let premiumFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var termStartDate: Date {
        Date(timeIntervalSince1970: termStart / 1000)
    }

    var termEndDate: Date {
        Date(timeIntervalSince1970: termEnd / 1000)
    }

    var termDisplay: String {
        "\(Self.termFormatter.string(from: termStartDate)) – \(Self.termFormatter.string(from: termEndDate))"
    }

    var premiumDisplay: String {
        Self.premiumFormatter.string(from: NSNumber(value: premium)) ?? "$\(premium)"
    }

    var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: termEndDate).day ?? 0
    }

    var isExpired: Bool {
        daysUntilExpiration < 0
    }

    var isExpiringSoon: Bool {
        daysUntilExpiration >= 0 && daysUntilExpiration <= 60
    }
}

struct ConvexRentalLicense: Codable, Identifiable {
    let id: String
    var propertyId: String?
    var propertyLabel: String
    var category: String
    var licenseNumber: String
    var dateFrom: Double
    var dateTo: Double
    var unitFees: Double
    var link: String?
    var notes: String?
    var createdAt: Double
    var updatedAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case propertyId, propertyLabel, category, licenseNumber
        case dateFrom, dateTo, unitFees, link, notes
        case createdAt, updatedAt
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    static let moneyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var dateFromValue: Date {
        Date(timeIntervalSince1970: dateFrom / 1000)
    }

    var dateToValue: Date {
        Date(timeIntervalSince1970: dateTo / 1000)
    }

    var termDisplay: String {
        "\(Self.dateFormatter.string(from: dateFromValue)) – \(Self.dateFormatter.string(from: dateToValue))"
    }

    var unitFeesDisplay: String {
        Self.moneyFormatter.string(from: NSNumber(value: unitFees)) ?? "$\(unitFees)"
    }

    var daysUntilExpiration: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dateToValue).day ?? 0
    }

    var isExpired: Bool {
        daysUntilExpiration < 0
    }

    var isExpiringSoon: Bool {
        daysUntilExpiration >= 0 && daysUntilExpiration <= 60
    }
}

struct ConvexMarketTrend: Codable, Identifiable {
    let id: String
    var propertyId: String?
    var title: String
    var marketType: String
    var areaLabel: String
    var estimatePrice: Double?
    var estimateRent: Double?
    var yoyChangePct: Double?
    var demandLevel: String?
    var source: String?
    var sourceURL: String?
    var notes: String?
    var observedAt: Double
    var createdAt: Double
    var updatedAt: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case propertyId, title, marketType, areaLabel
        case estimatePrice, estimateRent, yoyChangePct, demandLevel
        case source, sourceURL, notes, observedAt, createdAt, updatedAt
    }

    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var observedDate: Date {
        Date(timeIntervalSince1970: observedAt / 1000)
    }

    var priceDisplay: String {
        guard let estimatePrice else { return "—" }
        return Self.currencyFormatter.string(from: NSNumber(value: estimatePrice)) ?? "$\(Int(estimatePrice))"
    }

    var rentDisplay: String {
        guard let estimateRent else { return "—" }
        return Self.currencyFormatter.string(from: NSNumber(value: estimateRent)) ?? "$\(Int(estimateRent))"
    }
}

struct ConvexMarketTrendInput {
    var propertyId: String?
    var title: String
    var marketType: String
    var areaLabel: String
    var estimatePrice: Double?
    var estimateRent: Double?
    var yoyChangePct: Double?
    var demandLevel: String?
    var source: String?
    var sourceURL: String?
    var notes: String?
    var observedAt: Date?

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "marketType": marketType,
            "areaLabel": areaLabel
        ]
        if let propertyId, !propertyId.isEmpty { dict["propertyId"] = propertyId }
        if let estimatePrice { dict["estimatePrice"] = estimatePrice }
        if let estimateRent { dict["estimateRent"] = estimateRent }
        if let yoyChangePct { dict["yoyChangePct"] = yoyChangePct }
        if let demandLevel, !demandLevel.isEmpty { dict["demandLevel"] = demandLevel }
        if let source, !source.isEmpty { dict["source"] = source }
        if let sourceURL, !sourceURL.isEmpty { dict["sourceURL"] = sourceURL }
        if let notes, !notes.isEmpty { dict["notes"] = notes }
        if let observedAt { dict["observedAt"] = observedAt.timeIntervalSince1970 * 1000 }
        return dict
    }
}

struct ConvexMarketTrendUpdateInput {
    var id: String
    var title: String
    var marketType: String
    var areaLabel: String
    var estimatePrice: Double?
    var estimateRent: Double?
    var yoyChangePct: Double?
    var demandLevel: String?
    var source: String?
    var sourceURL: String?
    var notes: String?
    var observedAt: Date?

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "title": title,
            "marketType": marketType,
            "areaLabel": areaLabel
        ]
        if let estimatePrice { dict["estimatePrice"] = estimatePrice }
        if let estimateRent { dict["estimateRent"] = estimateRent }
        if let yoyChangePct { dict["yoyChangePct"] = yoyChangePct }
        if let demandLevel, !demandLevel.isEmpty { dict["demandLevel"] = demandLevel }
        if let source, !source.isEmpty { dict["source"] = source }
        if let sourceURL, !sourceURL.isEmpty { dict["sourceURL"] = sourceURL }
        if let notes, !notes.isEmpty { dict["notes"] = notes }
        if let observedAt { dict["observedAt"] = observedAt.timeIntervalSince1970 * 1000 }
        return dict
    }
}

struct ConvexLiveMarketRefreshResult: Codable {
    let success: Bool
    let propertyId: String
    let propertyName: String
    let trendId: String?
    let estimatePrice: Double?
    let estimateRent: Double?
    let source: String?
}

struct ConvexLiveMarketPortfolioItem: Codable, Identifiable {
    let propertyId: String
    let propertyName: String
    let error: String?

    var id: String { propertyId }
}

struct ConvexLiveMarketPortfolioResult: Codable {
    let success: Bool
    let totalProperties: Int
    let refreshed: Int
    let failed: Int
    let refreshedItems: [ConvexLiveMarketPortfolioItem]
    let failedItems: [ConvexLiveMarketPortfolioItem]
}

struct ConvexContractor: Codable, Identifiable {
    let id: String
    var companyName: String
    var contactName: String
    var address: String?
    var website: String?
    var notes: String?
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
        case companyName, contactName, address, website, notes, email, phone
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
    var address: String?
    var website: String?
    var notes: String?
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
        if let address = address, !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dict["address"] = address
        }
        if let website = website, !website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dict["website"] = website
        }
        if let notes = notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            dict["notes"] = notes
        }
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

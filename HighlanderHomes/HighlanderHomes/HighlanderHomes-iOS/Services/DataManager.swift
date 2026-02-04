import SwiftUI
import SwiftData
import Combine

/// Central data manager that syncs Firebase data to local SwiftData
/// Provides offline-first capability with real-time sync
@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()

    // MARK: - Published State
    @Published var properties: [Property] = []
    @Published var tenants: [Tenant] = []
    @Published var maintenanceRequests: [MaintenanceRequest] = []
    @Published var contractors: [Contractor] = []
    @Published var feedEvents: [FeedEvent] = []

    @Published var isLoading: Bool = false
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    // MARK: - Computed Statistics
    var totalMonthlyRevenue: Double {
        properties.reduce(0) { $0 + $1.monthlyRent }
    }

    var occupancyRate: Double {
        guard !properties.isEmpty else { return 0 }
        let totalUnits = properties.reduce(0) { $0 + $1.units }
        let occupiedUnits = tenants.filter { $0.isActive }.count
        guard totalUnits > 0 else { return 0 }
        return Double(occupiedUnits) / Double(totalUnits)
    }

    var pendingMaintenanceCount: Int {
        maintenanceRequests.filter { $0.status != .completed && $0.status != .cancelled }.count
    }

    var urgentMaintenanceCount: Int {
        maintenanceRequests.filter { $0.isUrgent && $0.status != .completed }.count
    }

    var portfolioHealthScore: Int {
        guard !properties.isEmpty else { return 100 }
        let totalScore = properties.reduce(0) { $0 + $1.healthScore }
        return totalScore / properties.count
    }

    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Setup
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLocalData()
    }

    // MARK: - Local Data Loading
    private func loadLocalData() {
        guard let context = modelContext else { return }

        do {
            // Load properties
            let propertyDescriptor = FetchDescriptor<Property>(sortBy: [SortDescriptor(\.name)])
            properties = try context.fetch(propertyDescriptor)

            // Load tenants
            let tenantDescriptor = FetchDescriptor<Tenant>(sortBy: [SortDescriptor(\.lastName)])
            tenants = try context.fetch(tenantDescriptor)

            // Load maintenance requests
            let maintenanceDescriptor = FetchDescriptor<MaintenanceRequest>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            maintenanceRequests = try context.fetch(maintenanceDescriptor)

            // Load contractors
            let contractorDescriptor = FetchDescriptor<Contractor>(sortBy: [SortDescriptor(\.companyName)])
            contractors = try context.fetch(contractorDescriptor)

            // Load feed events
            let feedDescriptor = FetchDescriptor<FeedEvent>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            feedEvents = try context.fetch(feedDescriptor)

            print("Loaded local data: \(properties.count) properties, \(tenants.count) tenants, \(maintenanceRequests.count) requests")
        } catch {
            print("Error loading local data: \(error)")
        }
    }

    // MARK: - Firebase Sync
    func syncWithFirebase() async {
        guard let context = modelContext else { return }

        isSyncing = true
        syncError = nil

        do {
            // Fetch all data from Firebase
            async let firebaseProperties = FirebaseService.shared.fetchProperties()
            async let firebaseTenants = FirebaseService.shared.fetchTenants()
            async let firebaseRequests = FirebaseService.shared.fetchMaintenanceRequests()
            async let firebaseContractors = FirebaseService.shared.fetchContractors()

            let (props, tens, reqs, cons) = try await (
                firebaseProperties,
                firebaseTenants,
                firebaseRequests,
                firebaseContractors
            )

            // Sync properties
            await syncProperties(props, context: context)

            // Sync tenants
            await syncTenants(tens, context: context)

            // Sync maintenance requests
            await syncMaintenanceRequests(reqs, context: context)

            // Sync contractors
            await syncContractors(cons, context: context)

            // Generate feed events from recent changes
            generateFeedEvents(context: context)

            // Save context
            try context.save()

            // Reload local data
            loadLocalData()

            lastSyncDate = Date()
            HapticManager.shared.success()

            print("Sync completed successfully")
        } catch {
            syncError = error.localizedDescription
            HapticManager.shared.error()
            print("Sync error: \(error)")
        }

        isSyncing = false
    }

    // MARK: - Property Sync
    private func syncProperties(_ firebaseProperties: [PropertyFirestore], context: ModelContext) async {
        for fbProperty in firebaseProperties {
            guard let fbId = fbProperty.id else { continue }

            // Check if property exists locally
            let existingProperty = properties.first { $0.id.uuidString == fbId }

            if let existing = existingProperty {
                // Update existing
                existing.address = fbProperty.address ?? ""
                existing.city = fbProperty.city ?? ""
                existing.state = fbProperty.state ?? ""
                existing.zipCode = fbProperty.zipCode ?? ""
                existing.monthlyRent = fbProperty.monthlyRent ?? 0
                existing.units = fbProperty.bedrooms ?? 1
                existing.updatedAt = Date()
            } else {
                // Create new property
                let newProperty = Property(
                    name: fbProperty.address ?? "",
                    address: fbProperty.address ?? "",
                    city: fbProperty.city ?? "",
                    state: fbProperty.state ?? "",
                    zipCode: fbProperty.zipCode ?? "",
                    propertyType: mapPropertyType(fbProperty.status ?? ""),
                    units: fbProperty.bedrooms ?? 1,
                    monthlyRent: fbProperty.monthlyRent ?? 0
                )
                context.insert(newProperty)
            }
        }
    }

    // MARK: - Tenant Sync
    private func syncTenants(_ firebaseTenants: [TenantFirestore], context: ModelContext) async {
        for fbTenant in firebaseTenants {
            guard let fbId = fbTenant.id else { continue }

            let existingTenant = tenants.first { $0.id.uuidString == fbId }

            if let existing = existingTenant {
                // Update existing
                let names = fbTenant.name.split(separator: " ")
                existing.firstName = String(names.first ?? "")
                existing.lastName = names.count > 1 ? String(names.dropFirst().joined(separator: " ")) : ""
                existing.email = fbTenant.email
                existing.phone = fbTenant.phone
                existing.monthlyRent = fbTenant.monthlyRent ?? 0
                existing.updatedAt = Date()
            } else {
                // Create new tenant
                let names = fbTenant.name.split(separator: " ")
                let newTenant = Tenant(
                    firstName: String(names.first ?? ""),
                    lastName: names.count > 1 ? String(names.dropFirst().joined(separator: " ")) : "",
                    email: fbTenant.email,
                    phone: fbTenant.phone,
                    leaseStartDate: parseDate(fbTenant.leaseStartDate) ?? Date(),
                    leaseEndDate: parseDate(fbTenant.leaseEndDate) ?? Date().addingTimeInterval(86400 * 365),
                    monthlyRent: fbTenant.monthlyRent ?? 0
                )
                context.insert(newTenant)
            }
        }
    }

    // MARK: - Maintenance Sync
    private func syncMaintenanceRequests(_ firebaseRequests: [MaintenanceRequestFirestore], context: ModelContext) async {
        for fbRequest in firebaseRequests {
            guard let fbId = fbRequest.id else { continue }

            let existingRequest = maintenanceRequests.first { $0.id.uuidString == fbId }

            if let existing = existingRequest {
                // Update existing
                existing.title = fbRequest.title
                existing.descriptionText = fbRequest.description ?? ""
                existing.status = mapMaintenanceStatus(fbRequest.status)
                existing.priority = mapMaintenancePriority(fbRequest.priority)
                existing.category = mapMaintenanceCategory(fbRequest.category)
                existing.updatedAt = Date()
            } else {
                // Create new request
                let newRequest = MaintenanceRequest(
                    title: fbRequest.title,
                    descriptionText: fbRequest.description ?? "",
                    category: mapMaintenanceCategory(fbRequest.category),
                    priority: mapMaintenancePriority(fbRequest.priority),
                    status: mapMaintenanceStatus(fbRequest.status)
                )
                context.insert(newRequest)
            }
        }
    }

    // MARK: - Contractor Sync
    private func syncContractors(_ firebaseContractors: [ContractorFirestore], context: ModelContext) async {
        for fbContractor in firebaseContractors {
            guard let fbId = fbContractor.id else { continue }

            let existingContractor = contractors.first { $0.id.uuidString == fbId }

            if existingContractor == nil {
                // Create new contractor
                let newContractor = Contractor(
                    companyName: fbContractor.company ?? "",
                    contactName: fbContractor.name,
                    email: fbContractor.email ?? "",
                    phone: fbContractor.phone,
                    specialty: [fbContractor.specialty],
                    hourlyRate: fbContractor.hourlyRate
                )
                context.insert(newContractor)
            }
        }
    }

    // MARK: - Feed Event Generation
    private func generateFeedEvents(context: ModelContext) {
        // Create feed events from recent maintenance requests
        for request in maintenanceRequests where request.status != .completed {
            let eventType: FeedEvent.EventType = request.isUrgent ? .maintenanceNew : .maintenanceUpdate

            let existingEvent = feedEvents.first { $0.maintenanceRequestId == request.id }
            if existingEvent == nil {
                let event = FeedEvent(
                    eventType: eventType,
                    title: request.title,
                    subtitle: "\(request.category.rawValue) - \(request.priority.label)",
                    detail: request.descriptionText,
                    isActionRequired: request.status == .new,
                    actionLabel: request.status == .new ? "Assign Contractor" : nil,
                    priority: request.isUrgent ? .urgent : .normal,
                    maintenanceRequestId: request.id
                )
                context.insert(event)
            }
        }
    }

    // MARK: - Helper Methods
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    private func mapPropertyType(_ status: String) -> PropertyType {
        switch status.lowercased() {
        case "occupied", "vacant": return .singleFamily
        case "maintenance": return .singleFamily
        default: return .singleFamily
        }
    }

    private func mapMaintenanceStatus(_ status: String) -> MaintenanceRequest.Status {
        switch status.lowercased() {
        case "pending": return .new
        case "scheduled": return .scheduled
        case "in-progress": return .inProgress
        case "completed": return .completed
        default: return .new
        }
    }

    private func mapMaintenancePriority(_ priority: String) -> MaintenanceRequest.Priority {
        switch priority.lowercased() {
        case "low": return .low
        case "medium": return .normal
        case "high": return .high
        default: return .normal
        }
    }

    private func mapMaintenanceCategory(_ category: String) -> MaintenanceRequest.MaintenanceCategory {
        switch category.lowercased() {
        case "plumbing": return .plumbing
        case "electrical": return .electrical
        case "hvac": return .hvac
        case "appliances": return .appliance
        case "landscaping": return .landscaping
        case "painting", "flooring", "roofing", "general": return .other
        default: return .other
        }
    }

    // MARK: - CRUD Operations
    func addProperty(_ property: Property) {
        guard let context = modelContext else { return }
        context.insert(property)
        try? context.save()
        loadLocalData()

        // Sync to Firebase
        Task {
            let fbProperty = PropertyFirestore(
                address: property.address,
                city: property.city,
                state: property.state,
                zipCode: property.zipCode,
                monthlyRent: property.monthlyRent,
                status: "vacant"
            )
            try? await FirebaseService.shared.saveProperty(fbProperty)
        }
    }

    func addMaintenanceRequest(_ request: MaintenanceRequest) {
        guard let context = modelContext else { return }
        context.insert(request)
        try? context.save()
        loadLocalData()

        // Create feed event
        let event = FeedEvent(
            eventType: .maintenanceNew,
            title: request.title,
            subtitle: "\(request.category.rawValue) - \(request.priority.label)",
            detail: request.descriptionText,
            isActionRequired: true,
            actionLabel: "Assign Contractor",
            priority: request.isUrgent ? .urgent : .normal,
            maintenanceRequestId: request.id
        )
        context.insert(event)
        try? context.save()
        loadLocalData()

        HapticManager.shared.notification(.warning)
    }

    func updateMaintenanceStatus(_ request: MaintenanceRequest, to status: MaintenanceRequest.Status) {
        request.status = status
        request.updatedAt = Date()

        if status == .completed {
            request.completedDate = Date()
            HapticManager.shared.reward()
        }

        try? modelContext?.save()
        loadLocalData()

        // Sync to Firebase
        Task {
            if let id = request.id.uuidString as String? {
                try? await FirebaseService.shared.updateMaintenanceStatus(id: id, status: status.rawValue)
            }
        }
    }
}

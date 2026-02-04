import Foundation
import SwiftData
import Combine

/// Handles offline-first data sync between local SwiftData and remote API
@MainActor
class SyncService: ObservableObject {
    static let shared = SyncService()

    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    @Published var pendingChangesCount: Int = 0

    private var modelContext: ModelContext?
    private var syncTimer: Timer?

    private init() {}

    // MARK: - Setup
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLastSyncDate()
        startAutoSync()
    }

    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }

    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
    }

    // MARK: - Auto Sync
    private func startAutoSync() {
        // Sync every 5 minutes when app is active
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performSync()
            }
        }
    }

    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Manual Sync
    func performSync() async {
        guard !isSyncing else { return }
        guard let context = modelContext else { return }

        isSyncing = true
        syncError = nil

        do {
            // 1. Fetch pending local changes
            let localChanges = try await gatherLocalChanges(context: context)

            // 2. Push local changes to server
            if !localChanges.isEmpty {
                let syncPayload = SyncPayload(
                    expenses: localChanges.expenses,
                    lastSyncTimestamp: lastSyncDate ?? Date.distantPast
                )
                let response = try await APIService.shared.syncLocalChanges(syncPayload)

                // Handle any conflicts
                if let conflicts = response.conflicts, !conflicts.isEmpty {
                    await resolveConflicts(conflicts, context: context)
                }
            }

            // 3. Pull remote changes
            try await pullRemoteChanges(context: context)

            // 4. Update sync timestamp
            lastSyncDate = Date()
            saveLastSyncDate()

            // 5. Clear pending changes
            pendingChangesCount = 0

        } catch {
            syncError = error
            print("Sync failed: \(error.localizedDescription)")
        }

        isSyncing = false
    }

    // MARK: - Local Changes
    private func gatherLocalChanges(context: ModelContext) async throws -> LocalChanges {
        // In a real implementation, you'd track which entities have been
        // modified since the last sync using a "isDirty" flag or change tracking

        // For now, return empty changes - this is a placeholder
        return LocalChanges()
    }

    // MARK: - Pull Remote
    private func pullRemoteChanges(context: ModelContext) async throws {
        // Fetch latest feed events
        let feedEvents = try await APIService.shared.fetchFeedEvents(since: lastSyncDate)

        for dto in feedEvents {
            // Check if event already exists
            // SwiftData predicates can't use global functions like UUID(uuidString:) directly.
            // Simple approach: fetch all and check in-memory since dataset is small.
            let existing = try context.fetch(FetchDescriptor<FeedEvent>())
                .first { $0.id == UUID(uuidString: dto.id) }

            if existing == nil {
                let event = FeedEvent(
                    id: UUID(uuidString: dto.id) ?? UUID(),
                    eventType: mapEventType(dto.eventType),
                    title: dto.title,
                    subtitle: dto.subtitle,
                    detail: dto.detail,
                    timestamp: dto.timestamp,
                    isRead: dto.isRead,
                    isActionRequired: dto.isActionRequired,
                    actionLabel: dto.actionLabel,
                    priority: FeedEvent.Priority(rawValue: dto.priority) ?? .normal
                )
                context.insert(event)
            }
        }

        try context.save()
    }

    // MARK: - Conflict Resolution
    private func resolveConflicts(_ conflicts: [SyncConflict], context: ModelContext) async {
        for conflict in conflicts {
            // Default strategy: Server wins
            // In production, you might want to present these to the user
            print("Conflict detected: \(conflict.entityType) \(conflict.entityId)")
        }
    }

    // MARK: - Helpers
    private func mapEventType(_ typeString: String) -> FeedEvent.EventType {
        FeedEvent.EventType(rawValue: typeString) ?? .systemAlert
    }

    // MARK: - Offline Queue
    func queueOfflineAction(_ action: OfflineAction) {
        var queue = loadOfflineQueue()
        queue.append(action)
        saveOfflineQueue(queue)
        pendingChangesCount = queue.count
    }

    private func loadOfflineQueue() -> [OfflineAction] {
        guard let data = UserDefaults.standard.data(forKey: "offlineQueue"),
              let queue = try? JSONDecoder().decode([OfflineAction].self, from: data) else {
            return []
        }
        return queue
    }

    private func saveOfflineQueue(_ queue: [OfflineAction]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: "offlineQueue")
        }
    }

    func processOfflineQueue() async {
        var queue = loadOfflineQueue()
        var processedIndices: [Int] = []

        for (index, action) in queue.enumerated() {
            do {
                try await processAction(action)
                processedIndices.append(index)
            } catch {
                // Keep failed actions in queue for retry
                print("Failed to process offline action: \(error)")
            }
        }

        // Remove processed actions
        for index in processedIndices.reversed() {
            queue.remove(at: index)
        }

        saveOfflineQueue(queue)
        pendingChangesCount = queue.count
    }

    private func processAction(_ action: OfflineAction) async throws {
        switch action.type {
        case .createExpense:
            if let expense = action.payload as? ExpenseDTO {
                _ = try await APIService.shared.syncLocalChanges(
                    SyncPayload(expenses: [expense], lastSyncTimestamp: Date())
                )
            }
        case .updateMaintenanceStatus:
            if let update = action.payload as? MaintenanceStatusUpdate {
                _ = try await APIService.shared.updateMaintenanceStatus(
                    id: update.id,
                    status: update.status
                )
            }
        case .recordPayment:
            if let payment = action.payload as? RentPaymentDTO {
                _ = try await APIService.shared.recordPayment(payment)
            }
        }
    }
}

// MARK: - Supporting Types
struct LocalChanges {
    var expenses: [ExpenseDTO]?
    var maintenanceUpdates: [MaintenanceRequestDTO]?

    var isEmpty: Bool {
        (expenses?.isEmpty ?? true) && (maintenanceUpdates?.isEmpty ?? true)
    }
}

struct OfflineAction: Codable {
    let id: UUID
    let type: ActionType
    let payload: Codable
    let createdAt: Date

    enum ActionType: String, Codable {
        case createExpense
        case updateMaintenanceStatus
        case recordPayment
    }

    enum CodingKeys: String, CodingKey {
        case id, type, payloadData, createdAt
    }

    init(type: ActionType, payload: Codable) {
        self.id = UUID()
        self.type = type
        self.payload = payload
        self.createdAt = Date()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(ActionType.self, forKey: .type)
        createdAt = try container.decode(Date.self, forKey: .createdAt)

        let payloadData = try container.decode(Data.self, forKey: .payloadData)

        switch type {
        case .createExpense:
            payload = try JSONDecoder().decode(ExpenseDTO.self, from: payloadData)
        case .updateMaintenanceStatus:
            payload = try JSONDecoder().decode(MaintenanceStatusUpdate.self, from: payloadData)
        case .recordPayment:
            payload = try JSONDecoder().decode(RentPaymentDTO.self, from: payloadData)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(createdAt, forKey: .createdAt)

        let payloadData = try JSONEncoder().encode(payload)
        try container.encode(payloadData, forKey: .payloadData)
    }
}

struct MaintenanceStatusUpdate: Codable {
    let id: String
    let status: String
}

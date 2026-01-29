import SwiftUI
import SwiftData
import Combine

@main
struct HighlanderHomesApp: App {
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Property.self,
            Tenant.self,
            MaintenanceRequest.self,
            Contractor.self,
            Expense.self,
            RentPayment.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .feed
    @Published var showingQuickEntry: Bool = false
    @Published var notificationBadgeCount: Int = 3

    enum Tab: Int, CaseIterable {
        case feed
        case triage
        case dashboard
        case vault

        var title: String {
            switch self {
            case .feed: return "Feed"
            case .triage: return "Triage"
            case .dashboard: return "Command"
            case .vault: return "Vault"
            }
        }

        var icon: String {
            switch self {
            case .feed: return "rectangle.stack.fill"
            case .triage: return "wrench.and.screwdriver.fill"
            case .dashboard: return "chart.bar.fill"
            case .vault: return "building.2.fill"
            }
        }
    }
}

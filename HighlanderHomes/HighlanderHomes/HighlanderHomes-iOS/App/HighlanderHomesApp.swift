import SwiftUI
import SwiftData
import Combine

@main
struct HighlanderHomesApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var convexAuth = ConvexAuth.shared
    @StateObject private var dataService = ConvexDataService.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Property.self,
            Tenant.self,
            MaintenanceRequest.self,
            Contractor.self,
            Expense.self,
            RentPayment.self,
            FeedEvent.self
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
            RootView()
                .environmentObject(appState)
                .environmentObject(convexAuth)
                .environmentObject(dataService)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Configure DataService with model context for local caching
                    dataService.configure(with: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Root View (handles auth state)
struct RootView: View {
    @EnvironmentObject var convexAuth: ConvexAuth
    @EnvironmentObject var dataService: ConvexDataService

    var body: some View {
        Group {
            if convexAuth.isLoading {
                // Splash Screen
                SplashView()
            } else if convexAuth.isAuthenticated {
                // Main App
                ContentView()
                    .onAppear {
                        // Sync data when user logs in
                        Task {
                            await dataService.syncAllData()
                        }
                    }
            } else {
                // Auth Screen
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: convexAuth.isAuthenticated)
    }
}

// MARK: - Splash View
struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    // Animated rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Theme.Colors.emerald.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                            .frame(width: CGFloat(120 + i * 40), height: CGFloat(120 + i * 40))
                            .scaleEffect(scale)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                                value: scale
                            )
                    }

                    // Logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Theme.Gradients.emeraldGlow)
                            .frame(width: 100, height: 100)
                            .shadow(color: Theme.Colors.emerald.opacity(0.5), radius: 20, y: 8)

                        Image(systemName: "building.2.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }
                }

                Text("Highlander Homes")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .opacity(opacity)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.emerald))
                    .scaleEffect(1.2)
                    .opacity(opacity)
            }
        }
        .onAppear {
            scale = 1.1
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
            }
        }
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .transactions
    @Published var showingQuickEntry: Bool = false
    @Published var isModalPresented: Bool = false
    @Published var notificationBadgeCount: Int = 3

    enum Tab: Int, CaseIterable {
        case transactions
        case feed
        case triage
        case dashboard
        case vault

        var title: String {
            switch self {
            case .transactions: return "Transactions"
            case .feed: return "Feed"
            case .triage: return "Triage"
            case .dashboard: return "Command"
            case .vault: return "Vault"
            }
        }

        var icon: String {
            switch self {
            case .transactions: return "dollarsign.circle.fill"
            case .feed: return "rectangle.stack.fill"
            case .triage: return "wrench.and.screwdriver.fill"
            case .dashboard: return "chart.bar.fill"
            case .vault: return "building.2.fill"
            }
        }
    }
}

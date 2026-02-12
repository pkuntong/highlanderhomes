import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Namespace private var tabAnimation

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content — swipeable TabView (page style) with custom tab bar
            TabView(selection: $appState.selectedTab) {
                DashboardView()
                    .tag(AppState.Tab.dashboard)

                PropertiesListView()
                    .tag(AppState.Tab.properties)

                MaintenanceListView()
                    .tag(AppState.Tab.maintenance)

                FinancesView()
                    .tag(AppState.Tab.finances)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            if !appState.isModalPresented {
                CustomTabBar(selectedTab: $appState.selectedTab, namespace: tabAnimation)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: AppState.Tab
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: namespace
                ) {
                    HapticManager.shared.impact(.medium)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.Colors.slate700, lineWidth: 1)
                }
        }
    }
}

struct TabBarButton: View {
    let tab: AppState.Tab
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .symbolEffect(.bounce, value: isSelected)

                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? Theme.Colors.emerald : Theme.Colors.slate400)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.emerald.opacity(0.15))
                        .matchedGeometryEffect(id: "tab_highlight", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tab.title) tab")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(ConvexDataService.shared)
        .environmentObject(ConvexAuth.shared)
}

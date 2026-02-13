import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Namespace private var tabAnimation
    private let swipeThreshold: CGFloat = 120
    @State private var swipeStartTab: AppState.Tab?

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
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
            .animation(.easeInOut(duration: 0.22), value: appState.selectedTab)

            // Custom Tab Bar
            if !appState.isModalPresented {
                CustomTabBar(selectedTab: $appState.selectedTab, namespace: tabAnimation)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { _ in
                    if swipeStartTab == nil {
                        swipeStartTab = appState.selectedTab
                    }
                }
                .onEnded { value in
                    let startedTab = swipeStartTab ?? appState.selectedTab
                    swipeStartTab = nil

                    // If TabView already paged successfully, don't step again.
                    guard appState.selectedTab == startedTab else { return }
                    guard abs(value.translation.width) > abs(value.translation.height) * 1.15 else { return }
                    if value.translation.width <= -swipeThreshold {
                        switchTab(forward: true)
                    } else if value.translation.width >= swipeThreshold {
                        switchTab(forward: false)
                    }
                }
        )
        .ignoresSafeArea(.keyboard)
    }

    private func switchTab(forward: Bool) {
        let allTabs = AppState.Tab.allCases
        guard let currentIndex = allTabs.firstIndex(of: appState.selectedTab) else { return }

        let targetIndex: Int
        if forward {
            targetIndex = min(currentIndex + 1, allTabs.count - 1)
        } else {
            targetIndex = max(currentIndex - 1, 0)
        }

        guard targetIndex != currentIndex else { return }
        HapticManager.shared.selection()
        withAnimation(.easeInOut(duration: 0.22)) {
            appState.selectedTab = allTabs[targetIndex]
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: AppState.Tab
    var namespace: Namespace.ID
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: namespace
                ) {
                    HapticManager.shared.impact(.medium)
                    if selectedTab == tab {
                        // Re-tap current tab to return to root list/navigation.
                        if tab == .properties {
                            appState.propertiesTabResetTrigger += 1
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Theme.Colors.surface.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.Colors.slate700, lineWidth: 1)
                }
                .shadow(color: Theme.Colors.slate400.opacity(0.18), radius: 8, x: 0, y: 4)
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

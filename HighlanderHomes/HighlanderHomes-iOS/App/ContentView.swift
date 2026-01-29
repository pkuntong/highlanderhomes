import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var tabBarOffset: CGFloat = 0
    @Namespace private var tabAnimation

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            TabView(selection: $appState.selectedTab) {
                MaintenanceFeedView()
                    .tag(AppState.Tab.feed)

                TriageHubView()
                    .tag(AppState.Tab.triage)

                CommandCenterView()
                    .tag(AppState.Tab.dashboard)

                PropertyVaultView()
                    .tag(AppState.Tab.vault)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            CustomTabBar(selectedTab: $appState.selectedTab, namespace: tabAnimation)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard)
        .overlay(alignment: .bottomTrailing) {
            // Quick Entry FAB
            QuickEntryFAB()
                .padding(.trailing, 20)
                .padding(.bottom, 100)
        }
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
    }
}

// MARK: - Quick Entry FAB
struct QuickEntryFAB: View {
    @EnvironmentObject var appState: AppState
    @State private var isPressed = false
    @State private var rotation: Double = 0

    var body: some View {
        Button {
            HapticManager.shared.impact(.heavy)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                appState.showingQuickEntry.toggle()
                rotation += 45
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.Gradients.emeraldGlow)
                    .frame(width: 56, height: 56)
                    .shadow(color: Theme.Colors.emerald.opacity(0.5), radius: 12, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotation))
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
        .sheet(isPresented: $appState.showingQuickEntry) {
            QuickEntryView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

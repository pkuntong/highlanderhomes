import SwiftUI
import SwiftData

struct MaintenanceFeedView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showingFilters = false

    private var events: [ConvexFeedEvent] {
        dataService.feedEvents
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    FeedHeader(showingFilters: $showingFilters)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.sm)

                    // Loading indicator
                    if dataService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.emerald))
                            .padding()
                    }

                    // Feed Content
                    if events.isEmpty && !dataService.isLoading {
                        EmptyFeedView()
                    } else if !events.isEmpty {
                        TabView(selection: $currentIndex) {
                            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                                ConvexFeedEventCard(event: event, geometry: geometry)
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
                    }

                    // Page Indicator
                    if !events.isEmpty {
                        FeedPageIndicator(
                            currentIndex: currentIndex,
                            totalCount: events.count
                        )
                        .padding(.bottom, Theme.Spacing.lg)
                    }
                }
            }
        }
        .refreshable {
            await dataService.loadAllData()
        }
    }
}

// MARK: - Feed Header
struct FeedHeader: View {
    @EnvironmentObject var convexAuth: ConvexAuth
    @Binding var showingFilters: Bool
    @State private var notificationCount = 3
    @State private var showingProfile = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("Your property feed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            HStack(spacing: 12) {
                // Filter Button
                Button {
                    HapticManager.shared.impact(.light)
                    showingFilters.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.slate400)
                }

                // Profile/Settings Button
                Button {
                    HapticManager.shared.impact(.light)
                    showingProfile = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.emerald.opacity(0.2))
                            .frame(width: 36, height: 36)

                        if let user = convexAuth.currentUser {
                            Text(user.initials)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.Colors.emerald)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.emerald)
                        }
                    }
                }
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .sheet(isPresented: $showingProfile) {
            ProfileSheet()
        }
    }
}

// MARK: - Convex Feed Event Card
struct ConvexFeedEventCard: View {
    let event: ConvexFeedEvent
    let geometry: GeometryProxy
    @State private var isPressed = false
    @State private var showActions = false
    @State private var pulseAnimation = false

    private var cardHeight: CGFloat {
        geometry.size.height * 0.75
    }

    private var isUrgent: Bool {
        event.priority >= 3
    }

    private var isHighPriority: Bool {
        event.priority >= 2
    }

    private var eventCategory: String {
        if event.type.contains("maintenance") { return "maintenance" }
        if event.type.contains("rent") || event.type.contains("payment") { return "financial" }
        if event.type.contains("contractor") { return "contractor" }
        if event.type.contains("tenant") { return "tenant" }
        return "general"
    }

    private var categoryIcon: String {
        switch eventCategory {
        case "maintenance": return "wrench.fill"
        case "financial": return "dollarsign.circle.fill"
        case "contractor": return "person.badge.key.fill"
        case "tenant": return "person.fill"
        default: return "bell.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Card Background
                RoundedRectangle(cornerRadius: Theme.Radius.extraLarge)
                    .fill(cardBackgroundGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.extraLarge)
                            .stroke(borderColor, lineWidth: event.isActionRequired ? 2 : 1)
                    }
                    .shadow(color: shadowColor, radius: 20, y: 10)

                // Pulse overlay for urgent items
                if isUrgent {
                    RoundedRectangle(cornerRadius: Theme.Radius.extraLarge)
                        .stroke(Theme.Colors.alertRed, lineWidth: 3)
                        .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.8)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }

                // Card Content
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Top Row: Icon + Category
                    HStack {
                        ConvexEventIconView(category: eventCategory, icon: categoryIcon)

                        Spacer()

                        if isHighPriority {
                            ConvexPriorityBadge(priority: event.priority)
                        }
                    }

                    Spacer()

                    // Main Content
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(event.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .lineLimit(2)

                        Text(event.subtitle)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineLimit(2)

                        if let detail = event.detail {
                            Text(detail)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Theme.Colors.textMuted)
                                .lineLimit(3)
                                .padding(.top, Theme.Spacing.xs)
                        }
                    }

                    Spacer()

                    // Bottom Row: Timestamp + Actions
                    HStack {
                        // Timestamp
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(event.timeAgo)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Theme.Colors.textMuted)

                        Spacer()

                        // Action Button
                        if event.isActionRequired, let actionLabel = event.actionLabel {
                            ActionButton(label: actionLabel) {
                                performAction()
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.xl)
            }
            .frame(height: cardHeight)
            .padding(.horizontal, Theme.Spacing.md)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.shared.impact(.light)
            showActions.toggle()
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            HapticManager.shared.impact(.medium)
        })
        .onAppear {
            if isUrgent {
                pulseAnimation = true
                HapticManager.shared.urgentPulse()
            }
        }
    }

    private var cardBackgroundGradient: LinearGradient {
        switch eventCategory {
        case "financial":
            return LinearGradient(
                colors: [Theme.Colors.goldMuted.opacity(0.3), Theme.Colors.slate900],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "maintenance":
            return LinearGradient(
                colors: [Theme.Colors.alertRedMuted.opacity(0.3), Theme.Colors.slate900],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return Theme.Gradients.cardGradient
        }
    }

    private var borderColor: Color {
        if isUrgent {
            return Theme.Colors.alertRed
        } else if eventCategory == "financial" {
            return Theme.Colors.gold.opacity(0.5)
        } else {
            return Theme.Colors.slate700.opacity(0.5)
        }
    }

    private var shadowColor: Color {
        switch eventCategory {
        case "financial":
            return Theme.Colors.gold.opacity(0.2)
        case "maintenance":
            return Theme.Colors.alertRed.opacity(0.2)
        default:
            return Color.black.opacity(0.3)
        }
    }

    private func performAction() {
        HapticManager.shared.reward()
        // Action logic here
    }
}

// MARK: - Convex Event Icon View
struct ConvexEventIconView: View {
    let category: String
    let icon: String
    @State private var bounceAnimation = false

    var body: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 56, height: 56)

            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(iconColor)
                .symbolEffect(.bounce, value: bounceAnimation)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bounceAnimation = true
            }
        }
    }

    private var iconBackgroundColor: Color {
        switch category {
        case "maintenance": return Theme.Colors.alertRed.opacity(0.2)
        case "financial": return Theme.Colors.gold.opacity(0.2)
        case "contractor": return Theme.Colors.infoBlue.opacity(0.2)
        case "tenant": return Theme.Colors.emerald.opacity(0.2)
        default: return Theme.Colors.slate600.opacity(0.2)
        }
    }

    private var iconColor: Color {
        switch category {
        case "maintenance": return Theme.Colors.alertRed
        case "financial": return Theme.Colors.gold
        case "contractor": return Theme.Colors.infoBlue
        case "tenant": return Theme.Colors.emerald
        default: return Theme.Colors.slate400
        }
    }
}

// MARK: - Convex Priority Badge
struct ConvexPriorityBadge: View {
    let priority: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority >= 3 ? "exclamationmark.triangle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 12))
            Text(priority >= 3 ? "URGENT" : "HIGH")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(priority >= 3 ? Theme.Colors.alertRed : Theme.Colors.warningAmber)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill((priority >= 3 ? Theme.Colors.alertRed : Theme.Colors.warningAmber).opacity(0.2))
        }
    }
}


// MARK: - Action Button
struct ActionButton: View {
    let label: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(Theme.Gradients.emeraldGlow)
            }
            .shadow(color: Theme.Colors.emerald.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.haptic(.medium))
    }
}

// MARK: - Page Indicator
struct FeedPageIndicator: View {
    let currentIndex: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<min(totalCount, 6), id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Theme.Colors.emerald : Theme.Colors.slate600)
                    .frame(width: index == currentIndex ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentIndex)
            }

            if totalCount > 6 {
                Text("+\(totalCount - 6)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.Colors.slate500)
            }
        }
    }
}

// MARK: - Empty Feed View
struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "tray.fill")
                .font(.system(size: 64))
                .foregroundColor(Theme.Colors.slate600)

            Text("All Caught Up!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)

            Text("No new activity to show.\nEnjoy the quiet moment.")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Profile Sheet
struct ProfileSheet: View {
    @EnvironmentObject var convexAuth: ConvexAuth
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xl) {
                    // Profile Avatar
                    ZStack {
                        Circle()
                            .fill(Theme.Gradients.emeraldGlow)
                            .frame(width: 100, height: 100)

                        if let user = convexAuth.currentUser {
                            Text(user.initials)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, Theme.Spacing.xl)

                    // User Info
                    if let user = convexAuth.currentUser {
                        VStack(spacing: Theme.Spacing.xs) {
                            Text(user.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text(user.email)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.textSecondary)

                            if user.isPremium {
                                Text("Premium Member")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.Colors.gold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background {
                                        Capsule()
                                            .fill(Theme.Colors.gold.opacity(0.15))
                                    }
                                    .padding(.top, Theme.Spacing.xs)
                            }
                        }
                    }

                    Spacer()

                    // Sign Out Button
                    Button {
                        HapticManager.shared.impact(.medium)
                        convexAuth.signOut()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .fill(Theme.Colors.alertRed)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
    }
}

#Preview {
    MaintenanceFeedView()
        .environmentObject(ConvexDataService.shared)
        .environmentObject(ConvexAuth.shared)
}

import SwiftUI
import SwiftData

struct MaintenanceFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FeedEvent.timestamp, order: .reverse) private var events: [FeedEvent]
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showingFilters = false

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

                    // Feed Content
                    if events.isEmpty {
                        EmptyFeedView()
                    } else {
                        TabView(selection: $currentIndex) {
                            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                                FeedEventCard(event: event, geometry: geometry)
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
        .onAppear {
            loadSampleDataIfNeeded()
        }
    }

    private func loadSampleDataIfNeeded() {
        if events.isEmpty {
            for event in FeedEvent.sampleEvents() {
                modelContext.insert(event)
            }
        }
    }
}

// MARK: - Feed Header
struct FeedHeader: View {
    @Binding var showingFilters: Bool
    @State private var notificationCount = 3

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

                // Notification Bell
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.Colors.slate400)

                    if notificationCount > 0 {
                        Text("\(notificationCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Theme.Colors.alertRed)
                            .clipShape(Circle())
                            .offset(x: 8, y: -6)
                    }
                }
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Feed Event Card
struct FeedEventCard: View {
    let event: FeedEvent
    let geometry: GeometryProxy
    @State private var isPressed = false
    @State private var showActions = false
    @State private var pulseAnimation = false

    private var cardHeight: CGFloat {
        geometry.size.height * 0.75
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
                if event.priority == .urgent {
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
                        EventIconView(event: event)

                        Spacer()

                        PriorityBadge(priority: event.priority)
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
            if event.priority == .urgent {
                pulseAnimation = true
                HapticManager.shared.urgentPulse()
            }
        }
    }

    private var cardBackgroundGradient: LinearGradient {
        switch event.eventType.category {
        case .financial:
            return LinearGradient(
                colors: [Theme.Colors.goldMuted.opacity(0.3), Theme.Colors.slate900],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .maintenance:
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
        if event.priority == .urgent {
            return Theme.Colors.alertRed
        } else if event.eventType.category == .financial {
            return Theme.Colors.gold.opacity(0.5)
        } else {
            return Theme.Colors.slate700.opacity(0.5)
        }
    }

    private var shadowColor: Color {
        switch event.eventType.category {
        case .financial:
            return Theme.Colors.gold.opacity(0.2)
        case .maintenance:
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

// MARK: - Event Icon View
struct EventIconView: View {
    let event: FeedEvent
    @State private var bounceAnimation = false

    var body: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 56, height: 56)

            Image(systemName: event.eventType.icon)
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
        switch event.eventType.category {
        case .maintenance:
            return Theme.Colors.alertRed.opacity(0.2)
        case .financial:
            return Theme.Colors.gold.opacity(0.2)
        case .contractor:
            return Theme.Colors.infoBlue.opacity(0.2)
        case .tenant:
            return Theme.Colors.emerald.opacity(0.2)
        case .general:
            return Theme.Colors.slate600.opacity(0.2)
        }
    }

    private var iconColor: Color {
        switch event.eventType.category {
        case .maintenance:
            return Theme.Colors.alertRed
        case .financial:
            return Theme.Colors.gold
        case .contractor:
            return Theme.Colors.infoBlue
        case .tenant:
            return Theme.Colors.emerald
        case .general:
            return Theme.Colors.slate400
        }
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: FeedEvent.Priority

    var body: some View {
        if priority >= .high {
            HStack(spacing: 4) {
                Image(systemName: priority == .urgent ? "exclamationmark.triangle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 12))
                Text(priority == .urgent ? "URGENT" : "HIGH")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(priority == .urgent ? Theme.Colors.alertRed : Theme.Colors.warningAmber)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill((priority == .urgent ? Theme.Colors.alertRed : Theme.Colors.warningAmber).opacity(0.2))
            }
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

#Preview {
    MaintenanceFeedView()
        .modelContainer(for: FeedEvent.self, inMemory: true)
}

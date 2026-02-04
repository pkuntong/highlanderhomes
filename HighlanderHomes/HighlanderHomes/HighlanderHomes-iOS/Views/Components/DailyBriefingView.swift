import SwiftUI

/// AI-powered daily briefing that gives you the "State of the Portfolio"
/// This is a premium feature that makes users feel like they have a personal assistant
struct DailyBriefingView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    @State private var showFullBriefing = false
    @State private var animateGradient = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Late night grind"
        }
    }

    private var briefingItems: [BriefingItem] {
        var items: [BriefingItem] = []

        // Revenue insight
        let revenue = dataService.totalMonthlyRevenue
        items.append(BriefingItem(
            icon: "dollarsign.circle.fill",
            color: Theme.Colors.gold,
            title: "Portfolio Revenue",
            value: "$\(Int(revenue).formatted())/mo",
            detail: revenue > 10000 ? "Strong cash flow this month" : "Room to grow",
            trend: .up
        ))

        // Occupancy
        let occupancy = Int(dataService.occupancyRate * 100)
        items.append(BriefingItem(
            icon: "person.2.fill",
            color: Theme.Colors.emerald,
            title: "Occupancy Rate",
            value: "\(occupancy)%",
            detail: occupancy >= 90 ? "Excellent occupancy!" : "Consider marketing vacant units",
            trend: occupancy >= 90 ? .up : .neutral
        ))

        // Urgent maintenance
        let urgentCount = dataService.urgentMaintenanceCount
        if urgentCount > 0 {
            items.append(BriefingItem(
                icon: "exclamationmark.triangle.fill",
                color: Theme.Colors.alertRed,
                title: "Urgent Attention",
                value: "\(urgentCount) issue\(urgentCount > 1 ? "s" : "")",
                detail: "Requires immediate action",
                trend: .down
            ))
        }

        // Health score
        let health = dataService.portfolioHealthScore
        items.append(BriefingItem(
            icon: "heart.fill",
            color: health >= 80 ? Theme.Colors.emerald : Theme.Colors.warningAmber,
            title: "Portfolio Health",
            value: "\(health)/100",
            detail: health >= 80 ? "Your properties are thriving" : "Some areas need attention",
            trend: health >= 80 ? .up : .neutral
        ))

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header (always visible)
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.impact(.light)
            } label: {
                HStack(spacing: 12) {
                    // AI Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.emerald, Theme.Colors.infoBlue],
                                    startPoint: animateGradient ? .topLeading : .bottomTrailing,
                                    endPoint: animateGradient ? .bottomTrailing : .topLeading
                                )
                            )
                            .frame(width: 44, height: 44)

                        Image(systemName: "sparkles")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(greeting)!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text(summaryText)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textMuted)
                }
                .padding(Theme.Spacing.md)
            }
            .buttonStyle(.plain)

            // Expanded briefing content
            if isExpanded {
                VStack(spacing: Theme.Spacing.sm) {
                    Divider()
                        .background(Theme.Colors.slate700)

                    ForEach(briefingItems, id: \.title) { item in
                        BriefingItemRow(item: item)
                    }

                    // See full briefing button
                    Button {
                        showFullBriefing = true
                        HapticManager.shared.impact(.medium)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("View Full Analysis")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.emerald)
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Colors.slate800.opacity(0.7))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.Colors.emerald.opacity(0.5), Theme.Colors.infoBlue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
        .sheet(isPresented: $showFullBriefing) {
            FullBriefingSheet(items: briefingItems)
        }
        .onChange(of: showFullBriefing) { newValue in
            appState.isModalPresented = newValue
        }
    }

    private var summaryText: String {
        let urgentCount = dataService.urgentMaintenanceCount
        let health = dataService.portfolioHealthScore

        if urgentCount > 0 {
            return "\(urgentCount) urgent matter\(urgentCount > 1 ? "s" : "") need attention"
        } else if health >= 90 {
            return "Everything's running smoothly today"
        } else if health >= 70 {
            return "A few items to review when you have time"
        } else {
            return "Your portfolio needs some attention"
        }
    }
}

// MARK: - Briefing Item Model
struct BriefingItem {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let detail: String
    let trend: Trend

    enum Trend {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return Theme.Colors.emerald
            case .down: return Theme.Colors.alertRed
            case .neutral: return Theme.Colors.slate400
            }
        }
    }
}

// MARK: - Briefing Item Row
struct BriefingItemRow: View {
    let item: BriefingItem
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 18))
                .foregroundColor(item.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textSecondary)

                HStack(spacing: 6) {
                    Text(item.value)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Image(systemName: item.trend.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(item.trend.color)
                }
            }

            Spacer()

            Text(item.detail)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textMuted)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Full Briefing Sheet
struct FullBriefingSheet: View {
    let items: [BriefingItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // AI Header
                        VStack(spacing: Theme.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Gradients.emeraldGlow)
                                    .frame(width: 80, height: 80)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }

                            Text("Your Daily Briefing")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text(Date(), style: .date)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding(.top, Theme.Spacing.lg)

                        // Detailed Cards
                        ForEach(items, id: \.title) { item in
                            DetailedBriefingCard(item: item)
                        }

                        // AI Recommendations
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(Theme.Colors.gold)
                                Text("Recommendations")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }

                            RecommendationRow(
                                icon: "clock.badge.checkmark",
                                text: "Schedule preventive HVAC maintenance before summer",
                                priority: .medium
                            )

                            RecommendationRow(
                                icon: "person.badge.plus",
                                text: "Review lease renewals expiring in 30 days",
                                priority: .high
                            )

                            RecommendationRow(
                                icon: "chart.line.uptrend.xyaxis",
                                text: "Market rates increased 3% - consider rent adjustment",
                                priority: .low
                            )
                        }
                        .padding(Theme.Spacing.lg)
                        .cardStyle()
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
    }
}

struct DetailedBriefingCard: View {
    let item: BriefingItem

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: item.icon)
                    .font(.system(size: 24))
                    .foregroundColor(item.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(item.value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(item.detail)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textMuted)
            }

            Spacer()

            Image(systemName: item.trend.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(item.trend.color)
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }
}

struct RecommendationRow: View {
    let icon: String
    let text: String
    let priority: Priority

    enum Priority {
        case high, medium, low

        var color: Color {
            switch self {
            case .high: return Theme.Colors.alertRed
            case .medium: return Theme.Colors.warningAmber
            case .low: return Theme.Colors.infoBlue
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(priority.color)
                .frame(width: 8, height: 8)

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textSecondary)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        VStack {
            DailyBriefingView()
                .padding()

            Spacer()
        }
    }
    .environmentObject(ConvexDataService.shared)
}

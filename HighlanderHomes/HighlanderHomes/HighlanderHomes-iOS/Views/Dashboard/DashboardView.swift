import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @EnvironmentObject var convexAuth: ConvexAuth
    @EnvironmentObject var appState: AppState

    @State private var showingSettings = false
    @State private var selectedTimeRange: TimeRange = .month

    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case quarter = "90D"
        case year = "1Y"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Portfolio Health
                        PortfolioHealthCard(
                            score: dataService.portfolioHealthScore,
                            propertiesCount: dataService.properties.count,
                            occupancyRate: dataService.occupancyRate,
                            pendingMaintenance: dataService.pendingMaintenanceCount
                        )

                        // Key Metrics
                        KeyMetricsRow(
                            totalRevenue: dataService.totalMonthlyRevenue,
                            occupancyRate: dataService.occupancyRate,
                            pendingMaintenance: dataService.pendingMaintenanceCount,
                            onTapRevenue: { appState.selectedTab = .finances },
                            onTapOccupancy: { appState.selectedTab = .properties },
                            onTapPending: { appState.selectedTab = .maintenance }
                        )

                        // Quick Actions
                        QuickActionsRow()

                        // Revenue Chart
                        RevenueChartCard(
                            rentPayments: dataService.rentPayments,
                            expenses: dataService.expenses,
                            timeRange: $selectedTimeRange
                        )

                        // Recent Activity
                        RecentActivitySection(events: dataService.feedEvents)
                    }
                    .padding(Theme.Spacing.md)
                    .padding(.bottom, 100)
                }

                if dataService.isLoading {
                    VStack {
                        DashboardRefreshBanner()
                            .padding(.top, 8)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: dataService.isLoading)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 10) {
                        Menu {
                            Button(dataService.isLoading ? "Refreshing..." : "Refresh Data") {
                                HapticManager.shared.impact(.light)
                                Task { await dataService.loadAllData() }
                            }
                            .disabled(dataService.isLoading)
                            Button("Settings") {
                                showingSettings = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .accessibilityLabel("Dashboard menu")

                        Text("Dashboard")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.impact(.light)
                        showingSettings = true
                    } label: {
                        ProfileAvatarButton()
                    }
                }
            }
        }
        .refreshable {
            await dataService.loadAllData()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onChange(of: showingSettings) { newValue in
            appState.isModalPresented = newValue
        }
    }
}

// MARK: - Profile Avatar Button (reused across screens)
struct ProfileAvatarButton: View {
    @EnvironmentObject var convexAuth: ConvexAuth

    var body: some View {
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
        .accessibilityLabel("Settings")
    }
}

struct DashboardRefreshBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(Theme.Colors.textPrimary)

            Text("Refreshing data...")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Colors.slate900.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.Colors.slate700.opacity(0.7), lineWidth: 1)
                }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .accessibilityLabel("Refreshing data")
    }
}

// MARK: - Quick Actions Row
struct QuickActionsRow: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)

            HStack(spacing: Theme.Spacing.md) {
                QuickActionCard(
                    icon: "dollarsign.circle.fill",
                    label: "Log Payment",
                    color: Theme.Colors.emerald
                ) {
                    appState.selectedTab = .finances
                }

                QuickActionCard(
                    icon: "wrench.and.screwdriver.fill",
                    label: "New Request",
                    color: Theme.Colors.warningAmber
                ) {
                    appState.selectedTab = .maintenance
                }

                QuickActionCard(
                    icon: "building.2.fill",
                    label: "Add Property",
                    color: Theme.Colors.infoBlue
                ) {
                    appState.selectedTab = .properties
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .fill(Theme.Colors.slate800.opacity(0.5))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.medium)
                            .stroke(Theme.Colors.slate700.opacity(0.5), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Revenue Chart Card (Real Data)
struct RevenueChartCard: View {
    let rentPayments: [ConvexRentPayment]
    let expenses: [ConvexExpense]
    @Binding var timeRange: DashboardView.TimeRange

    private var orderedRanges: [DashboardView.TimeRange] {
        DashboardView.TimeRange.allCases
    }

    private var chartData: [MonthlyFinancial] {
        let calendar = Calendar.current
        let now = Date()
        var data: [MonthlyFinancial] = []

        let dayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            return formatter
        }()

        let weekdayFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return formatter
        }()

        let monthFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter
        }()

        let weekFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter
        }()

        func incomeBetween(start: Date, end: Date) -> Double {
            let startMs = start.timeIntervalSince1970 * 1000
            let endMs = end.timeIntervalSince1970 * 1000
            return rentPayments
                .filter { $0.paymentDate >= startMs && $0.paymentDate < endMs && $0.status == "completed" }
                .reduce(0.0) { $0 + $1.amount }
        }

        func expenseBetween(start: Date, end: Date) -> Double {
            let startMs = start.timeIntervalSince1970 * 1000
            let endMs = end.timeIntervalSince1970 * 1000
            return expenses
                .filter { $0.date >= startMs && $0.date < endMs }
                .reduce(0.0) { $0 + $1.amount }
        }

        switch timeRange {
        case .week:
            for i in stride(from: 6, through: 0, by: -1) {
                guard let day = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
                let dayStart = calendar.startOfDay(for: day)
                guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
                data.append(MonthlyFinancial(
                    month: weekdayFormatter.string(from: dayStart),
                    income: incomeBetween(start: dayStart, end: dayEnd),
                    expenses: expenseBetween(start: dayStart, end: dayEnd),
                    date: dayStart
                ))
            }
        case .month:
            for i in stride(from: 29, through: 0, by: -1) {
                guard let day = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
                let dayStart = calendar.startOfDay(for: day)
                guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
                data.append(MonthlyFinancial(
                    month: dayFormatter.string(from: dayStart),
                    income: incomeBetween(start: dayStart, end: dayEnd),
                    expenses: expenseBetween(start: dayStart, end: dayEnd),
                    date: dayStart
                ))
            }
        case .quarter:
            for i in stride(from: 12, through: 0, by: -1) {
                guard let weekDate = calendar.date(byAdding: .weekOfYear, value: -i, to: now) else { continue }
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekDate)?.start ?? calendar.startOfDay(for: weekDate)
                guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { continue }
                data.append(MonthlyFinancial(
                    month: weekFormatter.string(from: startOfWeek),
                    income: incomeBetween(start: startOfWeek, end: weekEnd),
                    expenses: expenseBetween(start: startOfWeek, end: weekEnd),
                    date: startOfWeek
                ))
            }
        case .year:
            for i in stride(from: 11, through: 0, by: -1) {
                guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
                let components = calendar.dateComponents([.year, .month], from: monthDate)
                guard let monthStart = calendar.date(from: components),
                      let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
                data.append(MonthlyFinancial(
                    month: monthFormatter.string(from: monthStart),
                    income: incomeBetween(start: monthStart, end: monthEnd),
                    expenses: expenseBetween(start: monthStart, end: monthEnd),
                    date: monthStart
                ))
            }
        }

        return data
    }

    private var totalIncome: Double {
        chartData.reduce(0) { $0 + $1.income }
    }

    private var totalExpenses: Double {
        chartData.reduce(0) { $0 + $1.expenses }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Revenue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(Int(totalIncome).formatted())")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.emerald)
                    if totalExpenses > 0 {
                        Text("- $\(Int(totalExpenses).formatted())")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.Colors.alertRed)
                    }
                }
            }

            if chartData.isEmpty || chartData.allSatisfy({ $0.income == 0 && $0.expenses == 0 }) {
                // Empty state
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .fill(Theme.Colors.slate800.opacity(0.5))
                    .frame(height: 180)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.Colors.slate500)
                            Text("No revenue data yet")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)
                            Text("Add rent payments to see trends")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.textMuted)
                        }
                    }
            } else {
                Chart(chartData) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Income", item.income)
                    )
                    .foregroundStyle(Theme.Colors.emerald.gradient)
                    .cornerRadius(4)

                    if item.expenses > 0 {
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Expenses", -item.expenses)
                        )
                        .foregroundStyle(Theme.Colors.alertRed.opacity(0.6).gradient)
                        .cornerRadius(4)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("$\(abs(Int(amount)))")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.Colors.textMuted)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                }
                .frame(height: 180)
            }

            // Time Range Picker
            HStack(spacing: 6) {
                ForEach(DashboardView.TimeRange.allCases, id: \.self) { range in
                    Button {
                        HapticManager.shared.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            timeRange = range
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 12, weight: range == timeRange ? .bold : .medium))
                            .foregroundColor(range == timeRange ? .white : Theme.Colors.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background {
                                if range == timeRange {
                                    Capsule().fill(Theme.Colors.emerald)
                                } else {
                                    Capsule().fill(Color.clear)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background {
                Capsule()
                    .fill(Theme.Colors.slate800)
                    .overlay { Capsule().stroke(Theme.Colors.slate700, lineWidth: 1) }
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width < -24 {
                        stepRange(forward: true)
                    } else if value.translation.width > 24 {
                        stepRange(forward: false)
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Revenue chart showing \(Int(totalIncome)) dollars income")
    }

    private func stepRange(forward: Bool) {
        guard let currentIndex = orderedRanges.firstIndex(of: timeRange) else { return }
        let targetIndex: Int
        if forward {
            targetIndex = min(currentIndex + 1, orderedRanges.count - 1)
        } else {
            targetIndex = max(currentIndex - 1, 0)
        }
        guard targetIndex != currentIndex else { return }
        HapticManager.shared.selection()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            timeRange = orderedRanges[targetIndex]
        }
    }
}

struct MonthlyFinancial: Identifiable {
    let id = UUID()
    let month: String
    let income: Double
    let expenses: Double
    let date: Date
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    let events: [ConvexFeedEvent]

    private var recentEvents: [ConvexFeedEvent] {
        Array(events.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                if events.count > 5 {
                    Text("\(events.count) total")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }

            if recentEvents.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.Colors.slate600)
                        Text("No recent activity")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.vertical, Theme.Spacing.xl)
                    Spacer()
                }
            } else {
                ForEach(recentEvents) { event in
                    ActivityRow(event: event)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }
}

struct ActivityRow: View {
    let event: ConvexFeedEvent
    @EnvironmentObject var appState: AppState

    private var eventIcon: String {
        if event.type.contains("maintenance") { return "wrench.fill" }
        if event.type.contains("rent") || event.type.contains("payment") { return "dollarsign.circle.fill" }
        if event.type.contains("contractor") { return "person.badge.key.fill" }
        if event.type.contains("tenant") { return "person.fill" }
        return "bell.fill"
    }

    private var iconColor: Color {
        if event.type.contains("maintenance") { return Theme.Colors.alertRed }
        if event.type.contains("rent") || event.type.contains("payment") { return Theme.Colors.gold }
        if event.type.contains("contractor") { return Theme.Colors.infoBlue }
        if event.type.contains("tenant") { return Theme.Colors.emerald }
        return Theme.Colors.slate400
    }

    private var targetTab: AppState.Tab {
        if event.type.contains("maintenance") { return .maintenance }
        if event.type.contains("rent") || event.type.contains("payment") || event.type.contains("expense") { return .finances }
        if event.type.contains("contractor") || event.type.contains("tenant") || event.type.contains("property") { return .properties }
        return .dashboard
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: eventIcon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Text(event.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(event.timeAgo)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.textMuted)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.selectedTab = targetTab
            HapticManager.shared.impact(.light)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.title), \(event.subtitle), \(event.timeAgo)")
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
        .environmentObject(ConvexDataService.shared)
        .environmentObject(ConvexAuth.shared)
}

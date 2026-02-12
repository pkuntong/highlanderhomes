import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @EnvironmentObject var convexAuth: ConvexAuth
    @EnvironmentObject var appState: AppState

    @State private var showingSettings = false
    @State private var selectedTimeRange: TimeRange = .month
    @State private var isRefreshingLiveMarket = false
    @State private var marketAlertMessage = ""
    @State private var showingMarketAlert = false

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

                        MarketTrendsDashboardCard(
                            trends: dataService.marketTrends,
                            properties: dataService.properties,
                            isRefreshing: isRefreshingLiveMarket,
                            onRefresh: {
                                Task { await refreshLiveMarket() }
                            }
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
        .alert("Live Market Pull Failed", isPresented: $showingMarketAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(marketAlertMessage)
        }
        .onChange(of: showingSettings) { newValue in
            appState.isModalPresented = newValue
        }
    }

    private func refreshLiveMarket() async {
        guard !isRefreshingLiveMarket else { return }
        isRefreshingLiveMarket = true
        defer { isRefreshingLiveMarket = false }

        do {
            _ = try await dataService.refreshLiveMarketPortfolio()
            HapticManager.shared.success()
        } catch {
            marketAlertMessage = error.localizedDescription
            showingMarketAlert = true
            HapticManager.shared.error()
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

struct MarketTrendsDashboardCard: View {
    let trends: [ConvexMarketTrend]
    let properties: [ConvexProperty]
    let isRefreshing: Bool
    let onRefresh: () -> Void

    @State private var selectedMetric: Metric = .rent
    @State private var selectedPropertyId: String = "all"

    enum Metric: String, CaseIterable {
        case rent = "Rent"
        case value = "Value"

        var icon: String {
            switch self {
            case .rent: return "dollarsign.circle.fill"
            case .value: return "building.columns.fill"
            }
        }

        var color: Color {
            switch self {
            case .rent: return Theme.Colors.emerald
            case .value: return Theme.Colors.infoBlue
            }
        }
    }

    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let averageRent: Double?
        let averageValue: Double?
    }

    struct PropertySnapshot: Identifiable {
        let id: String
        let propertyName: String
        let rent: Double?
        let value: Double?
        let observedDate: Date
    }

    private var selectedPropertyName: String {
        if selectedPropertyId == "all" { return "All Properties" }
        return properties.first(where: { $0.id == selectedPropertyId })?.name ?? "Unknown Property"
    }

    private var filteredTrends: [ConvexMarketTrend] {
        if selectedPropertyId == "all" { return trends }
        return trends.filter { $0.propertyId == selectedPropertyId }
    }

    private var chartPoints: [ChartPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTrends) { calendar.startOfDay(for: $0.observedDate) }

        return grouped.keys.sorted().suffix(24).map { date in
            let rows = grouped[date] ?? []
            let rents = rows.compactMap { $0.estimateRent }
            let values = rows.compactMap { $0.estimatePrice }

            let avgRent = rents.isEmpty ? nil : rents.reduce(0, +) / Double(rents.count)
            let avgValue = values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
            return ChartPoint(date: date, averageRent: avgRent, averageValue: avgValue)
        }
    }

    private var pointsForSelectedMetric: [ChartPoint] {
        chartPoints.filter { point in
            selectedMetric == .rent ? point.averageRent != nil : point.averageValue != nil
        }
    }

    private var latestByProperty: [PropertySnapshot] {
        let grouped = Dictionary(grouping: trends.compactMap { trend -> (String, ConvexMarketTrend)? in
            guard let propertyId = trend.propertyId else { return nil }
            return (propertyId, trend)
        }, by: { $0.0 })

        return grouped.compactMap { propertyId, entries in
            guard let latest = entries.map(\.1).max(by: { $0.observedAt < $1.observedAt }) else { return nil }
            let name = properties.first(where: { $0.id == propertyId })?.name ?? latest.areaLabel
            return PropertySnapshot(
                id: propertyId,
                propertyName: name,
                rent: latest.estimateRent,
                value: latest.estimatePrice,
                observedDate: latest.observedDate
            )
        }
        .sorted { $0.propertyName < $1.propertyName }
    }

    private var latestValueText: String {
        guard let latest = pointsForSelectedMetric.last else { return "—" }
        let value = selectedMetric == .rent ? latest.averageRent : latest.averageValue
        guard let value else { return "—" }
        return ConvexMarketTrend.currencyFormatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private var latestDateText: String {
        guard let latest = pointsForSelectedMetric.last else { return "No snapshots yet" }
        return "Updated \(latest.date.formatted(date: .abbreviated, time: .omitted))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Live Market")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text("\(selectedPropertyName) \u{2022} \(latestDateText)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textMuted)
                }

                Spacer()

                Button(isRefreshing ? "Pulling..." : "Pull Live") {
                    onRefresh()
                }
                .disabled(isRefreshing)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(Theme.Colors.infoBlue.opacity(isRefreshing ? 0.5 : 1))
                }
            }

            HStack(spacing: 8) {
                Image(systemName: selectedMetric.icon)
                    .font(.system(size: 14))
                    .foregroundColor(selectedMetric.color)

                Text(latestValueText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()
            }

            Picker("Metric", selection: $selectedMetric) {
                ForEach(Metric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            Picker("Property", selection: $selectedPropertyId) {
                Text("All Properties").tag("all")
                ForEach(properties, id: \.id) { property in
                    Text(property.name).tag(property.id)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.Colors.emerald)

            if pointsForSelectedMetric.isEmpty {
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .fill(Theme.Colors.slate800.opacity(0.5))
                    .frame(height: 170)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 26))
                                .foregroundColor(Theme.Colors.slate500)
                            Text("No market data yet")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)
                            Text("Use Pull Live to fetch current market snapshots.")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.textMuted)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
            } else {
                Chart(pointsForSelectedMetric) { point in
                    let value = selectedMetric == .rent ? point.averageRent : point.averageValue
                    if let value {
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(selectedMetric.color.opacity(0.18))

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", value)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .foregroundStyle(selectedMetric.color)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(selectedMetric.color)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("$\(Int(amount / 1000))k")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.Colors.textMuted)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.Colors.textMuted)
                            }
                        }
                    }
                }
                .frame(height: 170)
            }

            if selectedPropertyId == "all" && !latestByProperty.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("By Property")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                    ForEach(latestByProperty) { snapshot in
                        HStack(spacing: 8) {
                            Text(snapshot.propertyName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            if let rent = snapshot.rent {
                                Text("Rent \(ConvexMarketTrend.currencyFormatter.string(from: NSNumber(value: rent)) ?? "$\(Int(rent))")")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.emerald)
                            }
                            if let value = snapshot.value {
                                Text("Value \(ConvexMarketTrend.currencyFormatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))")")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.infoBlue)
                            }
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
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

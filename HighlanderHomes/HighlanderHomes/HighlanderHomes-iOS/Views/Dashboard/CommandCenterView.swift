import SwiftUI
import SwiftData
import Charts

struct CommandCenterView: View {
    @EnvironmentObject var dataService: ConvexDataService

    @State private var selectedTimeRange: TimeRange = .month
    @State private var animateCharts = false

    private var properties: [ConvexProperty] {
        dataService.properties
    }

    private var tenants: [ConvexTenant] {
        dataService.tenants
    }

    private var maintenanceRequests: [ConvexMaintenanceRequest] {
        dataService.maintenanceRequests
    }

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
                        // Header
                        CommandHeader()

                        // Loading indicator
                        if dataService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.emerald))
                                .padding()
                        }

                        // Portfolio Health Score
                        PortfolioHealthCard(
                            score: portfolioHealthScore,
                            propertiesCount: properties.count,
                            occupancyRate: occupancyRate,
                            pendingMaintenance: pendingMaintenanceCount
                        )

                        // Key Metrics Row
                        KeyMetricsRow(
                            totalRevenue: totalMonthlyRevenue,
                            occupancyRate: occupancyRate,
                            pendingMaintenance: pendingMaintenanceCount
                        )

                        // Time Range Picker
                        TimeRangePicker(selectedRange: $selectedTimeRange)

                        // Revenue Chart
                        RevenueChartCardSimple(timeRange: selectedTimeRange, totalRevenue: totalMonthlyRevenue)

                        // Property Status Grid
                        ConvexPropertyStatusGrid(properties: properties)

                        // Quick Stats
                        QuickStatsSection(
                            tenantCount: tenants.count,
                            propertyCount: properties.count,
                            contractorCount: dataService.contractors.count
                        )
                    }
                    .padding(Theme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .refreshable {
            await dataService.loadAllData()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateCharts = true
            }
        }
    }

    // MARK: - Computed Properties
    private var portfolioHealthScore: Int {
        dataService.portfolioHealthScore
    }

    private var totalMonthlyRevenue: Double {
        dataService.totalMonthlyRevenue
    }

    private var occupancyRate: Double {
        dataService.occupancyRate
    }

    private var pendingMaintenanceCount: Int {
        dataService.pendingMaintenanceCount
    }
}

// MARK: - Command Header
struct CommandHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Command Center")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(Date(), style: .date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            // Refresh button
            Button {
                HapticManager.shared.impact(.light)
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.Colors.slate400)
            }
        }
    }
}

// MARK: - Portfolio Health Card
struct PortfolioHealthCard: View {
    let score: Int
    let propertiesCount: Int
    let occupancyRate: Double
    let pendingMaintenance: Int
    @State private var animatedScore: Int = 0
    @State private var ringProgress: Double = 0

    var body: some View {
        let hasData = propertiesCount > 0 || pendingMaintenance > 0 || occupancyRate > 0
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Text("Portfolio Health")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Image(systemName: healthIcon)
                    .foregroundColor(healthColor)
                    .symbolEffect(.pulse, isActive: score < 60)
            }

            HStack(spacing: Theme.Spacing.xl) {
                // Animated Ring
                ZStack {
                    Circle()
                        .stroke(Theme.Colors.slate700, lineWidth: 12)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            healthGradient,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text(hasData ? "\(animatedScore)" : "—")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .contentTransition(.numericText())

                        Text("/ 100")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HealthIndicator(label: "Properties", value: "\(propertiesCount) Active", color: Theme.Colors.emerald)
                    HealthIndicator(label: "Occupancy", value: "\(Int(occupancyRate * 100))%", color: Theme.Colors.infoBlue)
                    HealthIndicator(label: "Maintenance", value: "\(pendingMaintenance) Pending", color: Theme.Colors.warningAmber)
                }

                Spacer()
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedScore = hasData ? score : 0
                ringProgress = hasData ? Double(score) / 100.0 : 0
            }
        }
    }

    private var healthColor: Color {
        if !hasData { return Theme.Colors.slate500 }
        switch score {
        case 80...100: return Theme.Colors.emerald
        case 60..<80: return Theme.Colors.infoBlue
        case 40..<60: return Theme.Colors.warningAmber
        default: return Theme.Colors.alertRed
        }
    }

    private var healthGradient: LinearGradient {
        if !hasData {
            return LinearGradient(
                colors: [Theme.Colors.slate600, Theme.Colors.slate700],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        switch score {
        case 80...100: return Theme.Gradients.emeraldGlow
        case 60..<80: return LinearGradient(colors: [Theme.Colors.infoBlue, Theme.Colors.infoBlue.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        case 40..<60: return LinearGradient(colors: [Theme.Colors.warningAmber, Theme.Colors.warningAmber.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        default: return Theme.Gradients.alertPulse
        }
    }

    private var healthIcon: String {
        if !hasData { return "chart.line.downtrend.xyaxis" }
        switch score {
        case 80...100: return "checkmark.shield.fill"
        case 60..<80: return "shield.lefthalf.filled"
        case 40..<60: return "exclamationmark.shield.fill"
        default: return "xmark.shield.fill"
        }
    }

    private var hasData: Bool {
        propertiesCount > 0 || pendingMaintenance > 0 || occupancyRate > 0
    }
}

struct HealthIndicator: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textMuted)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
        }
    }
}

// MARK: - Key Metrics Row
struct KeyMetricsRow: View {
    let totalRevenue: Double
    let occupancyRate: Double
    let pendingMaintenance: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            MetricCard(
                icon: "dollarsign.circle.fill",
                label: "Monthly Revenue",
                value: "$\(Int(totalRevenue).formatted())",
                color: Theme.Colors.gold
            )

            MetricCard(
                icon: "person.2.fill",
                label: "Occupancy",
                value: "\(Int(occupancyRate * 100))%",
                color: Theme.Colors.emerald
            )

            MetricCard(
                icon: "wrench.fill",
                label: "Pending",
                value: "\(pendingMaintenance)",
                color: pendingMaintenance > 0 ? Theme.Colors.warningAmber : Theme.Colors.emerald
            )
        }
    }
}

struct MetricCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)

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
}

// MARK: - Time Range Picker
struct TimeRangePicker: View {
    @Binding var selectedRange: CommandCenterView.TimeRange
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CommandCenterView.TimeRange.allCases, id: \.self) { range in
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3)) {
                        selectedRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 14, weight: selectedRange == range ? .bold : .medium))
                        .foregroundColor(selectedRange == range ? .white : Theme.Colors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if selectedRange == range {
                                Capsule()
                                    .fill(Theme.Colors.emerald)
                                    .matchedGeometryEffect(id: "timeRange", in: animation)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(Theme.Colors.slate800)
        }
    }
}

// MARK: - Revenue Chart Card (Simplified for Convex)
struct RevenueChartCardSimple: View {
    let timeRange: CommandCenterView.TimeRange
    let totalRevenue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Revenue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Text("$\(Int(totalRevenue).formatted())")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.emerald)
            }

            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate800.opacity(0.5))
                .frame(height: 180)
                .overlay {
                    if totalRevenue <= 0 {
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
                    } else {
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(0..<7, id: \.self) { _ in
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Theme.Gradients.emeraldGlow)
                                        .frame(height: 100)
                                }
                            }
                        }
                        .padding()
                    }
                }

            HStack {
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.Colors.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }
}

// MARK: - Convex Property Status Grid
struct ConvexPropertyStatusGrid: View {
    let properties: [ConvexProperty]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Properties")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)

            if properties.isEmpty {
                Text("No properties yet")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
            } else {
                ForEach(properties) { property in
                    ConvexPropertyStatusRow(property: property)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }
}

struct ConvexPropertyStatusRow: View {
    let property: ConvexProperty

    private var propertyIcon: String {
        switch property.propertyType {
        case "Single Family": return "house.fill"
        case "Multi-Family": return "building.2.fill"
        case "Apartment": return "building.fill"
        case "Condo": return "building.columns.fill"
        case "Townhouse": return "house.and.flag.fill"
        case "Commercial": return "storefront.fill"
        default: return "building.2.fill"
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Property icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Colors.slate700)
                    .frame(width: 44, height: 44)

                Image(systemName: propertyIcon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.emerald)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(property.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("\(property.units) unit\(property.units > 1 ? "s" : "") • $\(Int(property.monthlyRent))/mo")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            // Property type badge
            Text(property.propertyType)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.Colors.emerald)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(Theme.Colors.emerald.opacity(0.15))
                }
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate800.opacity(0.3))
        }
    }
}

// MARK: - Quick Stats Section
struct QuickStatsSection: View {
    let tenantCount: Int
    let propertyCount: Int
    let contractorCount: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            QuickStatBadge(icon: "person.fill", value: "\(tenantCount)", label: "Tenants")
            QuickStatBadge(icon: "building.2.fill", value: "\(propertyCount)", label: "Properties")
            QuickStatBadge(icon: "wrench.fill", value: "\(contractorCount)", label: "Contractors")
        }
    }
}

struct QuickStatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.slate400)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.Colors.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate800.opacity(0.5))
        }
    }
}

#Preview {
    CommandCenterView()
        .environmentObject(ConvexDataService.shared)
}

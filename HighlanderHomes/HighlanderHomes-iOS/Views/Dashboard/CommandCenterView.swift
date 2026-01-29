import SwiftUI
import SwiftData
import Charts

struct CommandCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var properties: [Property]
    @Query private var tenants: [Tenant]
    @Query private var maintenanceRequests: [MaintenanceRequest]
    @Query private var rentPayments: [RentPayment]

    @State private var selectedTimeRange: TimeRange = .month
    @State private var animateCharts = false

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

                        // Portfolio Health Score
                        PortfolioHealthCard(score: portfolioHealthScore)

                        // Key Metrics Row
                        KeyMetricsRow(
                            totalRevenue: totalMonthlyRevenue,
                            occupancyRate: occupancyRate,
                            pendingMaintenance: pendingMaintenanceCount
                        )

                        // Time Range Picker
                        TimeRangePicker(selectedRange: $selectedTimeRange)

                        // Revenue Chart
                        RevenueChartCard(payments: rentPayments, timeRange: selectedTimeRange)

                        // Property Status Grid
                        PropertyStatusGrid(properties: properties)

                        // Quick Stats
                        QuickStatsSection(
                            tenantCount: tenants.count,
                            propertyCount: properties.count,
                            contractorCount: 5 // Placeholder
                        )
                    }
                    .padding(Theme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            loadSampleDataIfNeeded()
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateCharts = true
            }
        }
    }

    // MARK: - Computed Properties
    private var portfolioHealthScore: Int {
        guard !properties.isEmpty else { return 100 }
        let totalScore = properties.reduce(0) { $0 + $1.healthScore }
        return totalScore / properties.count
    }

    private var totalMonthlyRevenue: Double {
        properties.reduce(0) { $0 + $1.monthlyRent }
    }

    private var occupancyRate: Double {
        guard !properties.isEmpty else { return 1.0 }
        let totalUnits = properties.reduce(0) { $0 + $1.units }
        let occupiedUnits = tenants.filter { $0.isActive }.count
        return Double(occupiedUnits) / Double(totalUnits)
    }

    private var pendingMaintenanceCount: Int {
        maintenanceRequests.filter { $0.status != .completed && $0.status != .cancelled }.count
    }

    private func loadSampleDataIfNeeded() {
        if properties.isEmpty {
            let sampleProperties = [
                Property(
                    name: "Oak Street Duplex",
                    address: "123 Oak Street",
                    city: "Austin",
                    state: "TX",
                    zipCode: "78701",
                    propertyType: .multiFamily,
                    units: 2,
                    monthlyRent: 3200
                ),
                Property(
                    name: "Maple Avenue House",
                    address: "456 Maple Avenue",
                    city: "Austin",
                    state: "TX",
                    zipCode: "78702",
                    propertyType: .singleFamily,
                    units: 1,
                    monthlyRent: 2400
                ),
                Property(
                    name: "Cedar Park Complex",
                    address: "789 Cedar Blvd",
                    city: "Cedar Park",
                    state: "TX",
                    zipCode: "78613",
                    propertyType: .apartment,
                    units: 4,
                    monthlyRent: 5600
                )
            ]

            for property in sampleProperties {
                modelContext.insert(property)
            }
        }
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
    @State private var animatedScore: Int = 0
    @State private var ringProgress: Double = 0

    var body: some View {
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
                        Text("\(animatedScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.Colors.textPrimary)
                            .contentTransition(.numericText())

                        Text("/ 100")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HealthIndicator(label: "Properties", value: "3 Active", color: Theme.Colors.emerald)
                    HealthIndicator(label: "Occupancy", value: "87%", color: Theme.Colors.infoBlue)
                    HealthIndicator(label: "Maintenance", value: "2 Pending", color: Theme.Colors.warningAmber)
                }

                Spacer()
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedScore = score
                ringProgress = Double(score) / 100.0
            }
        }
    }

    private var healthColor: Color {
        switch score {
        case 80...100: return Theme.Colors.emerald
        case 60..<80: return Theme.Colors.infoBlue
        case 40..<60: return Theme.Colors.warningAmber
        default: return Theme.Colors.alertRed
        }
    }

    private var healthGradient: LinearGradient {
        switch score {
        case 80...100: return Theme.Gradients.emeraldGlow
        case 60..<80: return LinearGradient(colors: [Theme.Colors.infoBlue, Theme.Colors.infoBlue.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        case 40..<60: return LinearGradient(colors: [Theme.Colors.warningAmber, Theme.Colors.warningAmber.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
        default: return Theme.Gradients.alertPulse
        }
    }

    private var healthIcon: String {
        switch score {
        case 80...100: return "checkmark.shield.fill"
        case 60..<80: return "shield.lefthalf.filled"
        case 40..<60: return "exclamationmark.shield.fill"
        default: return "xmark.shield.fill"
        }
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

// MARK: - Revenue Chart Card
struct RevenueChartCard: View {
    let payments: [RentPayment]
    let timeRange: CommandCenterView.TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Revenue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Text("$11,200")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.emerald)
            }

            // Placeholder chart area
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate800.opacity(0.5))
                .frame(height: 180)
                .overlay {
                    // Simple bar chart visualization
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Gradients.emeraldGlow)
                                    .frame(height: CGFloat.random(in: 40...140))
                            }
                        }
                    }
                    .padding()
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

// MARK: - Property Status Grid
struct PropertyStatusGrid: View {
    let properties: [Property]

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
                    PropertyStatusRow(property: property)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }
}

struct PropertyStatusRow: View {
    let property: Property

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Property icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.Colors.slate700)
                    .frame(width: 44, height: 44)

                Image(systemName: property.propertyType.icon)
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

            // Health indicator
            HStack(spacing: 4) {
                Image(systemName: property.healthStatus.icon)
                    .font(.system(size: 14))

                Text("\(property.healthScore)")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(healthColor(for: property.healthStatus))
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate800.opacity(0.3))
        }
    }

    private func healthColor(for status: Property.HealthStatus) -> Color {
        switch status {
        case .excellent: return Theme.Colors.emerald
        case .good: return Theme.Colors.infoBlue
        case .attention: return Theme.Colors.warningAmber
        case .critical: return Theme.Colors.alertRed
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
        .modelContainer(for: [Property.self, Tenant.self, MaintenanceRequest.self, RentPayment.self], inMemory: true)
}

import SwiftUI

struct PropertyDetailView: View {
    let property: ConvexProperty
    @EnvironmentObject var dataService: ConvexDataService

    @State private var showingAddInsurance = false
    @State private var showingAddLicense = false
    @State private var showingMarketTrendSheet = false
    @State private var selectedPolicy: ConvexInsurancePolicy?
    @State private var selectedLicense: ConvexRentalLicense?
    @State private var selectedMarketTrend: ConvexMarketTrend?

    private var tenants: [ConvexTenant] {
        dataService.tenants.filter { $0.propertyId == property.id }
    }

    private var activeTenants: [ConvexTenant] {
        tenants.filter { $0.isActive }
    }

    private var maintenanceRequests: [ConvexMaintenanceRequest] {
        dataService.maintenanceRequests.filter { $0.propertyId == property.id }
    }

    private var activeMaintenanceCount: Int {
        maintenanceRequests.filter { $0.status != "completed" && $0.status != "cancelled" }.count
    }

    private var rentPayments: [ConvexRentPayment] {
        dataService.rentPayments.filter { $0.propertyId == property.id }
    }

    private var expenses: [ConvexExpense] {
        dataService.expenses.filter { $0.propertyId == property.id }
    }

    private var insurancePolicies: [ConvexInsurancePolicy] {
        let label = normalizeLabel(property.displayAddress)
        return dataService.insurancePolicies.filter { policy in
            if let propertyId = policy.propertyId {
                return propertyId == property.id
            }
            return normalizeLabel(policy.propertyLabel) == label
        }
    }

    private var rentalLicenses: [ConvexRentalLicense] {
        let label = normalizeLabel(property.displayAddress)
        return dataService.rentalLicenses.filter { license in
            if let propertyId = license.propertyId {
                return propertyId == property.id
            }
            return normalizeLabel(license.propertyLabel) == label
        }
    }

    private var marketTrends: [ConvexMarketTrend] {
        dataService.marketTrends
            .filter { trend in
                if let trendPropertyId = trend.propertyId {
                    return trendPropertyId == property.id
                }
                return normalizeLabel(trend.areaLabel).contains(normalizeLabel(property.zipCode))
            }
            .sorted { $0.observedAt > $1.observedAt }
    }

    private var monthlyIncome: Double {
        property.monthlyRent
    }

    private var monthlyExpenses: Double {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return 0 }
        let startMs = monthStart.timeIntervalSince1970 * 1000
        let endMs = monthEnd.timeIntervalSince1970 * 1000
        return expenses.filter { $0.date >= startMs && $0.date < endMs }.reduce(0) { $0 + $1.amount }
    }

    private var occupancyRate: Int {
        guard property.units > 0 else { return 0 }
        return Int(Double(activeTenants.count) / Double(property.units) * 100)
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header Stats
                    PropertyStatsRow(
                        monthlyIncome: monthlyIncome,
                        occupancyRate: occupancyRate,
                        activeIssues: activeMaintenanceCount
                    )

                    // Address
                    PropertyAddressCard(property: property)

                    // Tenants Section
                    PropertyTenantsSection(
                        tenants: activeTenants,
                        totalUnits: property.units
                    )

                    // Leases Section
                    PropertyLeasesSection(tenants: tenants)

                    // Maintenance Section
                    PropertyMaintenanceSection(
                        requests: maintenanceRequests.filter { $0.status != "completed" && $0.status != "cancelled" }
                    )

                    // Financials Section
                    PropertyFinancialsSection(
                        income: monthlyIncome,
                        expenses: monthlyExpenses,
                        payments: rentPayments,
                        expenseItems: expenses
                    )

                    // Documents Section (Insurance + Licenses)
                    PropertyDocumentsSection(
                        insurancePolicies: insurancePolicies,
                        rentalLicenses: rentalLicenses,
                        onAddInsurance: { showingAddInsurance = true },
                        onAddLicense: { showingAddLicense = true },
                        onSelectPolicy: { selectedPolicy = $0 },
                        onSelectLicense: { selectedLicense = $0 }
                    )

                    PropertyMarketSection(
                        trends: marketTrends,
                        onAdd: { showingMarketTrendSheet = true },
                        onSelect: { selectedMarketTrend = $0 }
                    )
                }
                .padding(Theme.Spacing.md)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle(property.name)
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await dataService.loadAllData()
        }
        .sheet(isPresented: $showingAddInsurance) {
            AddEntitySheet(selectedTab: .insurance, prefillProperty: property)
        }
        .sheet(isPresented: $showingAddLicense) {
            AddEntitySheet(selectedTab: .licenses, prefillProperty: property)
        }
        .sheet(item: $selectedPolicy) { policy in
            ConvexInsurancePolicyDetailSheet(policy: policy)
        }
        .sheet(item: $selectedLicense) { license in
            ConvexRentalLicenseDetailSheet(license: license)
        }
        .sheet(isPresented: $showingMarketTrendSheet) {
            MarketTrendDetailSheet(property: property)
        }
        .sheet(item: $selectedMarketTrend) { trend in
            MarketTrendDetailSheet(property: property, trend: trend)
        }
    }

    private func normalizeLabel(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    }
}

// MARK: - Property Stats Row
struct PropertyStatsRow: View {
    let monthlyIncome: Double
    let occupancyRate: Int
    let activeIssues: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            StatPill(
                value: "$\(Int(monthlyIncome).formatted())",
                label: "Monthly",
                color: Theme.Colors.emerald
            )
            StatPill(
                value: "\(occupancyRate)%",
                label: "Occupied",
                color: Theme.Colors.infoBlue
            )
            StatPill(
                value: "\(activeIssues)",
                label: "Issues",
                color: activeIssues > 0 ? Theme.Colors.warningAmber : Theme.Colors.emerald
            )
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(color.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Address Card
struct PropertyAddressCard: View {
    let property: ConvexProperty

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Theme.Colors.emerald)

            VStack(alignment: .leading, spacing: 2) {
                Text(property.address)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("\(property.city), \(property.state) \(property.zipCode)")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            Text(property.propertyType)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.Colors.emerald)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background { Capsule().fill(Theme.Colors.emerald.opacity(0.15)) }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Tenants Section
struct PropertyTenantsSection: View {
    let tenants: [ConvexTenant]
    let totalUnits: Int

    var body: some View {
        CollapsibleSection(
            title: "Tenants",
            count: tenants.count,
            icon: "person.2.fill"
        ) {
            if tenants.isEmpty {
                Text("No active tenants")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textMuted)
                    .padding(.vertical, Theme.Spacing.sm)
            } else {
                ForEach(tenants) { tenant in
                    TenantRow(tenant: tenant)
                }
            }
        }
    }
}

struct TenantRow: View {
    let tenant: ConvexTenant

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.emerald.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(tenant.initials)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.Colors.emerald)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tenant.fullName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                HStack(spacing: 4) {
                    if let unit = tenant.unit, !unit.isEmpty {
                        Text("Unit \(unit)")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textSecondary)
                        Text("\u{2022}")
                            .foregroundColor(Theme.Colors.textMuted)
                    }
                    Text("$\(Int(tenant.monthlyRent))/mo")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.Colors.emerald)
                }
            }

            Spacer()

            Text(tenant.leaseStatus)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(tenant.isActive ? Theme.Colors.emerald : Theme.Colors.warningAmber)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background {
                    Capsule()
                        .fill((tenant.isActive ? Theme.Colors.emerald : Theme.Colors.warningAmber).opacity(0.15))
                }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Leases Section
struct PropertyLeasesSection: View {
    let tenants: [ConvexTenant]

    var body: some View {
        CollapsibleSection(
            title: "Leases",
            count: tenants.count,
            icon: "doc.text.fill"
        ) {
            if tenants.isEmpty {
                Text("No leases on record")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textMuted)
                    .padding(.vertical, Theme.Spacing.sm)
            } else {
                ForEach(tenants) { tenant in
                    LeaseRow(tenant: tenant)
                }
            }
        }
    }
}

struct LeaseRow: View {
    let tenant: ConvexTenant

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: tenant.leaseEndDateValue).day ?? 0
    }

    private var leaseColor: Color {
        if daysRemaining < 0 { return Theme.Colors.alertRed }
        if daysRemaining < 30 { return Theme.Colors.warningAmber }
        if daysRemaining < 90 { return Theme.Colors.infoBlue }
        return Theme.Colors.emerald
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(tenant.fullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("\(dateFormatter.string(from: tenant.leaseStartDateValue)) - \(dateFormatter.string(from: tenant.leaseEndDateValue))")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            if daysRemaining < 0 {
                Text("Expired")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(leaseColor)
            } else {
                Text("\(daysRemaining)d left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(leaseColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Maintenance Section
struct PropertyMaintenanceSection: View {
    let requests: [ConvexMaintenanceRequest]

    var body: some View {
        CollapsibleSection(
            title: "Active Maintenance",
            count: requests.count,
            icon: "wrench.and.screwdriver.fill"
        ) {
            if requests.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.emerald)
                    Text("No active issues")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.vertical, Theme.Spacing.sm)
            } else {
                ForEach(requests) { request in
                    MaintenanceRow(request: request)
                }
            }
        }
    }
}

struct MaintenanceRow: View {
    let request: ConvexMaintenanceRequest

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.warningAmber.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "wrench.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.warningAmber)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(request.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)
                Text(request.category)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            ConvexStatusBadge(status: request.status)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Financials Section
struct PropertyFinancialsSection: View {
    let income: Double
    let expenses: Double
    let payments: [ConvexRentPayment]
    let expenseItems: [ConvexExpense]

    private var noi: Double { income - expenses }

    var body: some View {
        CollapsibleSection(
            title: "Financials",
            count: nil,
            icon: "dollarsign.circle.fill"
        ) {
            VStack(spacing: Theme.Spacing.sm) {
                FinancialRow(label: "Monthly Revenue", amount: income, color: Theme.Colors.emerald)
                FinancialRow(label: "Monthly Expenses", amount: -expenses, color: Theme.Colors.alertRed)
                Divider().background(Theme.Colors.slate700)
                FinancialRow(label: "Net Operating Income", amount: noi, color: noi >= 0 ? Theme.Colors.emerald : Theme.Colors.alertRed, isBold: true)
            }
        }
    }
}

struct FinancialRow: View {
    let label: String
    let amount: Double
    let color: Color
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: isBold ? .bold : .medium))
                .foregroundColor(isBold ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
            Spacer()
            Text(amount >= 0 ? "$\(Int(amount).formatted())" : "-$\(Int(abs(amount)).formatted())")
                .font(.system(size: 14, weight: isBold ? .bold : .semibold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

// MARK: - Documents Section (Insurance + Licenses)
struct PropertyDocumentsSection: View {
    let insurancePolicies: [ConvexInsurancePolicy]
    let rentalLicenses: [ConvexRentalLicense]
    let onAddInsurance: () -> Void
    let onAddLicense: () -> Void
    let onSelectPolicy: (ConvexInsurancePolicy) -> Void
    let onSelectLicense: (ConvexRentalLicense) -> Void

    private var totalDocs: Int { insurancePolicies.count + rentalLicenses.count }

    var body: some View {
        CollapsibleSection(
            title: "Documents",
            count: totalDocs,
            icon: "folder.fill"
        ) {
            HStack(spacing: Theme.Spacing.sm) {
                Button("Add Insurance") { onAddInsurance() }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule().fill(Theme.Colors.infoBlue)
                    }

                Button("Add License") { onAddLicense() }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        Capsule().fill(Theme.Colors.emerald)
                    }
            }
            .padding(.bottom, Theme.Spacing.sm)

            if insurancePolicies.isEmpty && rentalLicenses.isEmpty {
                Text("No documents on file")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textMuted)
                    .padding(.vertical, Theme.Spacing.sm)
            } else {
                ForEach(insurancePolicies) { policy in
                    DocumentRow(
                        icon: "shield.fill",
                        title: policy.insuranceName,
                        subtitle: "Policy #\(policy.policyNumber)",
                        trailing: policy.isExpired ? "Expired" : (policy.isExpiringSoon ? "\(policy.daysUntilExpiration)d left" : policy.termDisplay),
                        color: policy.isExpired ? Theme.Colors.alertRed : (policy.isExpiringSoon ? Theme.Colors.warningAmber : Theme.Colors.infoBlue)
                    ) {
                        onSelectPolicy(policy)
                    }
                }

                ForEach(rentalLicenses) { license in
                    DocumentRow(
                        icon: "doc.text.fill",
                        title: license.category,
                        subtitle: "#\(license.licenseNumber)",
                        trailing: license.isExpired ? "Expired" : (license.isExpiringSoon ? "\(license.daysUntilExpiration)d left" : license.termDisplay),
                        color: license.isExpired ? Theme.Colors.alertRed : (license.isExpiringSoon ? Theme.Colors.warningAmber : Theme.Colors.emerald)
                    ) {
                        onSelectLicense(license)
                    }
                }
            }
        }
    }
}

// MARK: - Market Section
struct PropertyMarketSection: View {
    let trends: [ConvexMarketTrend]
    let onAdd: () -> Void
    let onSelect: (ConvexMarketTrend) -> Void

    var body: some View {
        CollapsibleSection(
            title: "Market Watch",
            count: trends.count,
            icon: "chart.line.uptrend.xyaxis"
        ) {
            HStack {
                Button("Add Snapshot") { onAdd() }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background { Capsule().fill(Theme.Colors.emerald) }

                Spacer()
            }
            .padding(.bottom, Theme.Spacing.sm)

            if trends.isEmpty {
                Text("No market snapshots yet")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textMuted)
                    .padding(.vertical, Theme.Spacing.sm)
            } else {
                ForEach(trends.prefix(8)) { trend in
                    Button {
                        onSelect(trend)
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.infoBlue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(trend.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                Text(trend.areaLabel)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                if trend.estimateRent != nil {
                                    Text(trend.rentDisplay)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Theme.Colors.emerald)
                                }
                                if trend.estimatePrice != nil {
                                    Text(trend.priceDisplay)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct DocumentRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let trailing: String
    let color: Color
    var onSelect: (() -> Void)? = nil

    var body: some View {
        Button {
            onSelect?()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()

                Text(trailing)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct MarketTrendDetailSheet: View {
    let property: ConvexProperty
    let trend: ConvexMarketTrend?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false

    @State private var title: String
    @State private var marketType: String
    @State private var areaLabel: String
    @State private var estimatePrice: String
    @State private var estimateRent: String
    @State private var yoyChangePct: String
    @State private var demandLevel: String
    @State private var source: String
    @State private var sourceURL: String
    @State private var notes: String
    @State private var observedAt: Date

    init(property: ConvexProperty, trend: ConvexMarketTrend? = nil) {
        self.property = property
        self.trend = trend
        _title = State(initialValue: trend?.title ?? "Market Snapshot")
        _marketType = State(initialValue: trend?.marketType ?? "areaTrend")
        _areaLabel = State(initialValue: trend?.areaLabel ?? "\(property.city), \(property.state) \(property.zipCode)")
        if let estimatePrice = trend?.estimatePrice {
            _estimatePrice = State(initialValue: String(format: "%.0f", estimatePrice))
        } else {
            _estimatePrice = State(initialValue: "")
        }
        if let estimateRent = trend?.estimateRent {
            _estimateRent = State(initialValue: String(format: "%.0f", estimateRent))
        } else {
            _estimateRent = State(initialValue: "")
        }
        if let yoyChangePct = trend?.yoyChangePct {
            _yoyChangePct = State(initialValue: String(format: "%.1f", yoyChangePct))
        } else {
            _yoyChangePct = State(initialValue: "")
        }
        _demandLevel = State(initialValue: trend?.demandLevel ?? "normal")
        _source = State(initialValue: trend?.source ?? "")
        _sourceURL = State(initialValue: trend?.sourceURL ?? "")
        _notes = State(initialValue: trend?.notes ?? "")
        _observedAt = State(initialValue: trend?.observedDate ?? Date())
    }

    private var isEditing: Bool { trend != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.alertRed)
                        }

                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)

                        Picker("Type", selection: $marketType) {
                            Text("Area Trend").tag("areaTrend")
                            Text("Property Value").tag("propertyValue")
                            Text("Rent Comps").tag("rentComps")
                            Text("Demand").tag("demand")
                        }
                        .pickerStyle(.segmented)

                        TextField("Area / ZIP", text: $areaLabel)
                            .textFieldStyle(.roundedBorder)

                        TextField("Estimated Value", text: $estimatePrice)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)

                        TextField("Estimated Rent", text: $estimateRent)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)

                        TextField("YoY Change %", text: $yoyChangePct)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)

                        Picker("Demand", selection: $demandLevel) {
                            Text("Low").tag("low")
                            Text("Normal").tag("normal")
                            Text("High").tag("high")
                        }
                        .pickerStyle(.segmented)

                        DatePicker("Observed", selection: $observedAt, displayedComponents: .date)

                        TextField("Source", text: $source)
                            .textFieldStyle(.roundedBorder)
                        TextField("Source URL", text: $sourceURL)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                        TextField("Notes", text: $notes)
                            .textFieldStyle(.roundedBorder)

                        if isEditing {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Text("Delete Snapshot")
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.top, Theme.Spacing.sm)
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle(isEditing ? "Edit Market" : "Add Market")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                    .foregroundColor(Theme.Colors.emerald)
                }
            }
            .alert("Delete Market Snapshot?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { Task { await remove() } }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "Title is required."
            isSaving = false
            return
        }

        do {
            if let trend {
                let input = ConvexMarketTrendUpdateInput(
                    id: trend.id,
                    title: cleanTitle,
                    marketType: marketType,
                    areaLabel: areaLabel.trimmingCharacters(in: .whitespacesAndNewlines),
                    estimatePrice: parseNumber(estimatePrice),
                    estimateRent: parseNumber(estimateRent),
                    yoyChangePct: parseNumber(yoyChangePct),
                    demandLevel: demandLevel,
                    source: source.trimmedNil,
                    sourceURL: sourceURL.trimmedNil,
                    notes: notes.trimmedNil,
                    observedAt: observedAt
                )
                _ = try await dataService.updateMarketTrend(input)
            } else {
                let input = ConvexMarketTrendInput(
                    propertyId: property.id,
                    title: cleanTitle,
                    marketType: marketType,
                    areaLabel: areaLabel.trimmingCharacters(in: .whitespacesAndNewlines),
                    estimatePrice: parseNumber(estimatePrice),
                    estimateRent: parseNumber(estimateRent),
                    yoyChangePct: parseNumber(yoyChangePct),
                    demandLevel: demandLevel,
                    source: source.trimmedNil,
                    sourceURL: sourceURL.trimmedNil,
                    notes: notes.trimmedNil,
                    observedAt: observedAt
                )
                _ = try await dataService.createMarketTrend(input)
            }

            await dataService.loadAllData()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func remove() async {
        guard let trend else { return }
        do {
            try await dataService.deleteMarketTrend(id: trend.id)
            await dataService.loadAllData()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func parseNumber(_ value: String) -> Double? {
        let cleaned = value.filter { "0123456789.-".contains($0) }
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }
}

private extension String {
    var trimmedNil: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

// MARK: - Collapsible Section Component
struct CollapsibleSection<Content: View>: View {
    let title: String
    let count: Int?
    let icon: String
    @ViewBuilder let content: () -> Content
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.emerald)

                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    if let count {
                        Text("(\(count))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.slate500)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        PropertyDetailView(property: ConvexProperty(
            id: "test",
            name: "Oak Street House",
            address: "123 Oak Street",
            city: "Austin",
            state: "TX",
            zipCode: "78701",
            propertyType: "Single Family",
            units: 3,
            monthlyRent: 3600,
            purchasePrice: nil,
            currentValue: nil,
            imageURL: nil,
            notes: nil,
            createdAt: Date().timeIntervalSince1970 * 1000,
            updatedAt: Date().timeIntervalSince1970 * 1000
        ))
        .environmentObject(ConvexDataService.shared)
    }
}

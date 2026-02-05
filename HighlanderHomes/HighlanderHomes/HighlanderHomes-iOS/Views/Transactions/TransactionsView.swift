import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @State private var selectedMonth = Date()
    @State private var selectedPropertyId: String = "all"
    @State private var selectedCategory: String = "all"
    @State private var selectedType: TransactionTypeFilter = .all
    @State private var selectedRange: DateRangeFilter = .month
    @State private var showRentStatus = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        TransactionSummaryCard(totals: totals)

                        FilterBar(
                            selectedPropertyId: $selectedPropertyId,
                            selectedCategory: $selectedCategory,
                            selectedType: $selectedType,
                            selectedRange: $selectedRange,
                            properties: dataService.properties,
                            categories: categoryOptions
                        )

                        if selectedRange == .month {
                            MonthSelector(selectedMonth: $selectedMonth)
                        }

                        if dataService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.emerald))
                                .padding()
                        }

                        if groupedTransactions.isEmpty && !dataService.isLoading {
                            EmptyStateView(
                                title: "No Transactions Yet",
                                subtitle: "Add rent payments or expenses to see them here.",
                                icon: "dollarsign.circle.fill"
                            )
                            .padding(.top, Theme.Spacing.xl)
                        } else {
                            LazyVStack(spacing: Theme.Spacing.md) {
                                ForEach(groupedTransactions, id: \.date) { group in
                                    TransactionGroupCard(date: group.date, items: group.items)
                                }
                            }
                        }

                        if !dataService.properties.isEmpty {
                            DisclosureGroup(isExpanded: $showRentStatus) {
                                VStack(spacing: Theme.Spacing.md) {
                                    ForEach(dataService.properties) { property in
                                        PropertyRentStatusCard(
                                            property: property,
                                            tenants: dataService.tenants.filter { $0.propertyId == property.id },
                                            payments: dataService.rentPayments,
                                            monthStart: monthStart,
                                            monthEnd: monthEnd
                                        )
                                    }
                                }
                                .padding(.top, Theme.Spacing.sm)
                            } label: {
                                HStack {
                                    Text("Rent Status")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    Spacer()
                                    Text(showRentStatus ? "Hide" : "Show")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                            .padding(Theme.Spacing.lg)
                            .cardStyle()
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
        }
        .refreshable {
            await dataService.loadAllData()
        }
    }

    private var monthStart: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: selectedMonth)
        return Calendar.current.date(from: components) ?? selectedMonth
    }

    private var monthEnd: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? selectedMonth
    }

    private var allTransactions: [TransactionItem] {
        let propertyMap = Dictionary(uniqueKeysWithValues: dataService.properties.map { ($0.id, $0.name) })
        let tenantMap = Dictionary(uniqueKeysWithValues: dataService.tenants.map { ($0.id, $0.fullName) })

        var items: [TransactionItem] = []

        for payment in dataService.rentPayments {
            let propertyName = propertyMap[payment.propertyId] ?? "Property"
            let tenantName = payment.tenantId.flatMap { tenantMap[$0] }
            items.append(TransactionItem(
                id: payment.id,
                title: tenantName ?? "Rent Payment",
                subtitle: propertyName,
                category: "Rent",
                amount: payment.amount,
                date: payment.paymentDateValue,
                isIncome: true,
                propertyId: payment.propertyId
            ))
        }

        for expense in dataService.expenses {
            let propertyName = expense.propertyId.flatMap { propertyMap[$0] } ?? "General"
            items.append(TransactionItem(
                id: expense.id,
                title: expense.title,
                subtitle: propertyName,
                category: prettyCategory(expense.category),
                amount: expense.amount,
                date: expense.dateValue,
                isIncome: false,
                propertyId: expense.propertyId
            ))
        }

        return items
    }

    private var filteredTransactions: [TransactionItem] {
        allTransactions.filter { item in
            if selectedPropertyId != "all", item.propertyId != selectedPropertyId {
                return false
            }
            if selectedCategory != "all", item.category != selectedCategory {
                return false
            }
            switch selectedType {
            case .all:
                break
            case .income:
                if !item.isIncome { return false }
            case .expense:
                if item.isIncome { return false }
            }
            if selectedRange == .month {
                return item.date >= monthStart && item.date < monthEnd
            }
            return true
        }
        .sorted { $0.date > $1.date }
    }

    private var groupedTransactions: [(date: Date, items: [TransactionItem])] {
        let grouped = Dictionary(grouping: filteredTransactions) { item in
            Calendar.current.startOfDay(for: item.date)
        }
        return grouped.keys.sorted(by: >).map { date in
            let items = grouped[date]?.sorted { $0.date > $1.date } ?? []
            return (date: date, items: items)
        }
    }

    private var categoryOptions: [String] {
        let categories = Set(allTransactions.map { $0.category })
        return ["all"] + categories.sorted()
    }

    private var totals: TransactionTotals {
        let income = filteredTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        let expense = filteredTransactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        return TransactionTotals(income: income, expense: expense)
    }

    private func prettyCategory(_ raw: String) -> String {
        if raw.isEmpty { return "Other" }
        return raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

enum TransactionTypeFilter: String, CaseIterable, Identifiable {
    case all
    case income
    case expense

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .income: return "Income"
        case .expense: return "Expenses"
        }
    }
}

enum DateRangeFilter: String, CaseIterable, Identifiable {
    case month = "This Month"
    case all = "All Time"

    var id: String { rawValue }
}

struct TransactionTotals {
    let income: Double
    let expense: Double

    var net: Double {
        income - expense
    }
}

struct FilterBar: View {
    @Binding var selectedPropertyId: String
    @Binding var selectedCategory: String
    @Binding var selectedType: TransactionTypeFilter
    @Binding var selectedRange: DateRangeFilter
    let properties: [ConvexProperty]
    let categories: [String]

    private var propertyLabel: String {
        if selectedPropertyId == "all" {
            return "All Properties"
        }
        return properties.first { $0.id == selectedPropertyId }?.name ?? "Property"
    }

    private var categoryLabel: String {
        if selectedCategory == "all" {
            return "All Categories"
        }
        return selectedCategory
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Menu {
                    Button("All Properties") { selectedPropertyId = "all" }
                    ForEach(properties) { property in
                        Button(property.name) { selectedPropertyId = property.id }
                    }
                } label: {
                    TransactionFilterPill(icon: "building.2.fill", label: propertyLabel)
                }

                Menu {
                    ForEach(categories, id: \.self) { category in
                        let label = category == "all" ? "All Categories" : category
                        Button(label) { selectedCategory = category }
                    }
                } label: {
                    TransactionFilterPill(icon: "tag.fill", label: categoryLabel)
                }
            }

            HStack(spacing: Theme.Spacing.sm) {
                Menu {
                    ForEach(DateRangeFilter.allCases) { range in
                        Button(range.rawValue) { selectedRange = range }
                    }
                } label: {
                    TransactionFilterPill(icon: "calendar", label: selectedRange.rawValue)
                }

                Picker("Type", selection: $selectedType) {
                    ForEach(TransactionTypeFilter.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Theme.Colors.emerald)
            }
        }
    }
}

struct TransactionFilterPill: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)
        }
        .foregroundColor(Theme.Colors.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.small)
                .fill(Theme.Colors.slate800)
        }
    }
}

struct TransactionSummaryCard: View {
    let totals: TransactionTotals

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            SummaryStat(title: "Income", value: totals.income, color: Theme.Colors.emerald)
            SummaryStat(title: "Expenses", value: totals.expense, color: Theme.Colors.alertRed)
            SummaryStat(title: "Net", value: totals.net, color: totals.net >= 0 ? Theme.Colors.emerald : Theme.Colors.alertRed)
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }
}

struct SummaryStat: View {
    let title: String
    let value: Double
    let color: Color

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.Colors.textSecondary)
                .textCase(.uppercase)
            Text(formattedValue)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formattedValue: String {
        SummaryStat.formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct TransactionGroupCard: View {
    let date: Date
    let items: [TransactionItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(sectionTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
                Spacer()
                Text(sectionTotal)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(sectionNet >= 0 ? Theme.Colors.emerald : Theme.Colors.alertRed)
            }

            Divider()
                .background(Theme.Colors.slate700)

            ForEach(items) { item in
                TransactionRow(item: item)
                    .padding(.vertical, 6)
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }

    private var sectionNet: Double {
        items.reduce(0) { total, item in
            total + (item.isIncome ? item.amount : -item.amount)
        }
    }

    private var sectionTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        let value = formatter.string(from: NSNumber(value: abs(sectionNet))) ?? "$0"
        return sectionNet >= 0 ? "+\(value)" : "-\(value)"
    }

    private var sectionTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

struct MonthSelector: View {
    @Binding var selectedMonth: Date

    var body: some View {
        HStack {
            Button {
                withAnimation { selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth }
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            Text(monthTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Button {
                withAnimation { selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate800)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
}

struct PropertyRentStatusCard: View {
    @EnvironmentObject var dataService: ConvexDataService
    let property: ConvexProperty
    let tenants: [ConvexTenant]
    let payments: [ConvexRentPayment]
    let monthStart: Date
    let monthEnd: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(property.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(property.displayAddress)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(paidCount)/\(tenants.count) Paid")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.emerald)

                    Text("Due $\(Int(totalDue))")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

            if tenants.isEmpty {
                Text("No tenants assigned")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textMuted)
            } else {
                ForEach(tenants) { tenant in
                    TenantRentRow(
                        tenant: tenant,
                        isPaid: isTenantPaid(tenant),
                        onMarkPaid: {
                            Task {
                                let input = ConvexRentPaymentInput(
                                    propertyId: property.id,
                                    tenantId: tenant.id,
                                    amount: tenant.monthlyRent,
                                    paymentDate: Date(),
                                    paymentMethod: nil,
                                    status: "completed",
                                    transactionId: nil,
                                    notes: nil
                                )
                                _ = try await dataService.createRentPayment(input)
                                await dataService.loadAllData()
                            }
                        }
                    )
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }

    private var totalDue: Double {
        tenants.reduce(0) { $0 + $1.monthlyRent }
    }

    private var paidCount: Int {
        tenants.filter { isTenantPaid($0) }.count
    }

    private func isTenantPaid(_ tenant: ConvexTenant) -> Bool {
        payments.contains { payment in
            guard payment.tenantId == tenant.id else { return false }
            let date = payment.paymentDateValue
            return date >= monthStart && date < monthEnd
        }
    }
}

struct TenantRentRow: View {
    let tenant: ConvexTenant
    let isPaid: Bool
    let onMarkPaid: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tenant.fullName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                Text("$\(Int(tenant.monthlyRent)) / mo")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            if isPaid {
                Label("Paid", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.emerald)
            } else {
                Button {
                    onMarkPaid()
                } label: {
                    Text("Mark Paid")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            Capsule().fill(Theme.Colors.emerald)
                        }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct TransactionItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let category: String
    let amount: Double
    let date: Date
    let isIncome: Bool
    let propertyId: String?
}

struct TransactionRow: View {
    let item: TransactionItem

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)

                HStack(spacing: 8) {
                    Text(item.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)

                    CategoryPill(text: item.category, isIncome: item.isIncome)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedAmount)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(item.isIncome ? Theme.Colors.emerald : Theme.Colors.alertRed)
                Text(shortTime(item.date))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textMuted)
            }
        }
    }

    private var formattedAmount: String {
        let value = TransactionRow.formatter.string(from: NSNumber(value: item.amount)) ?? "$0"
        return item.isIncome ? "+\(value)" : "-\(value)"
    }

    private func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct CategoryPill: View {
    let text: String
    let isIncome: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(isIncome ? Theme.Colors.emerald : Theme.Colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill((isIncome ? Theme.Colors.emerald : Theme.Colors.slate600).opacity(0.15))
            }
    }
}

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.slate600)

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

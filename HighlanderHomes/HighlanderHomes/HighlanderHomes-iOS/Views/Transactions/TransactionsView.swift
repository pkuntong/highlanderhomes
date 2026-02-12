import SwiftUI
import UIKit

struct TransactionsView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @State private var selectedMonth = Date()
    @State private var selectedPropertyId: String = "all"
    @State private var selectedCategory: String = "all"
    @State private var selectedType: TransactionTypeFilter = .all
    @State private var selectedRange: DateRangeFilter = .month
    @State private var showRentStatus = true
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var selectedTransaction: TransactionItem?
    @State private var showBusinessFeeSheet = false
    @State private var pendingUndo: DeletedTransaction?
    @State private var showUndoBanner = false
    @State private var undoToken = UUID()

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
                                    Text("Properties")
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
                                    TransactionGroupCard(
                                        date: group.date,
                                        items: group.items,
                                        onSelect: { item in
                                            selectedTransaction = item
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Add Business Fee") { showBusinessFeeSheet = true }
                        Button("Export CSV") { exportCSV() }
                        Button("Export PDF") { exportPDF() }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet, onDismiss: { exportURL = nil }) {
                if let exportURL {
                    ShareSheet(activityItems: [exportURL])
                }
            }
            .sheet(item: $selectedTransaction) { item in
                TransactionEditSheet(item: item) { deleted in
                    presentUndo(for: deleted)
                }
            }
            .sheet(isPresented: $showBusinessFeeSheet) {
                BusinessFeeSheet { input in
                    Task {
                        do {
                            _ = try await dataService.createExpense(input)
                            await dataService.loadAllData()
                            showBusinessFeeSheet = false
                        } catch {
                            print("Business fee save failed: \(error)")
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showUndoBanner, let pendingUndo {
                    UndoBanner(message: pendingUndo.message) {
                        Task { await handleUndo() }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, 110)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
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
                category: "rent",
                amount: payment.amount,
                date: payment.paymentDateValue,
                isIncome: true,
                propertyId: payment.propertyId,
                kind: .rentPayment,
                tenantId: payment.tenantId,
                paymentMethod: payment.paymentMethod,
                status: payment.status,
                transactionId: payment.transactionId,
                notes: payment.notes,
                expenseDescription: nil,
                isRecurring: nil,
                recurringFrequency: nil,
                receiptURL: nil,
                vendor: nil
            ))
        }

        for expense in dataService.expenses {
            let propertyName = expense.propertyId.flatMap { propertyMap[$0] } ?? "General"
            items.append(TransactionItem(
                id: expense.id,
                title: expense.title,
                subtitle: propertyName,
                category: expense.category,
                amount: expense.amount,
                date: expense.dateValue,
                isIncome: false,
                propertyId: expense.propertyId,
                kind: .expense,
                tenantId: nil,
                paymentMethod: nil,
                status: nil,
                transactionId: nil,
                notes: expense.notes,
                expenseDescription: expense.description,
                isRecurring: expense.isRecurring,
                recurringFrequency: expense.recurringFrequency,
                receiptURL: expense.receiptURL,
                vendor: expense.vendor
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
        let sorted = categories.sorted { lhs, rhs in
            TransactionItem.prettyCategory(lhs) < TransactionItem.prettyCategory(rhs)
        }
        return ["all"] + sorted
    }

    private var totals: TransactionTotals {
        let income = filteredTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        let expense = filteredTransactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        return TransactionTotals(income: income, expense: expense)
    }

    private func exportCSV() {
        guard !filteredTransactions.isEmpty else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        var rows: [String] = [
            "Date,Time,Type,Category,Title,Property,Amount"
        ]

        for item in filteredTransactions {
            let date = formatter.string(from: item.date)
            let time = timeFormatter.string(from: item.date)
            let type = item.isIncome ? "Income" : "Expense"
            let amount = String(format: "%.2f", item.amount)
            let row = [
                csvEscape(date),
                csvEscape(time),
                csvEscape(type),
                csvEscape(item.displayCategory),
                csvEscape(item.title),
                csvEscape(item.subtitle),
                amount
            ].joined(separator: ",")
            rows.append(row)
        }

        let csvString = rows.joined(separator: "\n")
        let url = exportFileURL(extension: "csv")
        do {
            try csvString.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            showShareSheet = true
        } catch {
            print("CSV export failed: \(error)")
        }
    }

    private func exportPDF() {
        guard !filteredTransactions.isEmpty else { return }

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            var y: CGFloat = 72
            let left: CGFloat = 40
            let right: CGFloat = pageRect.width - 40

            func drawText(_ text: String, font: UIFont, color: UIColor = .black) {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let attributed = NSAttributedString(string: text, attributes: attributes)
                attributed.draw(at: CGPoint(x: left, y: y))
                y += font.lineHeight + 6
            }

            drawText("Transactions", font: .boldSystemFont(ofSize: 22))
            drawText("Exported \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))", font: .systemFont(ofSize: 11), color: .darkGray)
            y += 6

            let rowFont = UIFont.systemFont(ofSize: 10)

            func drawRow(_ columns: [String], font: UIFont = rowFont) {
                let columnWidths: [CGFloat] = [70, 120, 90, 140, 90]
                var x = left
                for (index, value) in columns.enumerated() {
                    let width = columnWidths[index]
                    let rect = CGRect(x: x, y: y, width: width, height: rowFont.lineHeight + 4)
                    (value as NSString).draw(in: rect, withAttributes: [
                        .font: font,
                        .foregroundColor: UIColor.black
                    ])
                    x += width + 8
                }
                y += rowFont.lineHeight + 8
            }

            let headerColumns = ["Date", "Title", "Category", "Property", "Amount"]
            drawRow(headerColumns.map { $0.uppercased() }, font: .boldSystemFont(ofSize: 11))

            for item in filteredTransactions {
                if y > pageRect.height - 72 {
                    context.beginPage()
                    y = 72
                    drawRow(headerColumns.map { $0.uppercased() }, font: .boldSystemFont(ofSize: 11))
                }

                let date = DateFormatter.localizedString(from: item.date, dateStyle: .short, timeStyle: .none)
                let amount = (item.isIncome ? "+" : "-") + String(format: "$%.2f", item.amount)
                drawRow([date, item.title, item.displayCategory, item.subtitle, amount])
            }
        }

        let url = exportFileURL(extension: "pdf")
        do {
            try data.write(to: url)
            exportURL = url
            showShareSheet = true
        } catch {
            print("PDF export failed: \(error)")
        }
    }

    private func exportFileURL(extension ext: String) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "transactions_\(formatter.string(from: Date())).\(ext)"
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }

    private func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func presentUndo(for deleted: DeletedTransaction) {
        pendingUndo = deleted
        showUndoBanner = true
        let token = UUID()
        undoToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            guard undoToken == token else { return }
            withAnimation {
                showUndoBanner = false
                pendingUndo = nil
            }
        }
    }

    private func handleUndo() async {
        guard let pendingUndo else { return }
        withAnimation {
            showUndoBanner = false
        }

        do {
            switch pendingUndo.kind {
            case .rentPayment:
                if let input = pendingUndo.rentPaymentInput {
                    _ = try await dataService.createRentPayment(input)
                }
            case .expense:
                if let input = pendingUndo.expenseInput {
                    _ = try await dataService.createExpense(input)
                }
            }
            await dataService.loadAllData()
        } catch {
            print("Undo failed: \(error)")
        }
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
        return TransactionItem.prettyCategory(selectedCategory)
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
                        let label = category == "all" ? "All Categories" : TransactionItem.prettyCategory(category)
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
    let onSelect: (TransactionItem) -> Void

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
                TransactionRow(item: item) {
                    onSelect(item)
                }
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
                    let paymentToUndo = paymentForTenant(tenant)
                    TenantRentRow(
                        tenant: tenant,
                        paymentIdToUndo: paymentToUndo?.id,
                        onMarkPaid: {
                            Task {
                                do {
                                    let input = ConvexRentPaymentInput(
                                        propertyId: property.id,
                                        tenantId: tenant.id,
                                        amount: tenant.monthlyRent,
                                        paymentDate: paymentDateForMarkPaid(),
                                        paymentMethod: nil,
                                        status: "completed",
                                        transactionId: nil,
                                        notes: nil
                                    )
                                    _ = try await dataService.createRentPayment(input)
                                    await dataService.loadAllData()
                                    HapticManager.shared.success()
                                } catch {
                                    HapticManager.shared.error()
                                }
                            }
                        },
                        onUndoPaid: { paymentId in
                            Task {
                                do {
                                    try await dataService.deleteRentPayment(id: paymentId)
                                    await dataService.loadAllData()
                                    HapticManager.shared.success()
                                } catch {
                                    HapticManager.shared.error()
                                }
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
        paymentForTenant(tenant) != nil
    }

    private func paymentForTenant(_ tenant: ConvexTenant) -> ConvexRentPayment? {
        payments
            .filter { payment in
                guard payment.tenantId == tenant.id else { return false }
                let date = payment.paymentDateValue
                return date >= monthStart && date < monthEnd
            }
            .sorted { $0.paymentDateValue > $1.paymentDateValue }
            .first
    }

    private func paymentDateForMarkPaid() -> Date {
        let now = Date()
        if now < monthStart { return monthStart }
        if now >= monthEnd {
            return Calendar.current.date(byAdding: .second, value: -1, to: monthEnd) ?? monthStart
        }
        return now
    }
}

struct TenantRentRow: View {
    let tenant: ConvexTenant
    let paymentIdToUndo: String?
    let onMarkPaid: () -> Void
    let onUndoPaid: (String) -> Void

    @State private var showingUndoConfirm = false

    private var isPaid: Bool { paymentIdToUndo != nil }

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
                HStack(spacing: 10) {
                    Label("Paid", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.emerald)

                    Button("Undo") {
                        showingUndoConfirm = true
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
                }
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
        .alert("Undo Payment?", isPresented: $showingUndoConfirm) {
            Button("Undo", role: .destructive) {
                if let id = paymentIdToUndo {
                    onUndoPaid(id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the rent payment record for this tenant for the selected month.")
        }
    }
}

enum TransactionKind {
    case rentPayment
    case expense
}

struct DeletedTransaction {
    let kind: TransactionKind
    let message: String
    let rentPaymentInput: ConvexRentPaymentInput?
    let expenseInput: ConvexExpenseInput?
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
    let kind: TransactionKind
    let tenantId: String?
    let paymentMethod: String?
    let status: String?
    let transactionId: String?
    let notes: String?
    let expenseDescription: String?
    let isRecurring: Bool?
    let recurringFrequency: String?
    let receiptURL: String?
    let vendor: String?

    var displayCategory: String {
        TransactionItem.prettyCategory(category)
    }

    static func prettyCategory(_ raw: String) -> String {
        if raw.isEmpty { return "Other" }
        return raw
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

struct TransactionRow: View {
    let item: TransactionItem
    let onSelect: () -> Void

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    HStack(spacing: 8) {
                        Text(item.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textSecondary)

                        CategoryPill(text: item.displayCategory, isIncome: item.isIncome)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedAmount)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(item.isIncome ? Theme.Colors.emerald : Theme.Colors.alertRed)
                    HStack(spacing: 6) {
                        Text(shortTime(item.date))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.textMuted)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

struct TransactionEditSheet: View {
    let item: TransactionItem
    let onDelete: (DeletedTransaction) -> Void
    @EnvironmentObject var dataService: ConvexDataService
    @Environment(\.dismiss) private var dismiss

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false

    @State private var propertyId: String
    @State private var amount: String
    @State private var date: Date
    @State private var notes: String

    @State private var tenantId: String
    @State private var paymentMethod: String
    @State private var status: String
    @State private var transactionId: String

    @State private var title: String
    @State private var category: String
    @State private var descriptionText: String
    @State private var isRecurring: Bool
    @State private var recurringFrequency: String
    @State private var receiptURL: String
    @State private var vendor: String

    init(item: TransactionItem, onDelete: @escaping (DeletedTransaction) -> Void) {
        self.item = item
        self.onDelete = onDelete
        _propertyId = State(initialValue: item.propertyId ?? "")
        _amount = State(initialValue: String(format: "%.2f", item.amount))
        _date = State(initialValue: item.date)
        _notes = State(initialValue: item.notes ?? "")

        _tenantId = State(initialValue: item.tenantId ?? "")
        _paymentMethod = State(initialValue: item.paymentMethod ?? "")
        _status = State(initialValue: item.status ?? "completed")
        _transactionId = State(initialValue: item.transactionId ?? "")

        _title = State(initialValue: item.title)
        _category = State(initialValue: item.category)
        _descriptionText = State(initialValue: item.expenseDescription ?? "")
        _isRecurring = State(initialValue: item.isRecurring ?? false)
        _recurringFrequency = State(initialValue: item.recurringFrequency ?? "")
        _receiptURL = State(initialValue: item.receiptURL ?? "")
        _vendor = State(initialValue: item.vendor ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.alertRed)
                        }

                        if item.kind == .rentPayment {
                            rentPaymentForm
                        } else {
                            expenseForm
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle(item.kind == .rentPayment ? "Edit Rent Payment" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await handleSave() }
                    }
                    .foregroundColor(Theme.Colors.emerald)
                    .disabled(isSaving)
                }
            }
            .alert("Delete Transaction?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    Task { await handleDelete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You can undo this for a few seconds after deletion.")
            }
        }
    }

    private var rentPaymentForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            if !dataService.properties.isEmpty {
                Picker("Property", selection: $propertyId) {
                    Text("Select Property").tag("")
                    ForEach(dataService.properties) { property in
                        Text(property.name).tag(property.id)
                    }
                }
                .onChange(of: propertyId) { _ in
                    syncTenantSelection()
                }
            }

            if !tenantOptions.isEmpty || !propertyId.isEmpty {
                Picker("Tenant", selection: $tenantId) {
                    Text("No Tenant").tag("")
                    ForEach(tenantOptions) { tenant in
                        Text(tenant.fullName).tag(tenant.id)
                    }
                }
            }

            TextField("Amount", text: $amount)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)

            DatePicker("Payment Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

            TextField("Status", text: $status)
                .textFieldStyle(.roundedBorder)

            TextField("Payment Method", text: $paymentMethod)
                .textFieldStyle(.roundedBorder)

            TextField("Transaction ID", text: $transactionId)
                .textFieldStyle(.roundedBorder)

            TextField("Notes", text: $notes)
                .textFieldStyle(.roundedBorder)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete Transaction")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    private var expenseForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            if !dataService.properties.isEmpty {
                Picker("Property", selection: $propertyId) {
                    Text("No Property").tag("")
                    ForEach(dataService.properties) { property in
                        Text(property.name).tag(property.id)
                    }
                }
            }

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("Category (e.g. maintenance)", text: $category)
                .textFieldStyle(.roundedBorder)

            TextField("Amount", text: $amount)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)

            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

            TextField("Description", text: $descriptionText)
                .textFieldStyle(.roundedBorder)

            TextField("Vendor", text: $vendor)
                .textFieldStyle(.roundedBorder)

            TextField("Receipt URL", text: $receiptURL)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)

            Toggle("Recurring", isOn: $isRecurring)
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.emerald))

            if isRecurring {
                TextField("Recurring Frequency", text: $recurringFrequency)
                    .textFieldStyle(.roundedBorder)
            }

            TextField("Notes", text: $notes)
                .textFieldStyle(.roundedBorder)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete Transaction")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    private var tenantOptions: [ConvexTenant] {
        guard !propertyId.isEmpty else { return [] }
        return dataService.tenants.filter { $0.propertyId == propertyId }
    }

    private func syncTenantSelection() {
        guard item.kind == .rentPayment else { return }
        let validTenantIds = tenantOptions.map { $0.id }
        if !validTenantIds.contains(tenantId) {
            tenantId = ""
        }
    }

    private func handleSave() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        do {
            let amountValue = Double(amount.filter { "0123456789.".contains($0) }) ?? 0

            switch item.kind {
            case .rentPayment:
                guard !propertyId.isEmpty else {
                    throw ConvexError.serverError("Select a property.")
                }

                _ = try await dataService.updateRentPayment(
                    id: item.id,
                    propertyId: propertyId,
                    tenantId: tenantId.isEmpty ? nil : tenantId,
                    clearTenantId: tenantId.isEmpty,
                    amount: amountValue,
                    paymentDate: date,
                    paymentMethod: paymentMethod,
                    status: status.isEmpty ? "completed" : status,
                    transactionId: transactionId,
                    notes: notes
                )

            case .expense:
                guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw ConvexError.serverError("Title is required.")
                }
                let categoryValue = category.trimmingCharacters(in: .whitespacesAndNewlines)
                _ = try await dataService.updateExpense(
                    id: item.id,
                    propertyId: propertyId.isEmpty ? nil : propertyId,
                    clearPropertyId: propertyId.isEmpty,
                    title: title,
                    description: descriptionText,
                    amount: amountValue,
                    category: categoryValue.isEmpty ? "other" : categoryValue,
                    date: date,
                    isRecurring: isRecurring,
                    recurringFrequency: isRecurring ? recurringFrequency : "",
                    receiptURL: receiptURL,
                    vendor: vendor,
                    notes: notes
                )
            }

            await dataService.loadAllData()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func handleDelete() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        do {
            let deleted = deletedTransactionSnapshot()

            switch item.kind {
            case .rentPayment:
                try await dataService.deleteRentPayment(id: item.id)
            case .expense:
                try await dataService.deleteExpense(id: item.id)
            }

            await dataService.loadAllData()
            onDelete(deleted)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    private func deletedTransactionSnapshot() -> DeletedTransaction {
        switch item.kind {
        case .rentPayment:
            let input: ConvexRentPaymentInput? = {
                guard let propertyId = item.propertyId, !propertyId.isEmpty else { return nil }
                return ConvexRentPaymentInput(
                    propertyId: propertyId,
                    tenantId: item.tenantId,
                    amount: item.amount,
                    paymentDate: item.date,
                    paymentMethod: item.paymentMethod,
                    status: item.status ?? "completed",
                    transactionId: item.transactionId,
                    notes: item.notes
                )
            }()
            let message = "Rent payment deleted"
            return DeletedTransaction(
                kind: .rentPayment,
                message: message,
                rentPaymentInput: input,
                expenseInput: nil
            )
        case .expense:
            let input = ConvexExpenseInput(
                propertyId: item.propertyId,
                title: item.title,
                description: item.expenseDescription,
                amount: item.amount,
                category: item.category,
                date: item.date,
                isRecurring: item.isRecurring ?? false,
                recurringFrequency: item.recurringFrequency,
                receiptURL: item.receiptURL,
                vendor: item.vendor,
                notes: item.notes
            )
            let message = "Expense deleted"
            return DeletedTransaction(
                kind: .expense,
                message: message,
                rentPaymentInput: nil,
                expenseInput: input
            )
        }
    }
}

struct BusinessFeeSheet: View {
    @EnvironmentObject var dataService: ConvexDataService
    @Environment(\.dismiss) private var dismiss
    let onSave: (ConvexExpenseInput) -> Void

    @State private var propertyId: String = ""
    @State private var description: String = ""
    @State private var amount: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.alertRed)
                        }

                        if !dataService.properties.isEmpty {
                            Picker("Property", selection: $propertyId) {
                                Text("No Property").tag("")
                                ForEach(dataService.properties) { property in
                                    Text(property.name).tag(property.id)
                                }
                            }
                        }

                        TextField("Description", text: $description)
                            .textFieldStyle(.roundedBorder)

                        TextField("Amount", text: $amount)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)

                        DatePicker("Date", selection: $date, displayedComponents: .date)

                        TextField("Note (optional)", text: $notes)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("Business Fee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { handleSave() }
                        .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
    }

    private func handleSave() {
        errorMessage = nil
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Description is required."
            return
        }
        let amountValue = Double(amount.filter { "0123456789.".contains($0) }) ?? 0
        let input = ConvexExpenseInput(
            propertyId: propertyId.isEmpty ? nil : propertyId,
            title: trimmed,
            description: nil,
            amount: amountValue,
            category: "business",
            date: date,
            isRecurring: false,
            recurringFrequency: nil,
            receiptURL: nil,
            vendor: nil,
            notes: notes.isEmpty ? nil : notes
        )
        onSave(input)
    }
}

struct UndoBanner: View {
    let message: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
            Spacer()
            Button("Undo") { onUndo() }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.Colors.emerald)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate900)
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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

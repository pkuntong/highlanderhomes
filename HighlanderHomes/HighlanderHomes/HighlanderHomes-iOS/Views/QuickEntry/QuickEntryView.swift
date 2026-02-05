import SwiftUI
import SwiftData

/// The "Spreadsheet Killer" - Fast data entry that feels like Excel but looks premium
struct QuickEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var dataService: ConvexDataService

    @State private var entryMode: EntryMode = .expense
    @State private var entries: [QuickEntryRow] = []
    @State private var isAddingRow = false
    @State private var saveMessage: String?
    @State private var errorMessage: String?
    @State private var selectedPropertyId: String = ""
    @State private var selectedTenantId: String = ""
    @FocusState private var focusedField: FocusedField?

    enum EntryMode: String, CaseIterable {
        case expense = "Expense"
        case income = "Income"
        case maintenance = "Maintenance"

        var icon: String {
            switch self {
            case .expense: return "arrow.up.circle.fill"
            case .income: return "arrow.down.circle.fill"
            case .maintenance: return "wrench.fill"
            }
        }

        var color: Color {
            switch self {
            case .expense: return Theme.Colors.alertRed
            case .income: return Theme.Colors.emerald
            case .maintenance: return Theme.Colors.warningAmber
            }
        }
    }

    enum FocusedField: Hashable {
        case description(Int)
        case amount(Int)
        case category(Int)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Mode Selector
                    EntryModeSelector(selectedMode: $entryMode)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.sm)

                    if entryMode == .income || entryMode == .expense {
                        VStack(spacing: Theme.Spacing.sm) {
                            Picker("Property", selection: $selectedPropertyId) {
                                Text(entryMode == .income ? "Select Property" : "None")
                                    .tag("")
                                ForEach(dataService.properties, id: \.id) { property in
                                    Text(property.name).tag(property.id)
                                }
                            }

                            if entryMode == .income {
                                Picker("Tenant (Optional)", selection: $selectedTenantId) {
                                    Text("None").tag("")
                                    ForEach(dataService.tenants.filter { $0.propertyId == selectedPropertyId }, id: \.id) { tenant in
                                        Text(tenant.fullName).tag(tenant.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.sm)
                    }

                    // Column Headers
                    ColumnHeaders(mode: entryMode)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.md)

                    // Entry Grid
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                QuickEntryRowView(
                                    entry: $entries[index],
                                    rowIndex: index,
                                    focusedField: $focusedField,
                                    onDelete: { deleteRow(at: index) }
                                )
                            }

                            // Add Row Button
                            AddRowButton {
                                addNewRow()
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.xxl)
                    }

                    // Bottom Action Bar
                    QuickEntryActionBar(
                        entryCount: entries.count,
                        totalAmount: totalAmount,
                        onSave: saveEntries,
                        onClear: clearEntries
                    )
                }
            }
            .navigationTitle("Quick Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.slate400)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveEntries()
                        HapticManager.shared.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.emerald)
                    .disabled(entries.isEmpty)
                }

                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Button("Previous") {
                            moveToPreviousField()
                        }
                        .disabled(!canMovePrevious)

                        Spacer()

                        Button("Next") {
                            moveToNextField()
                        }
                        .disabled(!canMoveNext)

                        Spacer()

                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .onAppear {
                // Start with one empty row
                if entries.isEmpty {
                    addNewRow()
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let message = saveMessage {
                Text(message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule().fill(Theme.Colors.slate800.opacity(0.9))
                    }
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        Capsule().fill(Theme.Colors.alertRed.opacity(0.9))
                    }
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Computed Properties
    private var totalAmount: Double {
        entries.reduce(0) { $0 + ($1.amount ?? 0) }
    }

    private var canMovePrevious: Bool {
        guard let focused = focusedField else { return false }
        switch focused {
        case .description(let index):
            return index > 0
        case .amount(let index):
            return true
        case .category:
            return true
        }
    }

    private var canMoveNext: Bool {
        guard let focused = focusedField else { return false }
        switch focused {
        case .description(let index):
            return true
        case .amount(let index):
            return index < entries.count - 1 || !entries.isEmpty
        case .category(let index):
            return index < entries.count - 1
        }
    }

    // MARK: - Actions
    private func addNewRow() {
        let newRow = QuickEntryRow()
        entries.append(newRow)
        HapticManager.shared.impact(.light)

        // Focus the description field of the new row
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedField = .description(entries.count - 1)
        }
    }

    private func deleteRow(at index: Int) {
        HapticManager.shared.impact(.medium)
        withAnimation(.spring(response: 0.3)) {
            entries.remove(at: index)
        }
    }

    private func saveEntries() {
        saveMessage = nil
        errorMessage = nil

        guard !entries.isEmpty else { return }

        switch entryMode {
        case .income:
            guard !selectedPropertyId.isEmpty else {
                withAnimation { errorMessage = "Select a property first." }
                return
            }
        default:
            break
        }

        Task {
            do {
                var savedCount = 0
                for entry in entries where entry.isValid {
                    switch entryMode {
                    case .expense, .maintenance:
                        let category = entryMode == .maintenance ? "maintenance" : (entry.category?.rawValue.lowercased() ?? "other")
                        let input = ConvexExpenseInput(
                            propertyId: selectedPropertyId.isEmpty ? nil : selectedPropertyId,
                            title: entry.description,
                            description: nil,
                            amount: entry.amount ?? 0,
                            category: category,
                            date: entry.date,
                            isRecurring: false,
                            recurringFrequency: nil,
                            receiptURL: nil,
                            vendor: nil,
                            notes: nil
                        )
                        _ = try await dataService.createExpense(input)
                        savedCount += 1

                    case .income:
                        let input = ConvexRentPaymentInput(
                            propertyId: selectedPropertyId,
                            tenantId: selectedTenantId.isEmpty ? nil : selectedTenantId,
                            amount: entry.amount ?? 0,
                            paymentDate: entry.date,
                            paymentMethod: nil,
                            status: "completed",
                            transactionId: nil,
                            notes: nil
                        )
                        _ = try await dataService.createRentPayment(input)
                        savedCount += 1
                    }
                }

                withAnimation {
                    saveMessage = "Saved \(savedCount) entries"
                }
                HapticManager.shared.reward()
            } catch {
                withAnimation {
                    errorMessage = "Save failed: \(error.localizedDescription)"
                }
                HapticManager.shared.error()
            }
        }
    }

    private func clearEntries() {
        HapticManager.shared.impact(.medium)
        withAnimation(.spring(response: 0.3)) {
            entries.removeAll()
            addNewRow()
        }
        saveMessage = nil
        errorMessage = nil
    }

    private func moveToPreviousField() {
        guard let focused = focusedField else { return }
        HapticManager.shared.selection()

        switch focused {
        case .description(let index):
            if index > 0 {
                focusedField = .amount(index - 1)
            }
        case .amount(let index):
            focusedField = .description(index)
        case .category(let index):
            focusedField = .amount(index)
        }
    }

    private func moveToNextField() {
        guard let focused = focusedField else { return }
        HapticManager.shared.selection()

        switch focused {
        case .description(let index):
            focusedField = .amount(index)
        case .amount(let index):
            if index < entries.count - 1 {
                focusedField = .description(index + 1)
            } else {
                addNewRow()
            }
        case .category(let index):
            if index < entries.count - 1 {
                focusedField = .description(index + 1)
            }
        }
    }
}

// MARK: - Quick Entry Row Model
struct QuickEntryRow: Identifiable {
    let id = UUID()
    var description: String = ""
    var amount: Double?
    var category: Expense.ExpenseCategory?
    var date: Date = Date()

    var isValid: Bool {
        !description.isEmpty && amount != nil && amount! > 0
    }
}

// MARK: - Entry Mode Selector
struct EntryModeSelector: View {
    @Binding var selectedMode: QuickEntryView.EntryMode
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(QuickEntryView.EntryMode.allCases, id: \.self) { mode in
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14))
                        Text(mode.rawValue)
                            .font(.system(size: 14, weight: selectedMode == mode ? .semibold : .medium))
                    }
                    .foregroundColor(selectedMode == mode ? .white : Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selectedMode == mode {
                            Capsule()
                                .fill(mode.color)
                                .matchedGeometryEffect(id: "entryMode", in: animation)
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

// MARK: - Column Headers
struct ColumnHeaders: View {
    let mode: QuickEntryView.EntryMode

    var body: some View {
        HStack(spacing: 8) {
            Text("Description")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Amount")
                .frame(width: 100, alignment: .trailing)

            Text("Category")
                .frame(width: 80, alignment: .center)

            // Delete column spacer
            Color.clear
                .frame(width: 32)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(Theme.Colors.textMuted)
        .textCase(.uppercase)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Quick Entry Row View
struct QuickEntryRowView: View {
    @Binding var entry: QuickEntryRow
    let rowIndex: Int
    var focusedField: FocusState<QuickEntryView.FocusedField?>.Binding
    let onDelete: () -> Void

    @State private var amountText: String = ""
    @State private var showCategoryPicker = false

    var body: some View {
        HStack(spacing: 8) {
            // Description Field
            TextField("Item description", text: $entry.description)
                .font(.system(size: 15))
                .foregroundColor(Theme.Colors.textPrimary)
                .focused(focusedField, equals: .description(rowIndex))
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.Colors.slate800)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isDescriptionFocused ? Theme.Colors.emerald : Theme.Colors.slate700,
                                    lineWidth: 1
                                )
                        }
                }
                .frame(maxWidth: .infinity)

            // Amount Field
            HStack(spacing: 4) {
                Text("$")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textMuted)

                TextField("0.00", text: $amountText)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: .amount(rowIndex))
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: amountText) { _, newValue in
                        entry.amount = Double(newValue.replacingOccurrences(of: ",", with: ""))
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: 100)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.Colors.slate800)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isAmountFocused ? Theme.Colors.emerald : Theme.Colors.slate700,
                                lineWidth: 1
                            )
                    }
            }

            // Category Button
            Button {
                HapticManager.shared.impact(.light)
                showCategoryPicker.toggle()
            } label: {
                HStack(spacing: 4) {
                    if let category = entry.category {
                        Image(systemName: category.icon)
                            .font(.system(size: 14))
                    } else {
                        Image(systemName: "tag")
                            .font(.system(size: 14))
                    }
                }
                .foregroundColor(entry.category != nil ? Theme.Colors.emerald : Theme.Colors.textMuted)
                .frame(width: 80)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.Colors.slate800)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.Colors.slate700, lineWidth: 1)
                        }
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerSheet(selectedCategory: $entry.category)
                    .presentationDetents([.medium])
            }

            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.slate500)
            }
            .frame(width: 32)
        }
        .padding(.vertical, 4)
    }

    private var isDescriptionFocused: Bool {
        if case .description(let index) = focusedField.wrappedValue {
            return index == rowIndex
        }
        return false
    }

    private var isAmountFocused: Bool {
        if case .amount(let index) = focusedField.wrappedValue {
            return index == rowIndex
        }
        return false
    }
}

// MARK: - Add Row Button
struct AddRowButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text("Add Row")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(Theme.Colors.emerald)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.Colors.emerald.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }
}

// MARK: - Quick Entry Action Bar
struct QuickEntryActionBar: View {
    let entryCount: Int
    let totalAmount: Double
    let onSave: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Theme.Colors.slate700)

            HStack {
                // Stats
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entryCount) entries")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text("$\(totalAmount, specifier: "%.2f")")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.Colors.textPrimary)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: onClear) {
                        Text("Clear")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.slate400)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background {
                                Capsule()
                                    .fill(Theme.Colors.slate800)
                            }
                    }

                    Button(action: onSave) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("Save All")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background {
                            Capsule()
                                .fill(Theme.Gradients.emeraldGlow)
                        }
                    }
                    .disabled(entryCount == 0)
                    .opacity(entryCount == 0 ? 0.5 : 1)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.slate900)
        }
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    @Binding var selectedCategory: Expense.ExpenseCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Expense.ExpenseCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                HapticManager.shared.selection()
                                selectedCategory = category
                                dismiss()
                            }
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("Category")
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

struct CategoryButton: View {
    let category: Expense.ExpenseCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Theme.Colors.emerald : Theme.Colors.textSecondary)

                Text(category.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.Colors.emerald.opacity(0.15) : Theme.Colors.slate800)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Theme.Colors.emerald : Theme.Colors.slate700, lineWidth: 1)
                    }
            }
        }
    }
}

#Preview {
    QuickEntryView()
        .modelContainer(for: Expense.self, inMemory: true)
}

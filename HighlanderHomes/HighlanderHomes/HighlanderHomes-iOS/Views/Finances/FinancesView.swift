import SwiftUI

/// FinancesView wraps the existing TransactionsView functionality
/// with the new 4-tab navigation structure.
/// The existing TransactionsView already has comprehensive filtering,
/// grouping, export, and editing — we reuse it directly.
struct FinancesView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @EnvironmentObject var appState: AppState

    @State private var showingAddPayment = false
    @State private var showingAddExpense = false
    @State private var showingSettings = false

    var body: some View {
        // Reuse the existing TransactionsView which already has:
        // - Transaction summary card (income/expenses/net)
        // - Property rent status disclosure
        // - Date range filtering
        // - Transaction grouping by date
        // - Edit/delete with undo
        // - CSV/PDF export
        // - Business fee entry
        // - .refreshable
        TransactionsView()
    }
}

#Preview {
    FinancesView()
        .environmentObject(AppState())
        .environmentObject(ConvexDataService.shared)
        .environmentObject(ConvexAuth.shared)
}

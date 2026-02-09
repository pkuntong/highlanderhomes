import SwiftUI

/// MaintenanceListView wraps the existing TriageHubView functionality
/// with the new naming convention. The TriageHubView already has:
/// - Active requests listing
/// - Status filter pills (New, Acknowledged, Scheduled, In Progress)
/// - Request detail sheets with workflow
/// - New request creation
/// - .refreshable
///
/// The contextual "+" button is already in the Triage header.
struct MaintenanceListView: View {
    var body: some View {
        TriageHubView()
    }
}

#Preview {
    MaintenanceListView()
        .environmentObject(AppState())
        .environmentObject(ConvexDataService.shared)
        .environmentObject(ConvexAuth.shared)
}

import SwiftUI
import SwiftData

struct TriageHubView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @EnvironmentObject var appState: AppState

    private enum ViewMode: String {
        case active
        case history
    }

    @State private var selectedRequest: ConvexMaintenanceRequest?
    @State private var showingNewRequest = false
    @State private var filterStatus: String?
    @State private var viewMode: ViewMode = .active

    private var activeRequests: [ConvexMaintenanceRequest] {
        dataService.maintenanceRequests.filter {
            $0.status != "completed" && $0.status != "cancelled"
        }
    }

    private var historyRequests: [ConvexMaintenanceRequest] {
        dataService.maintenanceRequests.filter {
            $0.status == "completed" || $0.status == "cancelled"
        }
    }

    private var headerCountText: String {
        switch viewMode {
        case .active:
            return "\(activeRequests.count) active requests"
        case .history:
            return "\(historyRequests.count) past requests"
        }
    }

    private var filterStatuses: [(key: String, label: String)] {
        switch viewMode {
        case .active:
            return [
                ("new", "New"),
                ("acknowledged", "Acknowledged"),
                ("scheduled", "Scheduled"),
                ("inProgress", "In Progress"),
                ("awaitingParts", "Awaiting Parts"),
            ]
        case .history:
            return [
                ("completed", "Completed"),
                ("cancelled", "Cancelled"),
            ]
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    TriageHeader(
                        countText: headerCountText,
                        showingNewRequest: $showingNewRequest
                    )

                    // Active / History toggle
                    HStack(spacing: 10) {
                        FilterPill(
                            label: "Active",
                            isSelected: viewMode == .active,
                            color: Theme.Colors.emerald
                        ) {
                            viewMode = .active
                            filterStatus = nil
                        }

                        FilterPill(
                            label: "History",
                            isSelected: viewMode == .history,
                            color: Theme.Colors.slate600
                        ) {
                            viewMode = .history
                            filterStatus = nil
                        }

                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.xs)

                    // Status Filter Pills
                    ConvexStatusFilterBar(selectedStatus: $filterStatus, statuses: filterStatuses)
                        .padding(.vertical, Theme.Spacing.sm)

                    // Loading indicator
                    if dataService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.emerald))
                            .padding()
                    }

                    // Requests List
                    if filteredRequests.isEmpty && !dataService.isLoading {
                        EmptyTriageView(isHistory: viewMode == .history)
                    } else if !filteredRequests.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.md) {
                                ForEach(filteredRequests) { request in
                                    ConvexTriageRequestCard(request: request)
                                        .onTapGesture {
                                            HapticManager.shared.impact(.light)
                                            selectedRequest = request
                                        }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.bottom, 120)
                        }
                    }
                }
            }
            .sheet(item: $selectedRequest) { request in
                ConvexTriageDetailView(requestId: request.id)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingNewRequest) {
                NewMaintenanceRequestView()
                    .presentationDetents([.large])
            }
            .onChange(of: selectedRequest?.id) { newValue in
                appState.isModalPresented = newValue != nil || showingNewRequest
            }
            .onChange(of: showingNewRequest) { newValue in
                appState.isModalPresented = newValue || selectedRequest != nil
            }
        }
        .refreshable {
            await dataService.loadAllData()
        }
    }

    private var filteredRequests: [ConvexMaintenanceRequest] {
        let base: [ConvexMaintenanceRequest]
        switch viewMode {
        case .active:
            base = activeRequests
        case .history:
            base = historyRequests
        }

        if let status = filterStatus {
            return base.filter { $0.status == status }
        }
        return base
    }
}

// MARK: - Triage Header
struct TriageHeader: View {
    let countText: String
    @Binding var showingNewRequest: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Triage")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(countText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            Button {
                HapticManager.shared.impact(.medium)
                showingNewRequest = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Gradients.emeraldGlow)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Convex Status Filter Bar
struct ConvexStatusFilterBar: View {
    @Binding var selectedStatus: String?
    let statuses: [(key: String, label: String)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All filter
                FilterPill(
                    label: "All",
                    isSelected: selectedStatus == nil,
                    color: Theme.Colors.emerald
                ) {
                    selectedStatus = nil
                }

                ForEach(statuses, id: \.key) { status in
                    FilterPill(
                        label: status.label,
                        isSelected: selectedStatus == status.key,
                        color: statusColor(for: status.key)
                    ) {
                        selectedStatus = status.key
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "new": return Theme.Colors.alertRed
        case "acknowledged": return Theme.Colors.warningAmber
        case "scheduled": return Theme.Colors.infoBlue
        case "inProgress": return Theme.Colors.emerald
        default: return Theme.Colors.slate500
        }
    }
}

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(isSelected ? color : Theme.Colors.slate800)
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? color : Theme.Colors.slate700, lineWidth: 1)
                }
        }
    }
}

// MARK: - Convex Triage Request Card
struct ConvexTriageRequestCard: View {
    let request: ConvexMaintenanceRequest
    @State private var showQuickActions = false

    private var categoryIcon: String {
        switch request.category.lowercased() {
        case "plumbing": return "drop.fill"
        case "electrical": return "bolt.fill"
        case "hvac": return "thermometer.medium"
        case "appliance": return "washer.fill"
        case "structural": return "building.2.fill"
        case "landscaping": return "leaf.fill"
        default: return "wrench.fill"
        }
    }

    private var priorityColor: Color {
        switch request.priority {
        case "emergency", "urgent": return Theme.Colors.alertRed
        case "high": return Theme.Colors.warningAmber
        case "normal": return Theme.Colors.infoBlue
        case "low": return Theme.Colors.slate400
        default: return Theme.Colors.slate400
        }
    }

    private var ageInDays: Int {
        let days = Calendar.current.dateComponents([.day], from: request.createdAtDate, to: Date()).day ?? 0
        return max(0, days)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Top Row
            HStack(alignment: .top) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(priorityColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: categoryIcon)
                        .font(.system(size: 20))
                        .foregroundColor(priorityColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    Text(request.category)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()

                // Status Badge
                ConvexStatusBadge(status: request.status)
            }

            // Description
            if let description = request.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.textMuted)
                    .lineLimit(2)
            }

            // Bottom Row
            HStack {
                // Time ago
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text("\(ageInDays)d ago")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Theme.Colors.textMuted)

                Spacer()

                // Quick Action Buttons
                HStack(spacing: 8) {
                    QuickActionButton(
                        icon: "person.badge.plus",
                        label: "Assign",
                        color: Theme.Colors.infoBlue
                    ) {
                        assignContractor()
                    }

                    QuickActionButton(
                        icon: "bubble.left.fill",
                        label: "Message",
                        color: Theme.Colors.emerald
                    ) {
                        sendMessage()
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Colors.slate800.opacity(0.7))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(
                            request.isUrgent ? Theme.Colors.alertRed.opacity(0.5) : Theme.Colors.slate700.opacity(0.5),
                            lineWidth: request.isUrgent ? 2 : 1
                        )
                }
        }
        .pulseAnimation(isActive: request.priority == "emergency", color: Theme.Colors.alertRed)
    }

    private func assignContractor() {
        HapticManager.shared.impact(.medium)
        // Navigate to contractor assignment
    }

    private func sendMessage() {
        HapticManager.shared.impact(.light)
        // Open messaging
    }
}

// MARK: - Convex Status Badge
struct ConvexStatusBadge: View {
    let status: String

    private var statusLabel: String {
        switch status {
        case "new": return "New"
        case "acknowledged": return "Acknowledged"
        case "scheduled": return "Scheduled"
        case "inProgress": return "In Progress"
        case "awaitingParts": return "Awaiting Parts"
        case "completed": return "Completed"
        case "cancelled": return "Cancelled"
        default: return status.capitalized
        }
    }

    private var statusIcon: String {
        switch status {
        case "new": return "exclamationmark.circle.fill"
        case "acknowledged": return "checkmark.circle.fill"
        case "scheduled": return "calendar"
        case "inProgress": return "wrench.fill"
        case "awaitingParts": return "clock.fill"
        case "completed": return "checkmark.seal.fill"
        case "cancelled": return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 10))
            Text(statusLabel)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(statusColor.opacity(0.15))
        }
    }

    private var statusColor: Color {
        switch status {
        case "new": return Theme.Colors.alertRed
        case "acknowledged": return Theme.Colors.warningAmber
        case "scheduled": return Theme.Colors.infoBlue
        case "inProgress": return Color.cyan
        case "awaitingParts": return Color.purple
        case "completed": return Theme.Colors.emerald
        case "cancelled": return Theme.Colors.slate500
        default: return Theme.Colors.slate400
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(color.opacity(0.15))
            }
        }
    }
}

// MARK: - Empty Triage View
struct EmptyTriageView: View {
    let isHistory: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: isHistory ? "clock.arrow.circlepath" : "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.Gradients.emeraldGlow)

            Text(isHistory ? "No History Yet" : "All Clear!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)

            Text(isHistory ? "Completed requests will show up here for easy reference." : "No active maintenance requests.\nYour properties are running smoothly.")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }
}

// MARK: - Convex Triage Detail View
struct ConvexTriageDetailView: View {
    let requestId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    private var request: ConvexMaintenanceRequest? {
        dataService.maintenanceRequests.first { $0.id == requestId }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                if let request {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                            // Header Card
                            ConvexDetailHeaderCard(request: request)

                            // Workflow Steps
                            ConvexTriageWorkflowView(requestId: requestId)

                            // Communication Timeline
                            ConvexCommunicationTimeline(request: request)
                        }
                        .padding(Theme.Spacing.md)
                    }
                } else {
                    VStack(spacing: Theme.Spacing.md) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.Colors.warningAmber)
                        Text("Request not found")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        Text("It may have been removed or is still syncing.")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.textSecondary)
                        Spacer()
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle(request?.title ?? "Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
    }
}

// MARK: - Convex Detail Header Card
struct ConvexDetailHeaderCard: View {
    let request: ConvexMaintenanceRequest

    private var categoryIcon: String {
        switch request.category.lowercased() {
        case "plumbing": return "drop.fill"
        case "electrical": return "bolt.fill"
        case "hvac": return "thermometer.medium"
        case "appliance": return "washer.fill"
        case "structural": return "building.2.fill"
        case "landscaping": return "leaf.fill"
        default: return "wrench.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.alertRed.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: categoryIcon)
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.alertRed)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.category)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text(request.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                }

                Spacer()
            }

            if let description = request.description {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            HStack {
                ConvexPriorityBadge(priority: request.isUrgent ? 3 : 2)
                Spacer()
                ConvexStatusBadge(status: request.status)
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }
}

// MARK: - Convex Triage Workflow View (3-way communication hub)
struct ConvexTriageWorkflowView: View {
    let requestId: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    @State private var showingContractorPicker = false
    @State private var isWorking = false
    @State private var errorMessage: String?

    private var request: ConvexMaintenanceRequest? {
        dataService.maintenanceRequests.first { $0.id == requestId }
    }

    private var isAssigned: Bool { request?.contractorId != nil }
    private var isScheduled: Bool {
        guard let status = request?.status else { return false }
        return ["scheduled", "inProgress", "awaitingParts", "completed"].contains(status)
    }
    private var isTenantNotified: Bool {
        guard let status = request?.status else { return false }
        return ["inProgress", "awaitingParts", "completed"].contains(status)
    }
    private var isCompleted: Bool { request?.status == "completed" }
    private var isCancelled: Bool { request?.status == "cancelled" }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Workflow")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)

            if let request {
                VStack(spacing: 0) {
                    WorkflowStep(
                        step: 1,
                        title: "Request Received",
                        subtitle: "Tenant submitted maintenance request",
                        icon: "bell.badge.fill",
                        isCompleted: true,
                        isCurrent: false
                    )

                    WorkflowConnector(isCompleted: true)

                    WorkflowStep(
                        step: 2,
                        title: "Send to Contractor",
                        subtitle: "Assign and notify a contractor",
                        icon: "arrow.right.circle.fill",
                        isCompleted: isAssigned,
                        isCurrent: !isAssigned && !isCompleted && !isCancelled,
                        actionLabel: (!isAssigned && !isCompleted && !isCancelled) ? "Assign Now" : nil
                    ) {
                        showingContractorPicker = true
                    }

                    WorkflowConnector(isCompleted: isAssigned)

                    WorkflowStep(
                        step: 3,
                        title: "Contractor Schedules",
                        subtitle: "Confirm appointment time",
                        icon: "calendar.badge.clock",
                        isCompleted: isScheduled,
                        isCurrent: isAssigned && !isScheduled && !isCompleted && !isCancelled,
                        actionLabel: (isAssigned && !isScheduled && !isCompleted && !isCancelled) ? "Mark Scheduled" : nil
                    ) {
                        Task { await markScheduled(requestId: request.id) }
                    }

                    WorkflowConnector(isCompleted: isScheduled)

                    WorkflowStep(
                        step: 4,
                        title: "Tenant Notified",
                        subtitle: "Update sent to tenant",
                        icon: "person.fill.checkmark",
                        isCompleted: isTenantNotified,
                        isCurrent: isScheduled && !isTenantNotified && !isCompleted && !isCancelled,
                        actionLabel: (isScheduled && !isTenantNotified && !isCompleted && !isCancelled) ? "Notify Tenant" : nil
                    ) {
                        Task { await notifyTenant(requestId: request.id) }
                    }

                    WorkflowConnector(isCompleted: isTenantNotified)

                    WorkflowStep(
                        step: 5,
                        title: isCancelled ? "Cancelled" : "Completed",
                        subtitle: isCancelled ? "Request was cancelled" : "Mark the work as complete",
                        icon: isCancelled ? "xmark.circle.fill" : "checkmark.seal.fill",
                        isCompleted: isCompleted || isCancelled,
                        isCurrent: isTenantNotified && !isCompleted && !isCancelled,
                        actionLabel: (isTenantNotified && !isCompleted && !isCancelled) ? "Mark Complete" : nil
                    ) {
                        Task { await markComplete(requestId: request.id) }
                    }
                }
            } else {
                Text("Workflow unavailable while syncing.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textMuted)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.alertRed)
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
        .sheet(isPresented: $showingContractorPicker) {
            ContractorPickerSheet(
                contractors: dataService.contractors,
                onSelect: { contractor in
                    Task { await assignContractor(contractor, requestId: requestId) }
                }
            )
        }
    }

    private func assignContractor(_ contractor: ConvexContractor, requestId: String) async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        do {
            try await dataService.assignContractor(requestId: requestId, contractorId: contractor.id)
            await dataService.loadAllData()
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
        isWorking = false
    }

    private func markScheduled(requestId: String) async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        do {
            try await dataService.updateMaintenanceStatus(id: requestId, status: "scheduled")
            await dataService.loadAllData()
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
        isWorking = false
    }

    private func notifyTenant(requestId: String) async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        do {
            try await dataService.updateMaintenanceStatus(id: requestId, status: "inProgress")
            await dataService.loadAllData()
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
        isWorking = false
    }

    private func markComplete(requestId: String) async {
        guard !isWorking else { return }
        isWorking = true
        errorMessage = nil
        do {
            try await dataService.updateMaintenanceStatus(id: requestId, status: "completed")
            await dataService.loadAllData()
            HapticManager.shared.success()

            // Immediately return to the list so the completed item disappears from Active.
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
        isWorking = false
    }
}

struct WorkflowStep: View {
    let step: Int
    let title: String
    let subtitle: String
    let icon: String
    let isCompleted: Bool
    let isCurrent: Bool
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 44, height: 44)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isCurrent ? .white : Theme.Colors.slate500)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isCompleted || isCurrent ? Theme.Colors.textPrimary : Theme.Colors.textMuted)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(Theme.Gradients.emeraldGlow)
                        }
                }
                .buttonStyle(.haptic(.medium))
            }
        }
    }

    private var circleColor: Color {
        if isCompleted {
            return Theme.Colors.emerald
        } else if isCurrent {
            return Theme.Colors.infoBlue
        } else {
            return Theme.Colors.slate700
        }
    }
}

struct WorkflowConnector: View {
    let isCompleted: Bool

    var body: some View {
        HStack {
            Rectangle()
                .fill(isCompleted ? Theme.Colors.emerald : Theme.Colors.slate700)
                .frame(width: 2, height: 24)
                .padding(.leading, 21)
            Spacer()
        }
    }
}

struct ContractorPickerSheet: View {
    let contractors: [ConvexContractor]
    let onSelect: (ConvexContractor) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [ConvexContractor] {
        if searchText.isEmpty { return contractors }
        return contractors.filter {
            $0.companyName.localizedCaseInsensitiveContains(searchText) ||
            $0.contactName.localizedCaseInsensitiveContains(searchText) ||
            $0.specialtyDisplay.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    SearchBar(text: $searchText)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.sm)

                    if filtered.isEmpty {
                        EmptyStateView(
                            title: "No Contractors",
                            subtitle: "Add contractors in the Vault first.",
                            icon: "wrench.and.screwdriver.fill"
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.sm) {
                                ForEach(filtered) { contractor in
                                    ContractorRow(contractor: contractor) {
                                        onSelect(contractor)
                                        dismiss()
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("Assign Contractor")
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

// MARK: - Convex Communication Timeline (Placeholder)
struct ConvexCommunicationTimeline: View {
    let request: ConvexMaintenanceRequest

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Communication")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)

            // Quick contact buttons
            HStack(spacing: Theme.Spacing.md) {
                ContactButton(
                    icon: "person.fill",
                    label: "Tenant",
                    color: Theme.Colors.emerald
                )

                ContactButton(
                    icon: "wrench.fill",
                    label: "Contractor",
                    color: Theme.Colors.infoBlue
                )

                ContactButton(
                    icon: "phone.fill",
                    label: "Call",
                    color: Theme.Colors.warningAmber
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }
}

struct ContactButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        Button {
            HapticManager.shared.impact(.medium)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - New Maintenance Request View
struct NewMaintenanceRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    @State private var propertyId: String = ""
    @State private var tenantId: String = ""
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var category: String = "plumbing"
    @State private var priority: String = "normal"
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let categories = [
        "plumbing",
        "electrical",
        "hvac",
        "appliance",
        "structural",
        "landscaping",
        "other"
    ]

    private let priorities = [
        "low",
        "normal",
        "high",
        "urgent",
        "emergency"
    ]

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

                        if dataService.properties.isEmpty {
                            Text("Add a property first to create a maintenance request.")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.textSecondary)
                        } else {
                            Picker("Property", selection: $propertyId) {
                                Text("Select Property").tag("")
                                ForEach(dataService.properties) { property in
                                    Text(property.name).tag(property.id)
                                }
                            }
                            .onChange(of: propertyId) { _ in
                                syncTenantSelection()
                            }

                            if !tenantOptions.isEmpty || !propertyId.isEmpty {
                                Picker("Tenant", selection: $tenantId) {
                                    Text("No Tenant").tag("")
                                    ForEach(tenantOptions) { tenant in
                                        Text(tenant.fullName).tag(tenant.id)
                                    }
                                }
                            }
                        }

                        TextField("Issue Title", text: $title)
                            .textFieldStyle(.roundedBorder)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.Colors.textSecondary)
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $descriptionText)
                                    .frame(minHeight: 120)
                                    .padding(8)
                                    .background {
                                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                                            .fill(Theme.Colors.slate800)
                                    }

                                if descriptionText.isEmpty {
                                    Text("Describe the issue...")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.textMuted)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 16)
                                }
                            }
                        }

                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { item in
                                Text(item.capitalized).tag(item)
                            }
                        }

                        Picker("Priority", selection: $priority) {
                            ForEach(priorities, id: \.self) { item in
                                Text(item.capitalized).tag(item)
                            }
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await handleSave() }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.emerald)
                    .disabled(!canSave || isSaving)
                }
            }
        }
        .onAppear {
            if propertyId.isEmpty, let first = dataService.properties.first {
                propertyId = first.id
            }
        }
    }

    private var tenantOptions: [ConvexTenant] {
        guard !propertyId.isEmpty else { return [] }
        return dataService.tenants.filter { $0.propertyId == propertyId }
    }

    private var canSave: Bool {
        !propertyId.isEmpty &&
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func syncTenantSelection() {
        let validTenantIds = tenantOptions.map { $0.id }
        if !validTenantIds.contains(tenantId) {
            tenantId = ""
        }
    }

    private func handleSave() async {
        guard !isSaving else { return }
        errorMessage = nil
        isSaving = true

        do {
            guard canSave else {
                throw ConvexError.serverError("Property, title, and description are required.")
            }

            let input = ConvexMaintenanceRequestInput(
                propertyId: propertyId,
                tenantId: tenantId.isEmpty ? nil : tenantId,
                title: title,
                descriptionText: descriptionText,
                category: category,
                priority: priority,
                photoURLs: nil
            )

            _ = try await dataService.createMaintenanceRequest(input)
            await dataService.loadAllData()
            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }

        isSaving = false
    }
}

#Preview {
    TriageHubView()
        .environmentObject(ConvexDataService.shared)
}

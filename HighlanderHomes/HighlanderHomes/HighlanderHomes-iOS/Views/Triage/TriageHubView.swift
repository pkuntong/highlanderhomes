import SwiftUI
import SwiftData

struct TriageHubView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @EnvironmentObject var appState: AppState

    @State private var selectedRequest: ConvexMaintenanceRequest?
    @State private var showingNewRequest = false
    @State private var filterStatus: String?

    private var activeRequests: [ConvexMaintenanceRequest] {
        dataService.maintenanceRequests.filter {
            $0.status != "completed" && $0.status != "cancelled"
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
                        activeCount: activeRequests.count,
                        showingNewRequest: $showingNewRequest
                    )

                    // Status Filter Pills
                    ConvexStatusFilterBar(selectedStatus: $filterStatus)
                        .padding(.vertical, Theme.Spacing.sm)

                    // Loading indicator
                    if dataService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.emerald))
                            .padding()
                    }

                    // Requests List
                    if filteredRequests.isEmpty && !dataService.isLoading {
                        EmptyTriageView()
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
                ConvexTriageDetailView(request: request)
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
        if let status = filterStatus {
            return activeRequests.filter { $0.status == status }
        }
        return activeRequests
    }
}

// MARK: - Triage Header
struct TriageHeader: View {
    let activeCount: Int
    @Binding var showingNewRequest: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Triage")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("\(activeCount) active requests")
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
    let statuses: [(key: String, label: String)] = [
        ("new", "New"),
        ("acknowledged", "Acknowledged"),
        ("scheduled", "Scheduled"),
        ("inProgress", "In Progress")
    ]

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
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.Gradients.emeraldGlow)

            Text("All Clear!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)

            Text("No active maintenance requests.\nYour properties are running smoothly.")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }
}

// MARK: - Convex Triage Detail View
struct ConvexTriageDetailView: View {
    let request: ConvexMaintenanceRequest
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        // Header Card
                        ConvexDetailHeaderCard(request: request)

                        // Workflow Steps
                        ConvexTriageWorkflowView(request: request)

                        // Communication Timeline
                        ConvexCommunicationTimeline(request: request)
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle(request.title)
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
    let request: ConvexMaintenanceRequest
    @State private var currentStep: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Workflow")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)

            VStack(spacing: 0) {
                WorkflowStep(
                    step: 1,
                    title: "Request Received",
                    subtitle: "Tenant submitted maintenance request",
                    icon: "bell.badge.fill",
                    isCompleted: true,
                    isCurrent: currentStep == 0
                )

                WorkflowConnector(isCompleted: currentStep > 0)

                WorkflowStep(
                    step: 2,
                    title: "Send to Contractor",
                    subtitle: "Assign and notify a contractor",
                    icon: "arrow.right.circle.fill",
                    isCompleted: currentStep > 0,
                    isCurrent: currentStep == 1,
                    actionLabel: currentStep == 1 ? "Assign Now" : nil
                ) {
                    HapticManager.shared.reward()
                    withAnimation(.spring(response: 0.4)) {
                        currentStep = 2
                    }
                }

                WorkflowConnector(isCompleted: currentStep > 1)

                WorkflowStep(
                    step: 3,
                    title: "Contractor Schedules",
                    subtitle: "Contractor confirms appointment time",
                    icon: "calendar.badge.clock",
                    isCompleted: currentStep > 1,
                    isCurrent: currentStep == 2
                )

                WorkflowConnector(isCompleted: currentStep > 2)

                WorkflowStep(
                    step: 4,
                    title: "Tenant Notified",
                    subtitle: "Automatic update sent to tenant",
                    icon: "person.fill.checkmark",
                    isCompleted: currentStep > 2,
                    isCurrent: currentStep == 3
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
        .onAppear {
            // Set initial step based on request status
            switch request.status {
            case "new": currentStep = 1
            case "acknowledged": currentStep = 1
            case "scheduled": currentStep = 2
            case "inProgress": currentStep = 3
            default: currentStep = 4
            }
        }
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

// MARK: - New Maintenance Request View (Placeholder)
struct NewMaintenanceRequestView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                Text("New Request Form")
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.slate400)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        HapticManager.shared.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
    }
}

#Preview {
    TriageHubView()
        .environmentObject(ConvexDataService.shared)
}

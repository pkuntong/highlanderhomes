import SwiftUI
import SwiftData

struct PropertyVaultView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Property.name) private var properties: [Property]
    @Query(sort: \Tenant.lastName) private var tenants: [Tenant]

    @State private var selectedTab: VaultTab = .properties
    @State private var searchText = ""
    @State private var showingAddSheet = false

    enum VaultTab: String, CaseIterable {
        case properties = "Properties"
        case tenants = "Tenants"
        case contractors = "Contractors"

        var icon: String {
            switch self {
            case .properties: return "building.2.fill"
            case .tenants: return "person.2.fill"
            case .contractors: return "wrench.and.screwdriver.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VaultHeader(showingAddSheet: $showingAddSheet)

                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.sm)

                    // Tab Selector
                    VaultTabBar(selectedTab: $selectedTab)
                        .padding(.horizontal, Theme.Spacing.md)

                    // Content
                    TabView(selection: $selectedTab) {
                        PropertiesListView(properties: filteredProperties, searchText: searchText)
                            .tag(VaultTab.properties)

                        TenantsListView(tenants: filteredTenants, searchText: searchText)
                            .tag(VaultTab.tenants)

                        ContractorsListView()
                            .tag(VaultTab.contractors)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEntitySheet(selectedTab: selectedTab)
            }
        }
        .onAppear {
            loadSampleDataIfNeeded()
        }
    }

    private var filteredProperties: [Property] {
        if searchText.isEmpty {
            return properties
        }
        return properties.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredTenants: [Tenant] {
        if searchText.isEmpty {
            return tenants
        }
        return tenants.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func loadSampleDataIfNeeded() {
        if tenants.isEmpty {
            let sampleTenants = [
                Tenant(
                    firstName: "Sarah",
                    lastName: "Johnson",
                    email: "sarah.j@email.com",
                    phone: "(512) 555-0123",
                    unit: "1A",
                    leaseStartDate: Date().addingTimeInterval(-86400 * 180),
                    leaseEndDate: Date().addingTimeInterval(86400 * 185),
                    monthlyRent: 2400
                ),
                Tenant(
                    firstName: "James",
                    lastName: "Wilson",
                    email: "j.wilson@email.com",
                    phone: "(512) 555-0456",
                    unit: "3C",
                    leaseStartDate: Date().addingTimeInterval(-86400 * 90),
                    leaseEndDate: Date().addingTimeInterval(86400 * 275),
                    monthlyRent: 1800
                ),
                Tenant(
                    firstName: "Emily",
                    lastName: "Chen",
                    email: "emily.chen@email.com",
                    phone: "(512) 555-0789",
                    unit: "4D",
                    leaseStartDate: Date().addingTimeInterval(-86400 * 335),
                    leaseEndDate: Date().addingTimeInterval(86400 * 30),
                    monthlyRent: 2200
                )
            ]

            for tenant in sampleTenants {
                modelContext.insert(tenant)
            }
        }
    }
}

// MARK: - Vault Header
struct VaultHeader: View {
    @Binding var showingAddSheet: Bool

    var body: some View {
        HStack {
            Text("Vault")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Button {
                HapticManager.shared.impact(.medium)
                showingAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Gradients.emeraldGlow)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textMuted)

            TextField("Search...", text: $text)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textPrimary)
                .focused($isFocused)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                    HapticManager.shared.impact(.light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.slate500)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate800)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .stroke(isFocused ? Theme.Colors.emerald : Theme.Colors.slate700, lineWidth: 1)
                }
        }
    }
}

// MARK: - Vault Tab Bar
struct VaultTabBar: View {
    @Binding var selectedTab: PropertyVaultView.VaultTab
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PropertyVaultView.VaultTab.allCases, id: \.self) { tab in
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                    }
                    .foregroundColor(selectedTab == tab ? Theme.Colors.emerald : Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .fill(Theme.Colors.emerald.opacity(0.15))
                                .matchedGeometryEffect(id: "vaultTab", in: animation)
                        }
                    }
                }
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.large)
                .fill(Theme.Colors.slate800)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Properties List View
struct PropertiesListView: View {
    let properties: [Property]
    let searchText: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(properties) { property in
                    PropertyCard(property: property)
                }

                if properties.isEmpty {
                    EmptyVaultState(
                        icon: "building.2",
                        title: searchText.isEmpty ? "No Properties" : "No Results",
                        subtitle: searchText.isEmpty ? "Add your first property to get started" : "Try a different search term"
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, 120)
        }
    }
}

struct PropertyCard: View {
    let property: Property
    @State private var showingDetail = false

    var body: some View {
        Button {
            HapticManager.shared.impact(.light)
            showingDetail = true
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Property Image/Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Gradients.cardGradient)
                        .frame(width: 64, height: 64)

                    Image(systemName: property.propertyType.icon)
                        .font(.system(size: 28))
                        .foregroundColor(Theme.Colors.emerald)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(property.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(property.address)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        Label("\(property.units)", systemImage: "door.left.hand.open")
                        Label("$\(Int(property.monthlyRent))", systemImage: "dollarsign.circle")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.textMuted)
                }

                Spacer()

                // Health indicator
                VStack(spacing: 4) {
                    Image(systemName: property.healthStatus.icon)
                        .font(.system(size: 20))
                        .foregroundColor(healthColor)

                    Text("\(property.healthScore)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(healthColor)
                }
            }
            .padding(Theme.Spacing.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            PropertyDetailView(property: property)
        }
    }

    private var healthColor: Color {
        switch property.healthStatus {
        case .excellent: return Theme.Colors.emerald
        case .good: return Theme.Colors.infoBlue
        case .attention: return Theme.Colors.warningAmber
        case .critical: return Theme.Colors.alertRed
        }
    }
}

// MARK: - Tenants List View
struct TenantsListView: View {
    let tenants: [Tenant]
    let searchText: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(tenants) { tenant in
                    TenantCard(tenant: tenant)
                }

                if tenants.isEmpty {
                    EmptyVaultState(
                        icon: "person.2",
                        title: searchText.isEmpty ? "No Tenants" : "No Results",
                        subtitle: searchText.isEmpty ? "Add tenants to your properties" : "Try a different search term"
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, 120)
        }
    }
}

struct TenantCard: View {
    let tenant: Tenant
    @State private var showingActions = false

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            HStack(spacing: Theme.Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Theme.Gradients.emeraldGlow.opacity(0.3))
                        .frame(width: 52, height: 52)

                    Text(tenant.initials)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.emerald)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(tenant.fullName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    HStack(spacing: 8) {
                        if let unit = tenant.unit {
                            Text("Unit \(unit)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }

                        LeaseStatusBadge(status: tenant.leaseStatus)
                    }
                }

                Spacer()

                // Quick actions
                HStack(spacing: 8) {
                    QuickContactButton(icon: "phone.fill", color: Theme.Colors.emerald) {
                        callTenant()
                    }

                    QuickContactButton(icon: "message.fill", color: Theme.Colors.infoBlue) {
                        messageTenant()
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .cardStyle()
    }

    private func callTenant() {
        HapticManager.shared.impact(.medium)
        if let url = URL(string: "tel:\(tenant.phone.replacingOccurrences(of: " ", with: ""))") {
            UIApplication.shared.open(url)
        }
    }

    private func messageTenant() {
        HapticManager.shared.impact(.medium)
        if let url = URL(string: "sms:\(tenant.phone.replacingOccurrences(of: " ", with: ""))") {
            UIApplication.shared.open(url)
        }
    }
}

struct QuickContactButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
        }
    }
}

struct LeaseStatusBadge: View {
    let status: Tenant.LeaseStatus

    var body: some View {
        Text(status.label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(statusColor.opacity(0.15))
            }
    }

    private var statusColor: Color {
        switch status {
        case .active: return Theme.Colors.emerald
        case .expiringSoon: return Theme.Colors.warningAmber
        case .expired: return Theme.Colors.alertRed
        case .inactive: return Theme.Colors.slate500
        }
    }
}

// MARK: - Contractors List View
struct ContractorsListView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                // Sample contractors
                ForEach(sampleContractors, id: \.name) { contractor in
                    ContractorCard(
                        name: contractor.name,
                        specialty: contractor.specialty,
                        rating: contractor.rating,
                        phone: contractor.phone
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, 120)
        }
    }

    private var sampleContractors: [(name: String, specialty: String, rating: Double, phone: String)] {
        [
            ("Mike's Plumbing", "Plumbing", 4.8, "(512) 555-1111"),
            ("AC Pros Austin", "HVAC", 4.5, "(512) 555-2222"),
            ("Quick Fix Electric", "Electrical", 4.9, "(512) 555-3333")
        ]
    }
}

struct ContractorCard: View {
    let name: String
    let specialty: String
    let rating: Double
    let phone: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.infoBlue.opacity(0.2))
                    .frame(width: 52, height: 52)

                Image(systemName: "wrench.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.Colors.infoBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)

                HStack(spacing: 8) {
                    Text(specialty)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.gold)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }

            Spacer()

            Button {
                HapticManager.shared.impact(.medium)
            } label: {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(12)
                    .background {
                        Circle()
                            .fill(Theme.Gradients.emeraldGlow)
                    }
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Empty Vault State
struct EmptyVaultState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.slate600)

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxl)
    }
}

// MARK: - Add Entity Sheet
struct AddEntitySheet: View {
    let selectedTab: PropertyVaultView.VaultTab
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack {
                    Text("Add \(selectedTab.rawValue.dropLast())")
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .navigationTitle("Add New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
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

// MARK: - Property Detail View
struct PropertyDetailView: View {
    let property: Property
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Property header
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: property.propertyType.icon)
                                .font(.system(size: 48))
                                .foregroundStyle(Theme.Gradients.emeraldGlow)

                            Text(property.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text(property.address)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .padding(.top, Theme.Spacing.lg)

                        // Stats
                        HStack(spacing: Theme.Spacing.lg) {
                            PropertyStatItem(label: "Units", value: "\(property.units)")
                            PropertyStatItem(label: "Rent", value: "$\(Int(property.monthlyRent))")
                            PropertyStatItem(label: "Health", value: "\(property.healthScore)")
                        }
                        .padding(Theme.Spacing.lg)
                        .cardStyle()
                    }
                    .padding(Theme.Spacing.md)
                }
            }
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

struct PropertyStatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PropertyVaultView()
        .modelContainer(for: [Property.self, Tenant.self], inMemory: true)
}

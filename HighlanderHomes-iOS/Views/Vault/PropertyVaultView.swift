import SwiftUI
import SwiftData

struct PropertyVaultView: View {
    @EnvironmentObject var dataService: ConvexDataService

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

                    // Loading indicator
                    if dataService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.emerald))
                            .padding()
                    }

                    // Content
                    TabView(selection: $selectedTab) {
                        ConvexPropertiesListView(properties: filteredProperties, searchText: searchText)
                            .tag(VaultTab.properties)

                        ConvexTenantsListView(tenants: filteredTenants, searchText: searchText)
                            .tag(VaultTab.tenants)

                        ConvexContractorsListView(contractors: filteredContractors)
                            .tag(VaultTab.contractors)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEntitySheet(selectedTab: selectedTab)
            }
        }
        .refreshable {
            await dataService.loadAllData()
        }
    }

    private var filteredProperties: [ConvexProperty] {
        if searchText.isEmpty {
            return dataService.properties
        }
        return dataService.properties.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredTenants: [ConvexTenant] {
        if searchText.isEmpty {
            return dataService.tenants
        }
        return dataService.tenants.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredContractors: [ConvexContractor] {
        if searchText.isEmpty {
            return dataService.contractors
        }
        return dataService.contractors.filter {
            $0.companyName.localizedCaseInsensitiveContains(searchText) ||
            $0.contactName.localizedCaseInsensitiveContains(searchText)
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

// MARK: - Properties List View (Convex)
struct ConvexPropertiesListView: View {
    let properties: [ConvexProperty]
    let searchText: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(properties) { property in
                    ConvexPropertyCard(property: property)
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

struct ConvexPropertyCard: View {
    let property: ConvexProperty
    @State private var showingDetail = false

    private var propertyIcon: String {
        switch property.propertyType {
        case "Single Family": return "house.fill"
        case "Multi-Family": return "building.2.fill"
        case "Apartment": return "building.fill"
        case "Condo": return "building.columns.fill"
        case "Townhouse": return "house.and.flag.fill"
        case "Commercial": return "storefront.fill"
        default: return "building.2.fill"
        }
    }

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

                    Image(systemName: propertyIcon)
                        .font(.system(size: 28))
                        .foregroundColor(Theme.Colors.emerald)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(property.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(property.displayAddress)
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

                // Type badge
                Text(property.propertyType)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.Colors.emerald)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.emerald.opacity(0.15))
                    }
            }
            .padding(Theme.Spacing.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            ConvexPropertyDetailView(property: property)
        }
    }
}

// MARK: - Tenants List View (Convex)
struct ConvexTenantsListView: View {
    let tenants: [ConvexTenant]
    let searchText: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(tenants) { tenant in
                    ConvexTenantCard(tenant: tenant)
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

struct ConvexTenantCard: View {
    let tenant: ConvexTenant
    @State private var showingActions = false

    private var leaseStatusText: String {
        switch tenant.leaseStatus {
        case "active": return "Active"
        case "expiringSoon": return "Expiring Soon"
        case "expired": return "Expired"
        default: return "Active"
        }
    }

    private var leaseStatusColor: Color {
        switch tenant.leaseStatus {
        case "active": return Theme.Colors.emerald
        case "expiringSoon": return Theme.Colors.warningAmber
        case "expired": return Theme.Colors.alertRed
        default: return Theme.Colors.emerald
        }
    }

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

                        Text(leaseStatusText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(leaseStatusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background {
                                Capsule()
                                    .fill(leaseStatusColor.opacity(0.15))
                            }
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


// MARK: - Contractors List View (Convex)
struct ConvexContractorsListView: View {
    let contractors: [ConvexContractor]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(contractors) { contractor in
                    ConvexContractorCard(contractor: contractor)
                }

                if contractors.isEmpty {
                    EmptyVaultState(
                        icon: "wrench.and.screwdriver",
                        title: "No Contractors",
                        subtitle: "Add contractors to manage your maintenance team"
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, 120)
        }
    }
}

struct ConvexContractorCard: View {
    let contractor: ConvexContractor

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
                Text(contractor.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)

                HStack(spacing: 8) {
                    Text(contractor.specialtyDisplay)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)

                    if let rating = contractor.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.gold)
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }

                    if contractor.isPreferred {
                        Text("Preferred")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.Colors.gold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background {
                                Capsule()
                                    .fill(Theme.Colors.gold.opacity(0.15))
                            }
                    }
                }
            }

            Spacer()

            Button {
                HapticManager.shared.impact(.medium)
                if let url = URL(string: "tel:\(contractor.phone.replacingOccurrences(of: " ", with: ""))") {
                    UIApplication.shared.open(url)
                }
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

// MARK: - Property Detail View (Convex)
struct ConvexPropertyDetailView: View {
    let property: ConvexProperty
    @Environment(\.dismiss) private var dismiss

    private var propertyIcon: String {
        switch property.propertyType {
        case "Single Family": return "house.fill"
        case "Multi-Family": return "building.2.fill"
        case "Apartment": return "building.fill"
        case "Condo": return "building.columns.fill"
        case "Townhouse": return "house.and.flag.fill"
        case "Commercial": return "storefront.fill"
        default: return "building.2.fill"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Property header
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: propertyIcon)
                                .font(.system(size: 48))
                                .foregroundStyle(Theme.Gradients.emeraldGlow)

                            Text(property.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text(property.displayAddress)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.textSecondary)

                            Text(property.propertyType)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.emerald)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(Theme.Colors.emerald.opacity(0.15))
                                }
                        }
                        .padding(.top, Theme.Spacing.lg)

                        // Stats
                        HStack(spacing: Theme.Spacing.lg) {
                            PropertyStatItem(label: "Units", value: "\(property.units)")
                            PropertyStatItem(label: "Rent", value: "$\(Int(property.monthlyRent))")
                            if let value = property.currentValue {
                                PropertyStatItem(label: "Value", value: "$\(Int(value / 1000))K")
                            }
                        }
                        .padding(Theme.Spacing.lg)
                        .cardStyle()

                        // Notes if any
                        if let notes = property.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("Notes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textSecondary)

                                Text(notes)
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.Colors.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Theme.Spacing.lg)
                            .cardStyle()
                        }
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
        .environmentObject(ConvexDataService.shared)
}

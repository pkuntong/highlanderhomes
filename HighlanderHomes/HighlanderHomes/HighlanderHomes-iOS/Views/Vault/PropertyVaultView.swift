import SwiftUI
import SwiftData

struct PropertyVaultView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @EnvironmentObject var appState: AppState

    @State private var selectedTab: VaultTab = .properties
    @State private var searchText = ""
    @State private var showingAddSheet = false

    enum VaultTab: String, CaseIterable {
        case properties = "Properties"
        case tenants = "Tenants"
        case contractors = "Contractors"
        case insurance = "Insurance"
        case licenses = "Licenses"

        var icon: String {
            switch self {
            case .properties: return "building.2.fill"
            case .tenants: return "person.2.fill"
            case .contractors: return "wrench.and.screwdriver.fill"
            case .insurance: return "shield.fill"
            case .licenses: return "doc.text.fill"
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

                        ConvexInsurancePoliciesListView(policies: filteredInsurancePolicies)
                            .tag(VaultTab.insurance)

                        ConvexRentalLicensesListView(licenses: filteredRentalLicenses)
                            .tag(VaultTab.licenses)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEntitySheet(selectedTab: selectedTab, prefillProperty: nil)
            }
            .onChange(of: showingAddSheet) { newValue in
                appState.isModalPresented = newValue
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
            $0.contactName.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText) ||
            $0.phone.localizedCaseInsensitiveContains(searchText) ||
            ($0.address ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.website ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.notes ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredInsurancePolicies: [ConvexInsurancePolicy] {
        if searchText.isEmpty {
            return dataService.insurancePolicies
        }
        return dataService.insurancePolicies.filter {
            $0.propertyLabel.localizedCaseInsensitiveContains(searchText) ||
            $0.insuranceName.localizedCaseInsensitiveContains(searchText) ||
            $0.policyNumber.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredRentalLicenses: [ConvexRentalLicense] {
        if searchText.isEmpty {
            return dataService.rentalLicenses
        }
        return dataService.rentalLicenses.filter {
            $0.propertyLabel.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText) ||
            $0.licenseNumber.localizedCaseInsensitiveContains(searchText) ||
            ($0.link ?? "").localizedCaseInsensitiveContains(searchText)
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? Theme.Colors.emerald : Theme.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .fill(isSelected ? Theme.Colors.emerald.opacity(0.15) : Theme.Colors.slate900)
                }
        }
    }
}

struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(color.opacity(0.15))
            }
    }
}

// MARK: - Vault Tab Bar
struct VaultTabBar: View {
    @Binding var selectedTab: PropertyVaultView.VaultTab
    @Namespace private var animation

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
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
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                    .fill(Theme.Colors.emerald.opacity(0.15))
                                    .matchedGeometryEffect(id: "vaultTab", in: animation)
                            } else {
                                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                    .fill(Theme.Colors.slate900)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
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
    @EnvironmentObject var appState: AppState
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
        .onChange(of: showingDetail) { newValue in
            appState.isModalPresented = newValue
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

struct QuickContactLink: View {
    let icon: String
    let color: Color
    let url: URL

    var body: some View {
        Link(destination: url) {
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
    @EnvironmentObject var dataService: ConvexDataService
    @State private var selectedCategory = "All"
    @State private var isBulkEditing = false
    @State private var selectedIds: Set<String> = []
    @State private var showingBulkSheet = false

    private var categories: [String] {
        let specialties = contractors.flatMap { $0.specialty }
        let unique = Array(Set(specialties)).sorted()
        return ["All"] + unique
    }

    private var filteredContractors: [ConvexContractor] {
        if selectedCategory == "All" {
            return contractors
        }
        return contractors.filter { $0.specialty.contains(selectedCategory) }
    }

    private var selectedContractors: [ConvexContractor] {
        contractors.filter { selectedIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(categories, id: \.self) { category in
                            FilterChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }

            HStack {
                if isBulkEditing {
                    Text("\(selectedIds.count) selected")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()

                Button(isBulkEditing ? "Cancel" : "Select") {
                    withAnimation(.spring(response: 0.25)) {
                        isBulkEditing.toggle()
                        if !isBulkEditing {
                            selectedIds.removeAll()
                        }
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isBulkEditing ? Theme.Colors.alertRed : Theme.Colors.emerald)

                if isBulkEditing {
                    Button("Bulk Edit") {
                        showingBulkSheet = true
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.emerald)
                    .disabled(selectedIds.isEmpty)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)

            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(filteredContractors) { contractor in
                        ConvexContractorCard(
                            contractor: contractor,
                            isBulkEditing: isBulkEditing,
                            isSelected: selectedIds.contains(contractor.id)
                        ) {
                            toggleSelection(contractor.id)
                        }
                    }

                    if filteredContractors.isEmpty {
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
        .sheet(isPresented: $showingBulkSheet) {
            BulkContractorEditSheet(
                contractors: selectedContractors,
                onComplete: {
                    selectedIds.removeAll()
                    isBulkEditing = false
                }
            )
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
}

struct ConvexContractorCard: View {
    let contractor: ConvexContractor
    var isBulkEditing: Bool = false
    var isSelected: Bool = false
    var onSelectToggle: (() -> Void)? = nil
    @State private var showingDetails = false

    private var hasEmail: Bool {
        !contractor.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasWebsite: Bool {
        guard let website = contractor.website else { return false }
        return !website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var emailURL: URL? {
        guard hasEmail else { return nil }
        return URL(string: "mailto:\(contractor.email)")
    }

    private var websiteURL: URL? {
        guard let website = contractor.website?.trimmingCharacters(in: .whitespacesAndNewlines), !website.isEmpty else {
            return nil
        }
        if website.lowercased().hasPrefix("http://") || website.lowercased().hasPrefix("https://") {
            return URL(string: website)
        }
        return URL(string: "https://\(website)")
    }

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

            if isBulkEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Theme.Colors.emerald : Theme.Colors.slate500)
            }

            HStack(spacing: 8) {
                if let emailURL {
                    QuickContactLink(icon: "envelope.fill", color: Theme.Colors.slate400, url: emailURL)
                }
                if let websiteURL {
                    QuickContactLink(icon: "globe", color: Theme.Colors.infoBlue, url: websiteURL)
                }
                Button {
                    HapticManager.shared.impact(.medium)
                    if let url = URL(string: "tel:\(contractor.phone.filter { $0.isNumber })") {
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
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture {
            if isBulkEditing {
                onSelectToggle?()
            } else {
                showingDetails = true
            }
        }
        .sheet(isPresented: $showingDetails) {
            ConvexContractorDetailSheet(contractor: contractor)
        }
    }
}

// MARK: - Insurance Policies (Convex)
struct ConvexInsurancePoliciesListView: View {
    let policies: [ConvexInsurancePolicy]

    var body: some View {
        let expiringSoon = policies.filter { $0.isExpiringSoon }.count
        let expired = policies.filter { $0.isExpired }.count

        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                if expiringSoon > 0 || expired > 0 {
                    HStack(spacing: Theme.Spacing.sm) {
                        if expiringSoon > 0 {
                            StatusPill(text: "\(expiringSoon) Expiring Soon", color: Theme.Colors.gold)
                        }
                        if expired > 0 {
                            StatusPill(text: "\(expired) Expired", color: Theme.Colors.alertRed)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }

                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(policies) { policy in
                        ConvexInsurancePolicyCard(policy: policy)
                    }

                    if policies.isEmpty {
                        EmptyVaultState(
                            icon: "shield",
                            title: "No Insurance Policies",
                            subtitle: "Seed or add insurance policies to track coverage"
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, 120)
            }
        }
    }
}

struct ConvexInsurancePolicyCard: View {
    let policy: ConvexInsurancePolicy
    @State private var showingDetails = false

    private var notesURL: URL? {
        guard let notes = policy.notes?.trimmingCharacters(in: .whitespacesAndNewlines),
              notes.lowercased().hasPrefix("http"),
              let url = URL(string: notes) else {
            return nil
        }
        return url
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.emerald.opacity(0.15))
                        .frame(width: 46, height: 46)

                    Image(systemName: "shield.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.emerald)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(policy.propertyLabel)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(policy.insuranceName)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text("Policy \(policy.policyNumber)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.slate400)
                }

                Spacer()

                Text(policy.premiumDisplay)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.Colors.emerald)
            }

            if policy.isExpired {
                StatusPill(text: "Expired", color: Theme.Colors.alertRed)
            } else if policy.isExpiringSoon {
                StatusPill(text: "Expiring in \(policy.daysUntilExpiration)d", color: Theme.Colors.gold)
            }

            DetailRow(label: "Term", value: policy.termDisplay)

            if let agent = policy.agent, !agent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DetailRow(label: "Agent", value: agent)
            }

            if let notes = policy.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let url = notesURL {
                    HStack(alignment: .top, spacing: 12) {
                        Text("Notes")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.textMuted)
                            .frame(width: 90, alignment: .leading)
                        Link(destination: url) {
                            Text(notes)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.emerald)
                                .underline()
                        }
                    }
                } else {
                    DetailRow(label: "Notes", value: notes)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetails = true
        }
        .sheet(isPresented: $showingDetails) {
            ConvexInsurancePolicyDetailSheet(policy: policy)
        }
    }
}

// MARK: - Rental Licenses (Convex)
struct ConvexRentalLicensesListView: View {
    let licenses: [ConvexRentalLicense]
    @State private var selectedCategory = "All"

    private var categories: [String] {
        let unique = Array(Set(licenses.map { $0.category })).sorted()
        return ["All"] + unique
    }

    private var filteredLicenses: [ConvexRentalLicense] {
        if selectedCategory == "All" {
            return licenses
        }
        return licenses.filter { $0.category == selectedCategory }
    }

    var body: some View {
        let expiringSoon = filteredLicenses.filter { $0.isExpiringSoon }.count
        let expired = filteredLicenses.filter { $0.isExpired }.count

        return VStack(spacing: Theme.Spacing.sm) {
            if !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(categories, id: \.self) { category in
                            FilterChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            }

            if expiringSoon > 0 || expired > 0 {
                HStack(spacing: Theme.Spacing.sm) {
                    if expiringSoon > 0 {
                        StatusPill(text: "\(expiringSoon) Expiring Soon", color: Theme.Colors.gold)
                    }
                    if expired > 0 {
                        StatusPill(text: "\(expired) Expired", color: Theme.Colors.alertRed)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }

            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(filteredLicenses) { license in
                        ConvexRentalLicenseCard(license: license)
                    }

                    if filteredLicenses.isEmpty {
                        EmptyVaultState(
                            icon: "doc.text",
                            title: "No Rental Licenses",
                            subtitle: "Add rent licenses to track compliance"
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, 120)
            }
        }
    }
}

struct ConvexRentalLicenseCard: View {
    let license: ConvexRentalLicense
    @State private var showingDetails = false

    private var linkURL: URL? {
        guard let link = license.link?.trimmingCharacters(in: .whitespacesAndNewlines), !link.isEmpty else {
            return nil
        }
        if link.lowercased().hasPrefix("http://") || link.lowercased().hasPrefix("https://") {
            return URL(string: link)
        }
        return URL(string: "https://\(link)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.infoBlue.opacity(0.2))
                        .frame(width: 46, height: 46)

                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.Colors.infoBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(license.propertyLabel)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(license.category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.infoBlue)
                }

                Spacer()

                Text(license.unitFeesDisplay)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.Colors.emerald)
            }

            if license.isExpired {
                StatusPill(text: "Expired", color: Theme.Colors.alertRed)
            } else if license.isExpiringSoon {
                StatusPill(text: "Expiring in \(license.daysUntilExpiration)d", color: Theme.Colors.gold)
            }

            DetailRow(label: "License #", value: license.licenseNumber)
            DetailRow(label: "Term", value: license.termDisplay)

            if let linkURL {
                DetailLinkRow(label: "Link", value: license.link ?? "", url: linkURL)
            }

            if let notes = license.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DetailRow(label: "Notes", value: notes)
            }
        }
        .padding(Theme.Spacing.md)
        .cardStyle()
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetails = true
        }
        .sheet(isPresented: $showingDetails) {
            ConvexRentalLicenseDetailSheet(license: license)
        }
    }
}

struct ConvexRentalLicenseDetailSheet: View {
    let license: ConvexRentalLicense
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    @State private var isEditing = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false

    @State private var propertyId: String
    @State private var propertyLabel: String
    @State private var category: String
    @State private var licenseNumber: String
    @State private var dateFrom: Date
    @State private var dateTo: Date
    @State private var unitFees: String
    @State private var link: String
    @State private var notes: String

    init(license: ConvexRentalLicense) {
        self.license = license
        _propertyId = State(initialValue: license.propertyId ?? "")
        _propertyLabel = State(initialValue: license.propertyLabel)
        _category = State(initialValue: license.category)
        _licenseNumber = State(initialValue: license.licenseNumber)
        _dateFrom = State(initialValue: license.dateFromValue)
        _dateTo = State(initialValue: license.dateToValue)
        _unitFees = State(initialValue: String(format: "%.2f", license.unitFees))
        _link = State(initialValue: license.link ?? "")
        _notes = State(initialValue: license.notes ?? "")
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

                        if isEditing {
                            licenseForm
                        } else {
                            licenseSummary
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("Rental License")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            Task { await handleSave() }
                        }
                        .foregroundColor(Theme.Colors.emerald)
                    } else {
                        Button("Edit") { isEditing = true }
                            .foregroundColor(Theme.Colors.emerald)
                    }
                }
            }
            .alert("Delete Rental License?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    Task { await handleDelete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the license from the vault.")
            }
        }
    }

    private var licenseSummary: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(propertyLabel)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)

            DetailRow(label: "Category", value: category)
            DetailRow(label: "License #", value: licenseNumber)
            DetailRow(label: "Term", value: "\(ConvexRentalLicense.dateFormatter.string(from: dateFrom)) – \(ConvexRentalLicense.dateFormatter.string(from: dateTo))")
            DetailRow(label: "Unit Fees", value: ConvexRentalLicense.moneyFormatter.string(from: NSNumber(value: Double(unitFees) ?? license.unitFees)) ?? unitFees)

            if !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let url = URL(string: link.hasPrefix("http") ? link : "https://\(link)") {
                DetailLinkRow(label: "Link", value: link, url: url)
            }

            if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DetailRow(label: "Notes", value: notes)
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete License")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate900)
        }
    }

    private var licenseForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            if !dataService.properties.isEmpty {
                Picker("Property", selection: $propertyId) {
                    Text("Select Property").tag("")
                    ForEach(dataService.properties, id: \.id) { property in
                        Text(property.name).tag(property.id)
                    }
                }
                .onChange(of: propertyId) { newValue in
                    guard let property = dataService.properties.first(where: { $0.id == newValue }) else { return }
                    let label = "\(property.address), \(property.city), \(property.state) \(property.zipCode)"
                    propertyLabel = label
                }
            }

            TextField("Property Address", text: $propertyLabel)
                .textFieldStyle(.roundedBorder)
            TextField("Category", text: $category)
                .textFieldStyle(.roundedBorder)
            TextField("License Number", text: $licenseNumber)
                .textFieldStyle(.roundedBorder)
            DatePicker("Date From", selection: $dateFrom, displayedComponents: .date)
            DatePicker("Date To", selection: $dateTo, displayedComponents: .date)
            TextField("Unit Fees", text: $unitFees)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
            TextField("Link", text: $link)
                .textFieldStyle(.roundedBorder)
            TextField("Notes", text: $notes)
                .textFieldStyle(.roundedBorder)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete License")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    private func handleSave() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        do {
            guard !propertyLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ConvexError.serverError("Property address is required.")
            }
            let fees = Double(unitFees.filter { "0123456789.".contains($0) }) ?? 0
            _ = try await dataService.updateRentalLicense(
                id: license.id,
                propertyId: propertyId.isEmpty ? nil : propertyId,
                propertyLabel: propertyLabel,
                category: category,
                licenseNumber: licenseNumber,
                dateFrom: dateFrom,
                dateTo: dateTo,
                unitFees: fees,
                link: link,
                notes: notes
            )
            await dataService.loadAllData()
            isEditing = false
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
            try await dataService.deleteRentalLicense(id: license.id)
            await dataService.loadAllData()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

struct ConvexInsurancePolicyDetailSheet: View {
    let policy: ConvexInsurancePolicy
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    @State private var isEditing = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false

    @State private var propertyId: String
    @State private var propertyLabel: String
    @State private var insuranceName: String
    @State private var policyNumber: String
    @State private var termStart: Date
    @State private var termEnd: Date
    @State private var premium: String
    @State private var notes: String
    @State private var agent: String

    init(policy: ConvexInsurancePolicy) {
        self.policy = policy
        _propertyId = State(initialValue: policy.propertyId ?? "")
        _propertyLabel = State(initialValue: policy.propertyLabel)
        _insuranceName = State(initialValue: policy.insuranceName)
        _policyNumber = State(initialValue: policy.policyNumber)
        _termStart = State(initialValue: policy.termStartDate)
        _termEnd = State(initialValue: policy.termEndDate)
        _premium = State(initialValue: String(format: "%.2f", policy.premium))
        _notes = State(initialValue: policy.notes ?? "")
        _agent = State(initialValue: policy.agent ?? "")
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

                        if isEditing {
                            insuranceForm
                        } else {
                            insuranceSummary
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("Insurance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            Task { await handleSave() }
                        }
                        .foregroundColor(Theme.Colors.emerald)
                    } else {
                        Button("Edit") { isEditing = true }
                            .foregroundColor(Theme.Colors.emerald)
                    }
                }
            }
            .alert("Delete Insurance Policy?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    Task { await handleDelete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the policy from the vault.")
            }
        }
    }

    private var insuranceSummary: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(propertyLabel)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.Colors.textPrimary)

            DetailRow(label: "Carrier", value: insuranceName)
            DetailRow(label: "Policy #", value: policyNumber)
            DetailRow(label: "Term", value: "\(ConvexInsurancePolicy.termFormatter.string(from: termStart)) – \(ConvexInsurancePolicy.termFormatter.string(from: termEnd))")
            DetailRow(label: "Premium", value: ConvexInsurancePolicy.premiumFormatter.string(from: NSNumber(value: Double(premium) ?? policy.premium)) ?? premium)

            if !agent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DetailRow(label: "Agent", value: agent)
            }
            if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DetailRow(label: "Notes", value: notes)
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete Policy")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate900)
        }
    }

    private var insuranceForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            if !dataService.properties.isEmpty {
                Picker("Property", selection: $propertyId) {
                    Text("Select Property").tag("")
                    ForEach(dataService.properties, id: \.id) { property in
                        Text(property.name).tag(property.id)
                    }
                }
                .onChange(of: propertyId) { newValue in
                    guard let property = dataService.properties.first(where: { $0.id == newValue }) else { return }
                    let label = "\(property.address), \(property.city), \(property.state) \(property.zipCode)"
                    propertyLabel = label
                }
            }

            TextField("Property Address", text: $propertyLabel)
                .textFieldStyle(.roundedBorder)
            TextField("Insurance Name", text: $insuranceName)
                .textFieldStyle(.roundedBorder)
            TextField("Policy Number", text: $policyNumber)
                .textFieldStyle(.roundedBorder)
            DatePicker("Term Start", selection: $termStart, displayedComponents: .date)
            DatePicker("Term End", selection: $termEnd, displayedComponents: .date)
            TextField("Premium", text: $premium)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
            TextField("Agent", text: $agent)
                .textFieldStyle(.roundedBorder)
            TextField("Notes", text: $notes)
                .textFieldStyle(.roundedBorder)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete Policy")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    private func handleSave() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        do {
            guard !propertyLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ConvexError.serverError("Property address is required.")
            }

            let premiumValue = Double(premium.filter { "0123456789.".contains($0) }) ?? 0
            _ = try await dataService.updateInsurancePolicy(
                id: policy.id,
                propertyId: propertyId.isEmpty ? nil : propertyId,
                propertyLabel: propertyLabel,
                insuranceName: insuranceName,
                policyNumber: policyNumber,
                termStart: termStart,
                termEnd: termEnd,
                premium: premiumValue,
                notes: notes,
                agent: agent
            )
            await dataService.loadAllData()
            isEditing = false
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
            try await dataService.deleteInsurancePolicy(id: policy.id)
            await dataService.loadAllData()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

struct ConvexContractorDetailSheet: View {
    let contractor: ConvexContractor
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    @State private var isEditing = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var companyName: String
    @State private var contactName: String
    @State private var address: String
    @State private var website: String
    @State private var notes: String
    @State private var email: String
    @State private var phone: String
    @State private var specialty: String
    @State private var hourlyRate: String
    @State private var rating: String
    @State private var isPreferred: Bool

    init(contractor: ConvexContractor) {
        self.contractor = contractor
        _companyName = State(initialValue: contractor.companyName)
        _contactName = State(initialValue: contractor.contactName)
        _address = State(initialValue: contractor.address ?? "")
        _website = State(initialValue: contractor.website ?? "")
        _notes = State(initialValue: contractor.notes ?? "")
        _email = State(initialValue: contractor.email)
        _phone = State(initialValue: contractor.phone)
        _specialty = State(initialValue: contractor.specialtyDisplay)
        _hourlyRate = State(initialValue: contractor.hourlyRate.map { String(format: "%.2f", $0) } ?? "")
        _rating = State(initialValue: contractor.rating.map { String(format: "%.1f", $0) } ?? "")
        _isPreferred = State(initialValue: contractor.isPreferred)
    }

    private var hasEmail: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasPhone: Bool {
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasAddress: Bool {
        !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasWebsite: Bool {
        !website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasNotes: Bool {
        !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var phoneDigits: String {
        phone.filter { $0.isNumber }
    }

    private var websiteURL: URL? {
        let trimmed = website.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
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

                        if isEditing {
                            contractorForm
                        } else {
                            contractorSummary
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("Contractor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            Task { await handleSave() }
                        }
                        .foregroundColor(Theme.Colors.emerald)
                    } else {
                        Button("Edit") { isEditing = true }
                            .foregroundColor(Theme.Colors.emerald)
                    }
                }
            }
        }
    }

    private var contractorSummary: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 6) {
                Text(companyName.isEmpty ? contactName : companyName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(contactName)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            HStack(spacing: Theme.Spacing.md) {
                if hasPhone {
                    Button {
                        if let url = URL(string: "tel:\(phoneDigits)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Call", systemImage: "phone.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.Colors.emerald)
                }

                if hasEmail, let url = URL(string: "mailto:\(email)") {
                    Link(destination: url) {
                        Label("Email", systemImage: "envelope.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.Colors.slate400)
                }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                DetailRow(label: "Phone", value: phone)
                if hasEmail, let url = URL(string: "mailto:\(email)") {
                    DetailLinkRow(label: "Email", value: email, url: url)
                }
                if hasAddress {
                    DetailRow(label: "Address", value: address)
                }
                DetailRow(label: "Specialties", value: specialty)
                if hasWebsite, let url = websiteURL {
                    DetailLinkRow(label: "Website", value: website, url: url)
                }
                if hasNotes {
                    DetailRow(label: "Notes", value: notes)
                }
                if let hourlyRateValue = Double(hourlyRate.filter { "0123456789.".contains($0) }) {
                    DetailRow(label: "Hourly Rate", value: "$\(String(format: "%.2f", hourlyRateValue))")
                }
                if let ratingValue = Double(rating.filter { "0123456789.".contains($0) }) {
                    DetailRow(label: "Rating", value: String(format: "%.1f", ratingValue))
                }
                DetailRow(label: "Preferred", value: isPreferred ? "Yes" : "No")
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .fill(Theme.Colors.slate900)
            }
        }
    }

    private var contractorForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            TextField("Company Name", text: $companyName)
                .textFieldStyle(.roundedBorder)
            TextField("Contact Name", text: $contactName)
                .textFieldStyle(.roundedBorder)
            TextField("Address", text: $address)
                .textFieldStyle(.roundedBorder)
            TextField("Website", text: $website)
                .textFieldStyle(.roundedBorder)
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
            TextField("Phone", text: $phone)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
            TextField("Specialties (comma separated)", text: $specialty)
                .textFieldStyle(.roundedBorder)
            TextField("Hourly Rate", text: $hourlyRate)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
            TextField("Rating", text: $rating)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
            TextField("Notes", text: $notes)
                .textFieldStyle(.roundedBorder)
            Toggle("Preferred Contractor", isOn: $isPreferred)
        }
    }

    private func handleSave() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        do {
            let specialties = specialty
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            let hourlyRateValue = Double(hourlyRate.filter { "0123456789.".contains($0) })
            let ratingValue = Double(rating.filter { "0123456789.".contains($0) })

            _ = try await dataService.updateContractor(
                id: contractor.id,
                companyName: companyName,
                contactName: contactName,
                address: address,
                website: website,
                notes: notes,
                email: email,
                phone: phone,
                specialty: specialties,
                hourlyRate: hourlyRateValue,
                rating: ratingValue,
                isPreferred: isPreferred
            )

            await dataService.loadAllData()
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.leading)
        }
    }
}

struct DetailLinkRow: View {
    let label: String
    let value: String
    let url: URL

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.textMuted)
                .frame(width: 90, alignment: .leading)
            Link(destination: url) {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.emerald)
                    .underline()
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

enum BulkPreferredAction: String, CaseIterable {
    case noChange = "No Change"
    case preferred = "Preferred"
    case notPreferred = "Not Preferred"
}

struct BulkContractorEditSheet: View {
    let contractors: [ConvexContractor]
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    @State private var preferredAction: BulkPreferredAction = .noChange
    @State private var addSpecialty = ""
    @State private var addNote = ""
    @State private var setPhone = ""
    @State private var setWebsite = ""
    @State private var isSaving = false
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

                        Text("Apply changes to \(contractors.count) contractors.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.Colors.textSecondary)

                        VStack(spacing: Theme.Spacing.md) {
                            Picker("Preferred", selection: $preferredAction) {
                                ForEach(BulkPreferredAction.allCases, id: \.self) { action in
                                    Text(action.rawValue).tag(action)
                                }
                            }
                            .pickerStyle(.segmented)

                            TextField("Add Specialty (optional)", text: $addSpecialty)
                                .textFieldStyle(.roundedBorder)

                            TextField("Append Note (optional)", text: $addNote)
                                .textFieldStyle(.roundedBorder)

                            TextField("Set Phone for All (optional)", text: $setPhone)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.phonePad)

                            TextField("Set Website for All (optional)", text: $setWebsite)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("Bulk Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await handleSave() }
                    }
                    .disabled(isSaving)
                    .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
    }

    private func handleSave() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        do {
            let specialtyToAdd = addSpecialty
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            for contractor in contractors {
                var specialties = contractor.specialty
                for specialty in specialtyToAdd where !specialties.contains(specialty) {
                    specialties.append(specialty)
                }

                var preferred = contractor.isPreferred
                switch preferredAction {
                case .noChange:
                    break
                case .preferred:
                    preferred = true
                case .notPreferred:
                    preferred = false
                }

                var notes = contractor.notes ?? ""
                if !addNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if notes.isEmpty {
                        notes = addNote
                    } else {
                        notes = "\(notes) • \(addNote)"
                    }
                }

                let phone = setPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? contractor.phone : setPhone
                let website = setWebsite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? contractor.website ?? "" : setWebsite

                _ = try await dataService.updateContractor(
                    id: contractor.id,
                    companyName: contractor.companyName,
                    contactName: contractor.contactName,
                    address: contractor.address,
                    website: website,
                    notes: notes,
                    email: contractor.email,
                    phone: phone,
                    specialty: specialties,
                    hourlyRate: contractor.hourlyRate,
                    rating: contractor.rating,
                    isPreferred: preferred
                )
            }

            await dataService.loadAllData()
            onComplete()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
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
    let prefillProperty: ConvexProperty?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    @State private var isSaving = false
    @State private var errorMessage: String?

    // Property fields
    @State private var propertyName = ""
    @State private var propertyAddress = ""
    @State private var propertyCity = ""
    @State private var propertyState = ""
    @State private var propertyZip = ""
    @State private var propertyType = "Single Family"
    @State private var propertyUnits = "1"
    @State private var propertyRent = ""
    @State private var propertyNotes = ""

    // Tenant fields
    @State private var tenantFirstName = ""
    @State private var tenantLastName = ""
    @State private var tenantEmail = ""
    @State private var tenantPhone = ""
    @State private var tenantPropertyId: String = ""
    @State private var tenantRent = ""
    @State private var tenantDeposit = ""
    @State private var tenantLeaseStart = Date()
    @State private var tenantLeaseEnd = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()

    // Contractor fields
    @State private var contractorCompany = ""
    @State private var contractorContact = ""
    @State private var contractorAddress = ""
    @State private var contractorWebsite = ""
    @State private var contractorNotes = ""
    @State private var contractorEmail = ""
    @State private var contractorPhone = ""
    @State private var contractorSpecialty = ""
    @State private var contractorHourlyRate = ""
    @State private var contractorPreferred = false

    // Insurance fields
    @State private var insurancePropertyId = ""
    @State private var insurancePropertyLabel = ""
    @State private var insuranceName = ""
    @State private var insurancePolicyNumber = ""
    @State private var insuranceTermStart = Date()
    @State private var insuranceTermEnd = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var insurancePremium = ""
    @State private var insuranceNotes = ""
    @State private var insuranceAgent = ""

    // Rental license fields
    @State private var licensePropertyId = ""
    @State private var licensePropertyLabel = ""
    @State private var licenseCategory = "Rent License"
    @State private var licenseNumber = ""
    @State private var licenseDateFrom = Date()
    @State private var licenseDateTo = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var licenseUnitFees = ""
    @State private var licenseLink = ""
    @State private var licenseNotes = ""

    init(selectedTab: PropertyVaultView.VaultTab, prefillProperty: ConvexProperty? = nil) {
        self.selectedTab = selectedTab
        self.prefillProperty = prefillProperty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.Colors.alertRed)
                        }

                        switch selectedTab {
                        case .properties:
                            propertyForm
                        case .tenants:
                            tenantForm
                        case .contractors:
                            contractorForm
                        case .insurance:
                            insurancePlaceholder
                        case .licenses:
                            rentalLicenseForm
                        }
                    }
                    .padding(Theme.Spacing.md)
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
                        Task { await handleSave() }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
        .onAppear {
            guard let property = prefillProperty else { return }
            let label = property.displayAddress
            switch selectedTab {
            case .tenants:
                if tenantPropertyId.isEmpty {
                    tenantPropertyId = property.id
                }
            case .insurance:
                if insurancePropertyId.isEmpty {
                    insurancePropertyId = property.id
                    insurancePropertyLabel = label
                }
            case .licenses:
                if licensePropertyId.isEmpty {
                    licensePropertyId = property.id
                    licensePropertyLabel = label
                }
            case .properties, .contractors:
                break
            }
        }
    }

    private var propertyForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            TextField("Property Name", text: $propertyName)
                .textFieldStyle(.roundedBorder)
            TextField("Address", text: $propertyAddress)
                .textFieldStyle(.roundedBorder)
            HStack {
                TextField("City", text: $propertyCity)
                TextField("State", text: $propertyState)
                    .frame(width: 70)
                TextField("Zip", text: $propertyZip)
                    .frame(width: 90)
            }
            .textFieldStyle(.roundedBorder)

            Picker("Type", selection: $propertyType) {
                ForEach(["Single Family", "Multi-Family", "Apartment", "Condo", "Townhouse", "Commercial"], id: \.self) {
                    Text($0)
                }
            }

            HStack {
                TextField("Units", text: $propertyUnits)
                    .keyboardType(.numberPad)
                TextField("Monthly Rent", text: $propertyRent)
                    .keyboardType(.decimalPad)
            }
            .textFieldStyle(.roundedBorder)

            TextField("Notes", text: $propertyNotes)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var tenantForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            TextField("First Name", text: $tenantFirstName)
                .textFieldStyle(.roundedBorder)
            TextField("Last Name", text: $tenantLastName)
                .textFieldStyle(.roundedBorder)
            TextField("Email", text: $tenantEmail)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
            TextField("Phone", text: $tenantPhone)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)

            Picker("Property", selection: $tenantPropertyId) {
                ForEach(dataService.properties, id: \.id) { property in
                    Text(property.name).tag(property.id)
                }
            }

            DatePicker("Lease Start", selection: $tenantLeaseStart, displayedComponents: .date)
            DatePicker("Lease End", selection: $tenantLeaseEnd, displayedComponents: .date)

            HStack {
                TextField("Monthly Rent", text: $tenantRent)
                    .keyboardType(.decimalPad)
                TextField("Deposit", text: $tenantDeposit)
                    .keyboardType(.decimalPad)
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    private var contractorForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            TextField("Company Name", text: $contractorCompany)
                .textFieldStyle(.roundedBorder)
            TextField("Contact Name", text: $contractorContact)
                .textFieldStyle(.roundedBorder)
            TextField("Address", text: $contractorAddress)
                .textFieldStyle(.roundedBorder)
            TextField("Website", text: $contractorWebsite)
                .textFieldStyle(.roundedBorder)
            TextField("Email", text: $contractorEmail)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
            TextField("Phone", text: $contractorPhone)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)
            TextField("Specialties (comma separated)", text: $contractorSpecialty)
                .textFieldStyle(.roundedBorder)
            TextField("Hourly Rate", text: $contractorHourlyRate)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
            TextField("Notes", text: $contractorNotes)
                .textFieldStyle(.roundedBorder)
            Toggle("Preferred Contractor", isOn: $contractorPreferred)
        }
    }

    private var insurancePlaceholder: some View {
        VStack(spacing: Theme.Spacing.md) {
            if !dataService.properties.isEmpty {
                Picker("Property", selection: $insurancePropertyId) {
                    Text("Select Property").tag("")
                    ForEach(dataService.properties, id: \.id) { property in
                        Text(property.name).tag(property.id)
                    }
                }
                .onChange(of: insurancePropertyId) { newValue in
                    guard let property = dataService.properties.first(where: { $0.id == newValue }) else { return }
                    let label = "\(property.address), \(property.city), \(property.state) \(property.zipCode)"
                    insurancePropertyLabel = label
                }
            }

            TextField("Property Address", text: $insurancePropertyLabel)
                .textFieldStyle(.roundedBorder)

            TextField("Insurance Name", text: $insuranceName)
                .textFieldStyle(.roundedBorder)
            TextField("Policy Number", text: $insurancePolicyNumber)
                .textFieldStyle(.roundedBorder)

            DatePicker("Term Start", selection: $insuranceTermStart, displayedComponents: .date)
            DatePicker("Term End", selection: $insuranceTermEnd, displayedComponents: .date)

            TextField("Premium", text: $insurancePremium)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)

            TextField("Agent", text: $insuranceAgent)
                .textFieldStyle(.roundedBorder)

            TextField("Notes", text: $insuranceNotes)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var rentalLicenseForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            if !dataService.properties.isEmpty {
                Picker("Property", selection: $licensePropertyId) {
                    Text("Select Property").tag("")
                    ForEach(dataService.properties, id: \.id) { property in
                        Text(property.name).tag(property.id)
                    }
                }
                .onChange(of: licensePropertyId) { newValue in
                    guard let property = dataService.properties.first(where: { $0.id == newValue }) else { return }
                    let label = "\(property.address), \(property.city), \(property.state) \(property.zipCode)"
                    licensePropertyLabel = label
                }
            }

            TextField("Property Address", text: $licensePropertyLabel)
                .textFieldStyle(.roundedBorder)

            TextField("Category", text: $licenseCategory)
                .textFieldStyle(.roundedBorder)

            TextField("License Number", text: $licenseNumber)
                .textFieldStyle(.roundedBorder)

            DatePicker("Date From", selection: $licenseDateFrom, displayedComponents: .date)
            DatePicker("Date To", selection: $licenseDateTo, displayedComponents: .date)

            TextField("Unit Fees", text: $licenseUnitFees)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)

            TextField("Link", text: $licenseLink)
                .textFieldStyle(.roundedBorder)

            TextField("Notes", text: $licenseNotes)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func handleSave() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        do {
            switch selectedTab {
            case .properties:
                let input = ConvexPropertyInput(
                    name: propertyName.isEmpty ? propertyAddress : propertyName,
                    address: propertyAddress,
                    city: propertyCity,
                    state: propertyState,
                    zipCode: propertyZip,
                    propertyType: propertyType,
                    units: Int(propertyUnits) ?? 1,
                    monthlyRent: Double(propertyRent) ?? 0,
                    purchasePrice: nil,
                    currentValue: nil,
                    imageURL: nil,
                    notes: propertyNotes.isEmpty ? nil : propertyNotes
                )
                _ = try await dataService.createProperty(input)
            case .tenants:
                guard !tenantPropertyId.isEmpty else {
                    throw ConvexError.serverError("Select a property first.")
                }
                let input = ConvexTenantInput(
                    firstName: tenantFirstName,
                    lastName: tenantLastName,
                    email: tenantEmail,
                    phone: tenantPhone,
                    unit: nil,
                    propertyId: tenantPropertyId,
                    leaseStartDate: tenantLeaseStart,
                    leaseEndDate: tenantLeaseEnd,
                    monthlyRent: Double(tenantRent) ?? 0,
                    securityDeposit: Double(tenantDeposit) ?? 0,
                    isActive: true,
                    emergencyContactName: nil,
                    emergencyContactPhone: nil,
                    notes: nil,
                    avatarURL: nil
                )
                _ = try await dataService.createTenant(input)
            case .contractors:
                let specialties = contractorSpecialty
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                let input = ConvexContractorInput(
                    companyName: contractorCompany,
                    contactName: contractorContact,
                    address: contractorAddress.isEmpty ? nil : contractorAddress,
                    website: contractorWebsite.isEmpty ? nil : contractorWebsite,
                    notes: contractorNotes.isEmpty ? nil : contractorNotes,
                    email: contractorEmail,
                    phone: contractorPhone,
                    specialty: specialties,
                    hourlyRate: Double(contractorHourlyRate),
                    rating: nil,
                    isPreferred: contractorPreferred
                )
                _ = try await dataService.createContractor(input)
            case .insurance:
                guard !insurancePropertyLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw ConvexError.serverError("Property address is required.")
                }
                let premium = Double(insurancePremium.filter { "0123456789.".contains($0) }) ?? 0
                _ = try await dataService.createInsurancePolicy(
                    propertyId: insurancePropertyId.isEmpty ? nil : insurancePropertyId,
                    propertyLabel: insurancePropertyLabel,
                    insuranceName: insuranceName,
                    policyNumber: insurancePolicyNumber,
                    termStart: insuranceTermStart,
                    termEnd: insuranceTermEnd,
                    premium: premium,
                    notes: insuranceNotes.isEmpty ? nil : insuranceNotes,
                    agent: insuranceAgent.isEmpty ? nil : insuranceAgent
                )
            case .licenses:
                guard !licensePropertyLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw ConvexError.serverError("Property address is required.")
                }
                let fees = Double(licenseUnitFees.filter { "0123456789.".contains($0) }) ?? 0
                _ = try await dataService.createRentalLicense(
                    propertyId: licensePropertyId.isEmpty ? nil : licensePropertyId,
                    propertyLabel: licensePropertyLabel,
                    category: licenseCategory,
                    licenseNumber: licenseNumber,
                    dateFrom: licenseDateFrom,
                    dateTo: licenseDateTo,
                    unitFees: fees,
                    link: licenseLink.isEmpty ? nil : licenseLink,
                    notes: licenseNotes.isEmpty ? nil : licenseNotes
                )
            }

            HapticManager.shared.success()
            await dataService.loadAllData()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }

        isSaving = false
    }
}

// MARK: - Property Detail View (Convex)
struct ConvexPropertyDetailView: View {
    let property: ConvexProperty
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ConvexDataService

    @State private var showingAddInsurance = false
    @State private var showingAddLicense = false

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

                        // Insurance Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack {
                                Text("Insurance")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                Spacer()
                                Button("Add") {
                                    showingAddInsurance = true
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.emerald)
                            }

                            if propertyInsurancePolicies.isEmpty {
                                Text("No insurance policies for this property yet.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            } else {
                                ForEach(propertyInsurancePolicies) { policy in
                                    ConvexInsurancePolicyCard(policy: policy)
                                }
                            }
                        }
                        .padding(Theme.Spacing.lg)
                        .cardStyle()

                        // Licenses Section
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack {
                                Text("Licenses")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.Colors.textPrimary)
                                Spacer()
                                Button("Add") {
                                    showingAddLicense = true
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.Colors.emerald)
                            }

                            if propertyRentalLicenses.isEmpty {
                                Text("No licenses for this property yet.")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.Colors.textSecondary)
                            } else {
                                ForEach(propertyRentalLicenses) { license in
                                    ConvexRentalLicenseCard(license: license)
                                }
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
        .sheet(isPresented: $showingAddInsurance) {
            AddEntitySheet(selectedTab: .insurance, prefillProperty: property)
        }
        .sheet(isPresented: $showingAddLicense) {
            AddEntitySheet(selectedTab: .licenses, prefillProperty: property)
        }
    }

    private var propertyInsurancePolicies: [ConvexInsurancePolicy] {
        let label = normalizeLabel(property.displayAddress)
        return dataService.insurancePolicies.filter { policy in
            if let propertyId = policy.propertyId {
                return propertyId == property.id
            }
            return normalizeLabel(policy.propertyLabel) == label
        }
    }

    private var propertyRentalLicenses: [ConvexRentalLicense] {
        let label = normalizeLabel(property.displayAddress)
        return dataService.rentalLicenses.filter { license in
            if let propertyId = license.propertyId {
                return propertyId == property.id
            }
            return normalizeLabel(license.propertyLabel) == label
        }
    }

    private func normalizeLabel(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
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

import SwiftUI

struct PropertiesListView: View {
    @EnvironmentObject var dataService: ConvexDataService
    @EnvironmentObject var appState: AppState

    @State private var searchText = ""
    @State private var showingAddProperty = false
    @State private var showingSettings = false
    @State private var showingContractors = false

    private var filteredProperties: [ConvexProperty] {
        if searchText.isEmpty {
            return dataService.properties
        }
        return dataService.properties.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search
                    SearchBar(text: $searchText)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.sm)

                    if dataService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.emerald))
                            .padding()
                    }

                    if filteredProperties.isEmpty && !dataService.isLoading {
                        EmptyStateView(
                            title: "No Properties Yet",
                            subtitle: "Add your first property to get started.",
                            icon: "building.2.fill"
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.md) {
                                ForEach(filteredProperties) { property in
                                    NavigationLink(value: property) {
                                        PropertyCard(property: property)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.bottom, 120)
                        }
                    }
                }
            }
            .navigationTitle("Properties")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Contractors directory
                        Button {
                            showingContractors = true
                        } label: {
                            Image(systemName: "person.2.badge.gearshape")
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        .accessibilityLabel("Contractors directory")

                        // Add property
                        Button {
                            HapticManager.shared.impact(.medium)
                            showingAddProperty = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.Gradients.emeraldGlow)
                        }
                        .accessibilityLabel("Add new property")
                    }
                }
            }
            .navigationDestination(for: ConvexProperty.self) { property in
                PropertyDetailView(property: property)
            }
        }
        .refreshable {
            await dataService.loadAllData()
        }
        .sheet(isPresented: $showingAddProperty) {
            AddPropertySheet()
        }
        .sheet(isPresented: $showingContractors) {
            ContractorsDirectorySheet()
        }
        .onChange(of: showingAddProperty) { newValue in
            appState.isModalPresented = newValue || showingContractors
        }
        .onChange(of: showingContractors) { newValue in
            appState.isModalPresented = newValue || showingAddProperty
        }
    }
}

// MARK: - Property Card
struct PropertyCard: View {
    let property: ConvexProperty
    @EnvironmentObject var dataService: ConvexDataService

    private var tenantCount: Int {
        dataService.tenants.filter { $0.propertyId == property.id && $0.isActive }.count
    }

    private var occupancyText: String {
        let occupied = tenantCount
        let total = property.units
        let rate = total > 0 ? Int(Double(occupied) / Double(total) * 100) : 0
        return "\(rate)% occupied"
    }

    private var pendingMaintenance: Int {
        dataService.maintenanceRequests.filter {
            $0.propertyId == property.id &&
            $0.status != "completed" && $0.status != "cancelled"
        }.count
    }

    private var statusColor: Color {
        if pendingMaintenance > 0 { return Theme.Colors.warningAmber }
        if tenantCount < property.units { return Theme.Colors.infoBlue }
        return Theme.Colors.emerald
    }

    private var statusText: String {
        if pendingMaintenance > 0 { return "\(pendingMaintenance) maintenance" }
        if tenantCount < property.units { return "Vacancy" }
        return "All current"
    }

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
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.slate700)
                    .frame(width: 56, height: 56)

                Image(systemName: propertyIcon)
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.emerald)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(property.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Text("\(property.propertyType) \u{2022} \(property.units) unit\(property.units > 1 ? "s" : "")")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.Colors.textSecondary)

                HStack(spacing: 6) {
                    Text("$\(Int(property.monthlyRent))/mo")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.Colors.emerald)

                    Text("\u{2022}")
                        .foregroundColor(Theme.Colors.textMuted)

                    Text(occupancyText)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(statusText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(statusColor)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.Colors.slate500)
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Colors.slate800.opacity(0.7))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .stroke(Theme.Colors.slate700.opacity(0.5), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(property.name), \(property.propertyType), \(property.units) units, \(Int(property.monthlyRent)) per month, \(statusText)")
    }
}

// MARK: - Add Property Sheet (placeholder — uses existing Vault add logic)
struct AddPropertySheet: View {
    @EnvironmentObject var dataService: ConvexDataService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var propertyType = "Single Family"
    @State private var units = 1
    @State private var monthlyRent = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    let propertyTypes = ["Single Family", "Multi-Family", "Apartment", "Condo", "Townhouse", "Commercial"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        FormField(label: "Property Name", text: $name, placeholder: "e.g. Oak Street House")
                        FormField(label: "Address", text: $address, placeholder: "Street address")

                        HStack(spacing: Theme.Spacing.md) {
                            FormField(label: "City", text: $city, placeholder: "City")
                            FormField(label: "State", text: $state, placeholder: "TX")
                                .frame(width: 80)
                            FormField(label: "ZIP", text: $zipCode, placeholder: "78701")
                                .frame(width: 100)
                        }

                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Property Type")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)

                            Picker("Type", selection: $propertyType) {
                                ForEach(propertyTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.Colors.emerald)
                        }

                        HStack(spacing: Theme.Spacing.lg) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text("Units")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.Colors.textSecondary)
                                Stepper(value: $units, in: 1...100) {
                                    Text("\(units)")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(Theme.Colors.textPrimary)
                                }
                                .tint(Theme.Colors.emerald)
                            }

                            FormField(label: "Monthly Rent ($)", text: $monthlyRent, placeholder: "0", keyboard: .decimalPad)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.Colors.alertRed)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.Colors.slate400)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await saveProperty() }
                    } label: {
                        if isSaving {
                            ProgressView().tint(Theme.Colors.emerald)
                        } else {
                            Text("Save").fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(Theme.Colors.emerald)
                    .disabled(name.isEmpty || address.isEmpty || isSaving)
                }
            }
        }
    }

    private func saveProperty() async {
        isSaving = true
        errorMessage = nil
        do {
            let input = ConvexPropertyInput(
                name: name,
                address: address,
                city: city,
                state: state,
                zipCode: zipCode,
                propertyType: propertyType,
                units: units,
                monthlyRent: Double(monthlyRent) ?? 0,
                purchasePrice: nil,
                currentValue: nil,
                imageURL: nil,
                notes: nil
            )
            _ = try await dataService.createProperty(input)
            HapticManager.shared.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.shared.error()
        }
        isSaving = false
    }
}

// MARK: - Form Field Helper
struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .fill(Theme.Colors.slate800)
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                .stroke(Theme.Colors.slate700, lineWidth: 1)
                        }
                }
        }
    }
}

// MARK: - Contractors Directory Sheet
struct ContractorsDirectorySheet: View {
    @EnvironmentObject var dataService: ConvexDataService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedContractor: ConvexContractor?

    private var filteredContractors: [ConvexContractor] {
        if searchText.isEmpty { return dataService.contractors }
        return dataService.contractors.filter {
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

                    if filteredContractors.isEmpty {
                        EmptyStateView(
                            title: "No Contractors",
                            subtitle: "Your contractor directory is empty.",
                            icon: "wrench.and.screwdriver.fill"
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Theme.Spacing.sm) {
                                ForEach(filteredContractors) { contractor in
                                    ContractorRow(contractor: contractor) {
                                        selectedContractor = contractor
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("Contractors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Theme.Colors.emerald)
                }
            }
        }
        .sheet(item: $selectedContractor) { contractor in
            ConvexContractorDetailSheet(contractor: contractor)
        }
    }
}

struct ContractorRow: View {
    let contractor: ConvexContractor
    var onSelect: (() -> Void)? = nil

    private var phoneURL: URL? {
        let digits = contractor.phone.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    private var smsURL: URL? {
        let digits = contractor.phone.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return URL(string: "sms://\(digits)")
    }

    private var emailURL: URL? {
        guard !contractor.email.isEmpty else { return nil }
        return URL(string: "mailto:\(contractor.email)")
    }

    private var websiteURL: URL? {
        guard let website = contractor.website?.trimmingCharacters(in: .whitespacesAndNewlines),
              !website.isEmpty else { return nil }
        if website.lowercased().hasPrefix("http") {
            return URL(string: website)
        }
        return URL(string: "https://\(website)")
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.infoBlue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "wrench.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.infoBlue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(contractor.companyName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        if contractor.isPreferred {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.gold)
                        }
                    }
                    Text(contractor.specialtyDisplay)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()

                if let rate = contractor.hourlyRate {
                    Text("$\(Int(rate))/hr")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.Colors.emerald)
                }
            }

            HStack(spacing: Theme.Spacing.sm) {
                if let phoneURL {
                    Link(destination: phoneURL) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.emerald)
                    }
                }
                if let smsURL {
                    Link(destination: smsURL) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.infoBlue)
                    }
                }
                if let emailURL {
                    Link(destination: emailURL) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.warningAmber)
                    }
                }
                if let websiteURL {
                    Link(destination: websiteURL) {
                        Image(systemName: "globe")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.slate400)
                    }
                }

                Spacer()

                if onSelect != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.Colors.textMuted)
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .fill(Theme.Colors.slate800.opacity(0.5))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect?()
        }
    }
}

#Preview {
    PropertiesListView()
        .environmentObject(AppState())
        .environmentObject(ConvexDataService.shared)
        .environmentObject(ConvexAuth.shared)
}

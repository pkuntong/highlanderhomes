import Foundation

/// Convex configuration for Highlander Homes
/// Update CONVEX_URL after running `npx convex dev`
enum ConvexConfig {
    // MARK: - Deployment URL
    // Get this from: npx convex dev (look for "Convex deployment URL")
    // Format: https://YOUR_DEPLOYMENT_NAME.convex.cloud
    static let deploymentURL = "https://acrobatic-nightingale-459.convex.cloud"
    // Keep in sync with the Convex JS client version used in this repo.
    static let apiVersion = "1.31.6"

    // Optional: set this to a specific userId from Convex to view existing data
    // Example: "js7f3g0...". Leave empty to use the signed-in user.
    static let dataOwnerUserIdDefaultsKey = "convex_data_owner_user_id"
    static let defaultDataOwnerUserId: String = ""

    static var dataOwnerUserId: String {
        let stored = UserDefaults.standard.string(forKey: dataOwnerUserIdDefaultsKey) ?? ""
        return stored.isEmpty ? defaultDataOwnerUserId : stored
    }

    // MARK: - Table Names (define in convex/schema.ts)
    enum Tables {
        static let properties = "properties"
        static let tenants = "tenants"
        static let maintenanceRequests = "maintenanceRequests"
        static let contractors = "contractors"
        static let users = "users"
        static let feedEvents = "feedEvents"
        static let rentPayments = "rentPayments"
        static let insurancePolicies = "insurancePolicies"
        static let rentalLicenses = "rentalLicenses"
        static let marketTrends = "marketTrends"
    }

    // MARK: - Function Names (define in convex/ folder)
    enum Functions {
        // Queries (read data)
        static let getProperties = "properties:list"
        static let getProperty = "properties:get"
        static let getTenants = "tenants:list"
        static let getTenant = "tenants:get"
        static let getMaintenanceRequests = "maintenanceRequests:list"
        static let getContractors = "contractors:list"
        static let getFeedEvents = "feedEvents:list"
        static let getRentPayments = "rentPayments:list"
        static let getExpenses = "expenses:list"
        static let getInsurancePolicies = "insurancePolicies:list"
        static let getRentalLicenses = "rentalLicenses:list"
        static let getMarketTrends = "marketTrends:list"
        static let getCurrentUser = "users:current"

        // Mutations (write data)
        static let createProperty = "properties:create"
        static let updateProperty = "properties:update"
        static let deleteProperty = "properties:deleteProperty"
        static let createTenant = "tenants:create"
        static let updateTenant = "tenants:update"
        static let createMaintenanceRequest = "maintenanceRequests:create"
        static let updateMaintenanceRequest = "maintenanceRequests:update"
        static let updateMaintenanceStatus = "maintenanceRequests:updateStatus"
        static let assignContractor = "maintenanceRequests:assignContractor"
        static let createContractor = "contractors:create"
        static let updateContractor = "contractors:update"
        static let createRentPayment = "rentPayments:create"
        static let updateRentPayment = "rentPayments:update"
        static let deleteRentPayment = "rentPayments:remove"
        static let createExpense = "expenses:create"
        static let updateExpense = "expenses:update"
        static let deleteExpense = "expenses:remove"
        static let createInsurancePolicy = "insurancePolicies:create"
        static let updateInsurancePolicy = "insurancePolicies:update"
        static let deleteInsurancePolicy = "insurancePolicies:remove"
        static let createRentalLicense = "rentalLicenses:create"
        static let updateRentalLicense = "rentalLicenses:update"
        static let deleteRentalLicense = "rentalLicenses:remove"
        static let createMarketTrend = "marketTrends:create"
        static let updateMarketTrend = "marketTrends:update"
        static let deleteMarketTrend = "marketTrends:remove"
        static let refreshLiveMarketTrend = "marketTrendsLive:refreshForProperty"
        static let refreshLiveMarketPortfolio = "marketTrendsLive:refreshPortfolio"
        static let createUser = "users:create"
        static let updateUser = "users:update"
        static let deleteUser = "users:deleteAccount"
        static let setPremiumStatus = "users:setPremiumStatus"
        static let changePassword = "auth:changePassword"
    }

    // MARK: - Auth Providers
    enum AuthProvider: String {
        case apple = "apple"
        case email = "email"
    }
}

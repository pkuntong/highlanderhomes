import Foundation

/// Convex configuration for Highlander Homes
/// Update CONVEX_URL after running `npx convex dev`
enum ConvexConfig {
    // MARK: - Deployment URL
    // Get this from: npx convex dev (look for "Convex deployment URL")
    // Format: https://YOUR_DEPLOYMENT_NAME.convex.cloud
    static let deploymentURL = "https://successful-goldfinch-551.convex.cloud"

    // MARK: - Table Names (define in convex/schema.ts)
    enum Tables {
        static let properties = "properties"
        static let tenants = "tenants"
        static let maintenanceRequests = "maintenanceRequests"
        static let contractors = "contractors"
        static let users = "users"
        static let feedEvents = "feedEvents"
        static let rentPayments = "rentPayments"
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
        static let getCurrentUser = "users:current"

        // Mutations (write data)
        static let createProperty = "properties:create"
        static let updateProperty = "properties:update"
        static let deleteProperty = "properties:delete"
        static let createTenant = "tenants:create"
        static let updateTenant = "tenants:update"
        static let createMaintenanceRequest = "maintenanceRequests:create"
        static let updateMaintenanceStatus = "maintenanceRequests:updateStatus"
        static let assignContractor = "maintenanceRequests:assignContractor"
        static let createUser = "users:create"
        static let updateUser = "users:update"
    }

    // MARK: - Auth Providers
    enum AuthProvider: String {
        case apple = "apple"
        case email = "email"
    }
}

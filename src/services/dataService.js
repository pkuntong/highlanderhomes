import { api } from "../../convex/_generated/api";
import {
  runConvexMutation,
  runConvexQuery,
} from "./convexClient";

export async function listProperties(userId) {
  return runConvexQuery(api.properties.list, { userId });
}

export async function updateProperty(payload) {
  return runConvexMutation(api.properties.update, payload);
}

export async function listTenants(userId) {
  return runConvexQuery(api.tenants.list, { userId });
}

export async function listMaintenanceRequests(userId) {
  return runConvexQuery(api.maintenanceRequests.list, { userId });
}

export async function createMaintenanceRequest(payload) {
  return runConvexMutation(api.maintenanceRequests.create, payload);
}

export async function updateMaintenanceRequest(payload) {
  return runConvexMutation(api.maintenanceRequests.update, payload);
}

export async function updateMaintenanceStatus(payload) {
  return runConvexMutation(api.maintenanceRequests.updateStatus, payload);
}

export async function listContractors(userId, specialty) {
  return runConvexQuery(api.contractors.list, {
    userId,
    specialty: specialty || undefined,
  });
}

export async function updateContractor(payload) {
  return runConvexMutation(api.contractors.update, payload);
}

export async function createContractor(payload) {
  return runConvexMutation(api.contractors.create, payload);
}

export async function listRentPayments(userId) {
  return runConvexQuery(api.rentPayments.list, { userId });
}

export async function createRentPayment(payload) {
  return runConvexMutation(api.rentPayments.create, payload);
}

export async function updateRentPayment(payload) {
  return runConvexMutation(api.rentPayments.update, payload);
}

export async function listExpenses(userId) {
  return runConvexQuery(api.expenses.list, { userId });
}

export async function createExpense(payload) {
  return runConvexMutation(api.expenses.create, payload);
}

export async function updateExpense(payload) {
  return runConvexMutation(api.expenses.update, payload);
}

export async function listUserProfile(userId) {
  return runConvexQuery(api.users.current, { userId });
}

export async function updateUserProfile(payload) {
  return runConvexMutation(api.users.update, payload);
}

export async function listInsurancePolicies(userId) {
  return runConvexQuery(api.insurancePolicies.list, { userId });
}

export async function listRentalLicenses(userId) {
  return runConvexQuery(api.rentalLicenses.list, { userId });
}

export async function generateDocumentUploadUrl() {
  return runConvexMutation(api.documents.generateUploadUrl, {});
}

export async function listDocuments(userId, propertyId, category) {
  return runConvexQuery(api.documents.list, {
    userId,
    propertyId: propertyId || undefined,
    category: category || undefined,
  });
}

export async function createDocument(payload) {
  return runConvexMutation(api.documents.create, payload);
}

export async function updateDocument(payload) {
  return runConvexMutation(api.documents.update, payload);
}

export async function removeDocument(id) {
  return runConvexMutation(api.documents.remove, { id });
}

export async function fetchDashboardSnapshot(userId) {
  const safeList = async (loader, fallback = []) => {
    try {
      return await loader();
    } catch (error) {
      // Keep dashboard usable if optional modules are not deployed yet.
      console.warn("Optional dashboard data unavailable:", error?.message || error);
      return fallback;
    }
  };

  const [
    properties,
    tenants,
    maintenanceRequests,
    rentPayments,
    expenses,
    contractors,
    documents,
    insurancePolicies,
    rentalLicenses,
  ] = await Promise.all([
    listProperties(userId),
    listTenants(userId),
    listMaintenanceRequests(userId),
    listRentPayments(userId),
    listExpenses(userId),
    listContractors(userId),
    safeList(() => listDocuments(userId), []),
    safeList(() => listInsurancePolicies(userId), []),
    safeList(() => listRentalLicenses(userId), []),
  ]);

  return {
    properties,
    tenants,
    maintenanceRequests,
    rentPayments,
    expenses,
    contractors,
    documents,
    insurancePolicies,
    rentalLicenses,
  };
}

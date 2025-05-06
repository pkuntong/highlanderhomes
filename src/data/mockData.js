// Mock data for the application
export const properties = [
  {
    id: 1,
    name: "Sunset Apartments",
    address: "123 Main St, San Francisco, CA 94105",
    type: "Apartment",
    units: 12,
    status: "Active",
    image: "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&auto=format&fit=crop&q=60",
    fullBathrooms: 1,
    halfBathrooms: 0,
    bedrooms: 2,
    squareFeet: 1200,
    yearBuilt: 2010,
    lastRenovation: "2020",
    notes: "Recently renovated kitchen and bathrooms"
  },
  {
    id: 2,
    name: "Ocean View Condos",
    address: "456 Beach Rd, San Francisco, CA 94107",
    type: "Condo",
    units: 8,
    status: "Active",
    image: "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&auto=format&fit=crop&q=60",
    fullBathrooms: 2,
    halfBathrooms: 1,
    bedrooms: 3,
    squareFeet: 1800,
    yearBuilt: 2015,
    lastRenovation: "2021",
    notes: "Premium ocean view units"
  }
];

export const tenants = [
  {
    id: 1,
    name: "John Smith",
    email: "john.smith@email.com",
    phone: "(555) 123-4567",
    propertyId: 1,
    unit: "101",
    leaseStart: "2023-01-01",
    leaseEnd: "2024-01-01",
    rent: 2500,
    status: "Active",
    paymentStatus: "Paid",
    notes: "Pays rent on time"
  },
  {
    id: 2,
    name: "Sarah Johnson",
    email: "sarah.j@email.com",
    phone: "(555) 987-6543",
    propertyId: 2,
    unit: "202",
    leaseStart: "2023-03-01",
    leaseEnd: "2024-03-01",
    rent: 3000,
    status: "Active",
    paymentStatus: "Pending",
    notes: "New tenant"
  }
];

export const maintenanceLogs = [
  {
    id: 1,
    propertyId: 1,
    unit: "101",
    type: "Plumbing",
    description: "Leaking faucet in kitchen",
    status: "Completed",
    date: "2023-05-15",
    cost: 150,
    assignedTo: "Mike's Plumbing",
    notes: "Fixed and tested"
  },
  {
    id: 2,
    propertyId: 2,
    unit: "202",
    type: "HVAC",
    description: "AC not cooling properly",
    status: "In Progress",
    date: "2023-06-01",
    cost: 0,
    assignedTo: "Cool Air Systems",
    notes: "Scheduled for repair"
  }
];

export const insurancePolicies = [
  {
    id: 1,
    propertyId: 1,
    provider: "State Farm",
    policyNumber: "SF123456",
    type: "Property",
    coverage: "Full",
    startDate: "2023-01-01",
    endDate: "2024-01-01",
    premium: 1200,
    status: "Active",
    notes: "Includes flood coverage"
  },
  {
    id: 2,
    propertyId: 2,
    provider: "Allstate",
    policyNumber: "AL789012",
    type: "Property",
    coverage: "Full",
    startDate: "2023-01-01",
    endDate: "2024-01-01",
    premium: 1500,
    status: "Active",
    notes: "Includes earthquake coverage"
  }
];

export const licenses = [
  {
    id: 1,
    propertyId: 1,
    type: "Business",
    number: "BL123456",
    issuingAuthority: "City of San Francisco",
    issueDate: "2023-01-01",
    expirationDate: "2024-01-01",
    status: "Active",
    notes: "Annual renewal required"
  },
  {
    id: 2,
    propertyId: 2,
    type: "Business",
    number: "BL789012",
    issuingAuthority: "City of San Francisco",
    issueDate: "2023-01-01",
    expirationDate: "2024-01-01",
    status: "Active",
    notes: "Annual renewal required"
  }
];

export const reminders = [
  {
    id: 1,
    title: "Renew Business License",
    description: "Annual business license renewal due",
    dueDate: "2024-01-01",
    priority: "High",
    status: "Pending",
    propertyId: 1,
    type: "License"
  },
  {
    id: 2,
    title: "Insurance Renewal",
    description: "Property insurance policy renewal",
    dueDate: "2024-01-01",
    priority: "High",
    status: "Pending",
    propertyId: 2,
    type: "Insurance"
  }
];

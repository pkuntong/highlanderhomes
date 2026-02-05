import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // Users table
  users: defineTable({
    name: v.string(),
    email: v.string(),
    avatarURL: v.optional(v.string()),
    isPremium: v.boolean(),
    passwordHash: v.optional(v.string()),
    passwordSalt: v.optional(v.string()),
    emailVerified: v.optional(v.boolean()),
    emailVerificationCode: v.optional(v.string()),
    emailVerificationExpiresAt: v.optional(v.number()),
    createdAt: v.number(),
    lastLoginAt: v.optional(v.number()),
  })
    .index("by_email", ["email"]),

  // Properties table
  properties: defineTable({
    name: v.string(),
    address: v.string(),
    city: v.string(),
    state: v.string(),
    zipCode: v.string(),
    propertyType: v.string(), // "Single Family", "Multi-Family", etc.
    units: v.number(),
    monthlyRent: v.number(),
    purchasePrice: v.optional(v.number()),
    currentValue: v.optional(v.number()),
    imageURL: v.optional(v.string()),
    notes: v.optional(v.string()),
    userId: v.id("users"), // Owner of the property
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_user_updated", ["userId", "updatedAt"]),

  // Tenants table
  tenants: defineTable({
    firstName: v.string(),
    lastName: v.string(),
    email: v.string(),
    phone: v.string(),
    unit: v.optional(v.string()),
    propertyId: v.id("properties"),
    leaseStartDate: v.number(),
    leaseEndDate: v.number(),
    monthlyRent: v.number(),
    securityDeposit: v.number(),
    isActive: v.boolean(),
    emergencyContactName: v.optional(v.string()),
    emergencyContactPhone: v.optional(v.string()),
    notes: v.optional(v.string()),
    avatarURL: v.optional(v.string()),
    userId: v.id("users"), // Property owner
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_property", ["propertyId"])
    .index("by_user", ["userId"])
    .index("by_email", ["email"]),

  // Maintenance Requests table
  maintenanceRequests: defineTable({
    propertyId: v.id("properties"),
    tenantId: v.optional(v.id("tenants")),
    contractorId: v.optional(v.id("contractors")),
    title: v.string(),
    descriptionText: v.string(),
    category: v.string(), // "Plumbing", "Electrical", "HVAC", etc.
    priority: v.string(), // "low", "normal", "high", "urgent", "emergency"
    status: v.string(), // "new", "acknowledged", "scheduled", "inProgress", "awaitingParts", "completed", "cancelled"
    photoURLs: v.optional(v.array(v.string())),
    scheduledDate: v.optional(v.number()),
    completedDate: v.optional(v.number()),
    estimatedCost: v.optional(v.number()),
    actualCost: v.optional(v.number()),
    notes: v.optional(v.string()),
    userId: v.id("users"), // Property owner
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_property", ["propertyId"])
    .index("by_tenant", ["tenantId"])
    .index("by_contractor", ["contractorId"])
    .index("by_user", ["userId"])
    .index("by_status", ["status"])
    .index("by_user_status", ["userId", "status"]),

  // Contractors table
  contractors: defineTable({
    companyName: v.string(),
    contactName: v.string(),
    email: v.string(),
    phone: v.string(),
    specialty: v.array(v.string()), // ["Plumbing", "Electrical", etc.]
    hourlyRate: v.optional(v.number()),
    rating: v.optional(v.number()),
    isPreferred: v.boolean(),
    userId: v.id("users"), // Property owner who added this contractor
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_specialty", ["specialty"]),

  // Rent Payments table
  rentPayments: defineTable({
    propertyId: v.id("properties"),
    tenantId: v.optional(v.id("tenants")),
    amount: v.number(),
    paymentDate: v.number(),
    dueDate: v.optional(v.number()),
    paymentMethod: v.optional(v.string()), // "check", "bank_transfer", "cash", etc.
    status: v.string(), // "pending", "completed", "overdue", "cancelled"
    transactionId: v.optional(v.string()),
    notes: v.optional(v.string()),
    userId: v.id("users"), // Property owner
    createdAt: v.number(),
  })
    .index("by_property", ["propertyId"])
    .index("by_tenant", ["tenantId"])
    .index("by_user", ["userId"])
    .index("by_date", ["paymentDate"]),

  // Expenses table
  expenses: defineTable({
    propertyId: v.optional(v.id("properties")),
    title: v.string(),
    description: v.optional(v.string()),
    amount: v.number(),
    category: v.string(), // "maintenance", "utilities", "insurance", etc.
    date: v.number(),
    isRecurring: v.boolean(),
    recurringFrequency: v.optional(v.string()), // "monthly", "yearly", etc.
    receiptURL: v.optional(v.string()),
    vendor: v.optional(v.string()),
    notes: v.optional(v.string()),
    userId: v.id("users"), // Property owner
    createdAt: v.number(),
  })
    .index("by_property", ["propertyId"])
    .index("by_user", ["userId"])
    .index("by_date", ["date"]),

  // Feed Events table (activity feed)
  feedEvents: defineTable({
    eventType: v.string(), // "maintenanceNew", "rentReceived", etc.
    title: v.string(),
    subtitle: v.string(),
    detail: v.optional(v.string()),
    timestamp: v.number(),
    isRead: v.boolean(),
    isActionRequired: v.boolean(),
    actionLabel: v.optional(v.string()),
    priority: v.number(), // 0-3 (low to urgent)
    propertyId: v.optional(v.id("properties")),
    tenantId: v.optional(v.id("tenants")),
    maintenanceRequestId: v.optional(v.id("maintenanceRequests")),
    contractorId: v.optional(v.id("contractors")),
    rentPaymentId: v.optional(v.id("rentPayments")),
    userId: v.id("users"), // Property owner
    createdAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_user_timestamp", ["userId", "timestamp"])
    .index("by_user_unread", ["userId", "isRead"]),
});

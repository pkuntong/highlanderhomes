import { v } from "convex/values";
import { mutation, action, internalMutation } from "./_generated/server";
import { internal } from "./_generated/api";

/**
 * Import properties from Firebase
 * Called from the migration script with Firebase data
 */
export const importProperties = mutation({
  args: {
    properties: v.array(
      v.object({
        firebaseId: v.string(),
        address: v.string(),
        city: v.string(),
        state: v.string(),
        zipCode: v.string(),
        propertyType: v.optional(v.string()),
        units: v.optional(v.number()),
        monthlyRent: v.optional(v.number()),
        bedrooms: v.optional(v.number()),
        fullBathrooms: v.optional(v.number()),
        halfBathrooms: v.optional(v.number()),
        squareFootage: v.optional(v.number()),
        yearBuilt: v.optional(v.number()),
        status: v.optional(v.string()),
        paymentStatus: v.optional(v.string()),
        description: v.optional(v.string()),
        imageUrl: v.optional(v.string()),
        leaseType: v.optional(v.string()),
      })
    ),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const results = [];
    const now = Date.now();

    for (const prop of args.properties) {
      try {
        const propertyId = await ctx.db.insert("properties", {
          name: prop.address, // Use address as name
          address: prop.address,
          city: prop.city,
          state: prop.state,
          zipCode: prop.zipCode,
          propertyType: prop.propertyType || "Single Family",
          units: prop.units || 1,
          monthlyRent: prop.monthlyRent || 0,
          purchasePrice: undefined,
          currentValue: undefined,
          imageURL: prop.imageUrl,
          notes: prop.description,
          userId: args.userId,
          createdAt: now,
          updatedAt: now,
        });

        results.push({
          firebaseId: prop.firebaseId,
          convexId: propertyId,
          success: true,
        });
      } catch (error) {
        results.push({
          firebaseId: prop.firebaseId,
          convexId: null,
          success: false,
          error: String(error),
        });
      }
    }

    return results;
  },
});

/**
 * Import tenants from Firebase
 */
export const importTenants = mutation({
  args: {
    tenants: v.array(
      v.object({
        firebaseId: v.string(),
        firstName: v.string(),
        lastName: v.string(),
        email: v.string(),
        phone: v.string(),
        unit: v.optional(v.string()),
        propertyId: v.optional(v.id("properties")),
        leaseStartDate: v.optional(v.number()),
        leaseEndDate: v.optional(v.number()),
        monthlyRent: v.optional(v.number()),
        securityDeposit: v.optional(v.number()),
        isActive: v.optional(v.boolean()),
      })
    ),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const results = [];
    const now = Date.now();

    for (const tenant of args.tenants) {
      try {
        // Skip if no propertyId (required field)
        if (!tenant.propertyId) {
          results.push({
            firebaseId: tenant.firebaseId,
            convexId: null,
            success: false,
            error: "Missing propertyId",
          });
          continue;
        }

        const tenantId = await ctx.db.insert("tenants", {
          firstName: tenant.firstName,
          lastName: tenant.lastName,
          email: tenant.email,
          phone: tenant.phone,
          unit: tenant.unit,
          propertyId: tenant.propertyId,
          leaseStartDate: tenant.leaseStartDate || now,
          leaseEndDate: tenant.leaseEndDate || now + 365 * 24 * 60 * 60 * 1000,
          monthlyRent: tenant.monthlyRent || 0,
          securityDeposit: tenant.securityDeposit || 0,
          isActive: tenant.isActive ?? true,
          userId: args.userId,
          createdAt: now,
          updatedAt: now,
        });

        results.push({
          firebaseId: tenant.firebaseId,
          convexId: tenantId,
          success: true,
        });
      } catch (error) {
        results.push({
          firebaseId: tenant.firebaseId,
          convexId: null,
          success: false,
          error: String(error),
        });
      }
    }

    return results;
  },
});

/**
 * Import maintenance requests from Firebase
 */
export const importMaintenanceRequests = mutation({
  args: {
    requests: v.array(
      v.object({
        firebaseId: v.string(),
        propertyId: v.id("properties"),
        tenantId: v.optional(v.id("tenants")),
        title: v.string(),
        descriptionText: v.string(),
        category: v.string(),
        priority: v.string(),
        status: v.string(),
        scheduledDate: v.optional(v.number()),
        completedDate: v.optional(v.number()),
        estimatedCost: v.optional(v.number()),
        actualCost: v.optional(v.number()),
        notes: v.optional(v.string()),
      })
    ),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const results = [];
    const now = Date.now();

    for (const req of args.requests) {
      try {
        const requestId = await ctx.db.insert("maintenanceRequests", {
          propertyId: req.propertyId,
          tenantId: req.tenantId,
          title: req.title,
          descriptionText: req.descriptionText,
          category: req.category,
          priority: req.priority,
          status: req.status,
          scheduledDate: req.scheduledDate,
          completedDate: req.completedDate,
          estimatedCost: req.estimatedCost,
          actualCost: req.actualCost,
          notes: req.notes,
          userId: args.userId,
          createdAt: now,
          updatedAt: now,
        });

        results.push({
          firebaseId: req.firebaseId,
          convexId: requestId,
          success: true,
        });
      } catch (error) {
        results.push({
          firebaseId: req.firebaseId,
          convexId: null,
          success: false,
          error: String(error),
        });
      }
    }

    return results;
  },
});

/**
 * Create a user for migration (if doesn't exist)
 */
export const createMigrationUser = mutation({
  args: {
    email: v.string(),
    name: v.string(),
  },
  handler: async (ctx, args) => {
    // Check if user exists
    const existingUser = await ctx.db
      .query("users")
      .withIndex("by_email", (q) => q.eq("email", args.email))
      .first();

    if (existingUser) {
      return existingUser._id;
    }

    // Create new user
    const userId = await ctx.db.insert("users", {
      name: args.name,
      email: args.email,
      isPremium: false,
      createdAt: Date.now(),
    });

    return userId;
  },
});

/**
 * Clear all data (for testing migrations)
 */
export const clearAllData = mutation({
  args: {},
  handler: async (ctx) => {
    // Delete all documents from each table
    const tables = [
      "properties",
      "tenants",
      "maintenanceRequests",
      "contractors",
      "rentPayments",
      "expenses",
      "feedEvents",
    ];

    const results: Record<string, number> = {};

    for (const table of tables) {
      const docs = await ctx.db.query(table as any).collect();
      for (const doc of docs) {
        await ctx.db.delete(doc._id);
      }
      results[table] = docs.length;
    }

    return results;
  },
});

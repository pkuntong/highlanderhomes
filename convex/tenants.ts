import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

/**
 * List all tenants
 */
export const list = query({
  args: {
    userId: v.optional(v.id("users")),
    propertyId: v.optional(v.id("properties")),
  },
  handler: async (ctx, args) => {
    let query = ctx.db.query("tenants");

    if (args.propertyId) {
      query = query.withIndex("by_property", (q) =>
        q.eq("propertyId", args.propertyId!)
      );
    } else if (args.userId) {
      query = query.withIndex("by_user", (q) => q.eq("userId", args.userId!));
    }

    const tenants = await query.collect();

    return tenants.map((tenant) => ({
      _id: tenant._id,
      id: tenant._id,
      firstName: tenant.firstName,
      lastName: tenant.lastName,
      email: tenant.email,
      phone: tenant.phone,
      unit: tenant.unit,
      propertyId: tenant.propertyId,
      leaseStartDate: tenant.leaseStartDate,
      leaseEndDate: tenant.leaseEndDate,
      monthlyRent: tenant.monthlyRent,
      securityDeposit: tenant.securityDeposit,
      isActive: tenant.isActive,
      emergencyContactName: tenant.emergencyContactName,
      emergencyContactPhone: tenant.emergencyContactPhone,
      notes: tenant.notes,
      avatarURL: tenant.avatarURL,
      createdAt: tenant.createdAt,
      updatedAt: tenant.updatedAt,
    }));
  },
});

/**
 * Get a single tenant by ID
 */
export const get = query({
  args: { id: v.id("tenants") },
  handler: async (ctx, args) => {
    const tenant = await ctx.db.get(args.id);
    if (!tenant) {
      throw new Error("Tenant not found");
    }

    return {
      _id: tenant._id,
      id: tenant._id,
      firstName: tenant.firstName,
      lastName: tenant.lastName,
      email: tenant.email,
      phone: tenant.phone,
      unit: tenant.unit,
      propertyId: tenant.propertyId,
      leaseStartDate: tenant.leaseStartDate,
      leaseEndDate: tenant.leaseEndDate,
      monthlyRent: tenant.monthlyRent,
      securityDeposit: tenant.securityDeposit,
      isActive: tenant.isActive,
      emergencyContactName: tenant.emergencyContactName,
      emergencyContactPhone: tenant.emergencyContactPhone,
      notes: tenant.notes,
      avatarURL: tenant.avatarURL,
      createdAt: tenant.createdAt,
      updatedAt: tenant.updatedAt,
    };
  },
});

/**
 * Create a new tenant
 */
export const create = mutation({
  args: {
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
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const tenantId = await ctx.db.insert("tenants", {
      firstName: args.firstName,
      lastName: args.lastName,
      email: args.email,
      phone: args.phone,
      unit: args.unit,
      propertyId: args.propertyId,
      leaseStartDate: args.leaseStartDate,
      leaseEndDate: args.leaseEndDate,
      monthlyRent: args.monthlyRent,
      securityDeposit: args.securityDeposit,
      isActive: args.isActive,
      emergencyContactName: args.emergencyContactName,
      emergencyContactPhone: args.emergencyContactPhone,
      notes: args.notes,
      avatarURL: args.avatarURL,
      userId: args.userId,
      createdAt: now,
      updatedAt: now,
    });

    const tenant = await ctx.db.get(tenantId);
    return {
      _id: tenant!._id,
      id: tenant!._id,
      firstName: tenant!.firstName,
      lastName: tenant!.lastName,
      email: tenant!.email,
      phone: tenant!.phone,
      unit: tenant!.unit,
      propertyId: tenant!.propertyId,
      leaseStartDate: tenant!.leaseStartDate,
      leaseEndDate: tenant!.leaseEndDate,
      monthlyRent: tenant!.monthlyRent,
      securityDeposit: tenant!.securityDeposit,
      isActive: tenant!.isActive,
      emergencyContactName: tenant!.emergencyContactName,
      emergencyContactPhone: tenant!.emergencyContactPhone,
      notes: tenant!.notes,
      avatarURL: tenant!.avatarURL,
      createdAt: tenant!.createdAt,
      updatedAt: tenant!.updatedAt,
    };
  },
});

/**
 * Update an existing tenant
 */
export const update = mutation({
  args: {
    id: v.id("tenants"),
    firstName: v.optional(v.string()),
    lastName: v.optional(v.string()),
    email: v.optional(v.string()),
    phone: v.optional(v.string()),
    unit: v.optional(v.string()),
    propertyId: v.optional(v.id("properties")),
    leaseStartDate: v.optional(v.number()),
    leaseEndDate: v.optional(v.number()),
    monthlyRent: v.optional(v.number()),
    securityDeposit: v.optional(v.number()),
    isActive: v.optional(v.boolean()),
    emergencyContactName: v.optional(v.string()),
    emergencyContactPhone: v.optional(v.string()),
    notes: v.optional(v.string()),
    avatarURL: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { id, ...updates } = args;
    const tenant = await ctx.db.get(id);
    if (!tenant) {
      throw new Error("Tenant not found");
    }

    await ctx.db.patch(id, {
      ...updates,
      updatedAt: Date.now(),
    });

    const updated = await ctx.db.get(id);
    return {
      _id: updated!._id,
      id: updated!._id,
      firstName: updated!.firstName,
      lastName: updated!.lastName,
      email: updated!.email,
      phone: updated!.phone,
      unit: updated!.unit,
      propertyId: updated!.propertyId,
      leaseStartDate: updated!.leaseStartDate,
      leaseEndDate: updated!.leaseEndDate,
      monthlyRent: updated!.monthlyRent,
      securityDeposit: updated!.securityDeposit,
      isActive: updated!.isActive,
      emergencyContactName: updated!.emergencyContactName,
      emergencyContactPhone: updated!.emergencyContactPhone,
      notes: updated!.notes,
      avatarURL: updated!.avatarURL,
      createdAt: updated!.createdAt,
      updatedAt: updated!.updatedAt,
    };
  },
});

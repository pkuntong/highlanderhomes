import { v } from "convex/values";
import { query, mutation } from "./_generated/server";
import { FREE_PROPERTY_LIMIT, isOwnerEmail } from "./limits";

/**
 * List all properties for the current user
 * Note: In production, get userId from auth token
 */
export const list = query({
  args: {
    userId: v.optional(v.id("users")),
  },
  handler: async (ctx, args) => {
    // TODO: Get userId from auth token in production
    // If userId is present, scope to that user; otherwise return all (useful for preview/demo).
    let query = ctx.db.query("properties");
    if (args.userId) {
      query = query.withIndex("by_user", (q) => q.eq("userId", args.userId!));
    }

    const properties = await query.order("desc").collect();

    return properties.map((prop) => ({
      _id: prop._id,
      id: prop._id,
      name: prop.name,
      address: prop.address,
      city: prop.city,
      state: prop.state,
      zipCode: prop.zipCode,
      propertyType: prop.propertyType,
      units: prop.units,
      monthlyRent: prop.monthlyRent,
      purchasePrice: prop.purchasePrice,
      currentValue: prop.currentValue,
      mortgageLoanBalance: prop.mortgageLoanBalance,
      mortgageAPR: prop.mortgageAPR,
      mortgageMonthlyPayment: prop.mortgageMonthlyPayment,
      imageURL: prop.imageURL,
      notes: prop.notes,
      createdAt: prop.createdAt,
      updatedAt: prop.updatedAt,
    }));
  },
});

/**
 * Get a single property by ID
 */
export const get = query({
  args: { id: v.id("properties") },
  handler: async (ctx, args) => {
    const property = await ctx.db.get(args.id);
    if (!property) {
      throw new Error("Property not found");
    }

    return {
      _id: property._id,
      id: property._id,
      name: property.name,
      address: property.address,
      city: property.city,
      state: property.state,
      zipCode: property.zipCode,
      propertyType: property.propertyType,
      units: property.units,
      monthlyRent: property.monthlyRent,
      purchasePrice: property.purchasePrice,
      currentValue: property.currentValue,
      mortgageLoanBalance: property.mortgageLoanBalance,
      mortgageAPR: property.mortgageAPR,
      mortgageMonthlyPayment: property.mortgageMonthlyPayment,
      imageURL: property.imageURL,
      notes: property.notes,
      createdAt: property.createdAt,
      updatedAt: property.updatedAt,
    };
  },
});

/**
 * Create a new property
 */
export const create = mutation({
  args: {
    name: v.string(),
    address: v.string(),
    city: v.string(),
    state: v.string(),
    zipCode: v.string(),
    propertyType: v.string(),
    units: v.number(),
    monthlyRent: v.number(),
    purchasePrice: v.optional(v.number()),
    currentValue: v.optional(v.number()),
    mortgageLoanBalance: v.optional(v.number()),
    mortgageAPR: v.optional(v.number()),
    mortgageMonthlyPayment: v.optional(v.number()),
    imageURL: v.optional(v.string()),
    notes: v.optional(v.string()),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const user = await ctx.db.get(args.userId);
    if (!user) {
      throw new Error("User not found");
    }

    const ownerAccount = isOwnerEmail(user.email);
    if (!user.isPremium && !ownerAccount) {
      const existing = await ctx.db
        .query("properties")
        .withIndex("by_user", (q) => q.eq("userId", args.userId))
        .collect();
      if (existing.length >= FREE_PROPERTY_LIMIT) {
        throw new Error(
          `Free plan limit reached (max ${FREE_PROPERTY_LIMIT} properties). Upgrade to add more.`
        );
      }
    }

    const propertyId = await ctx.db.insert("properties", {
      name: args.name,
      address: args.address,
      city: args.city,
      state: args.state,
      zipCode: args.zipCode,
      propertyType: args.propertyType,
      units: args.units,
      monthlyRent: args.monthlyRent,
      purchasePrice: args.purchasePrice,
      currentValue: args.currentValue,
      mortgageLoanBalance: args.mortgageLoanBalance,
      mortgageAPR: args.mortgageAPR,
      mortgageMonthlyPayment: args.mortgageMonthlyPayment,
      imageURL: args.imageURL,
      notes: args.notes,
      userId: args.userId,
      createdAt: now,
      updatedAt: now,
    });

    const property = await ctx.db.get(propertyId);
    return {
      _id: property!._id,
      id: property!._id,
      name: property!.name,
      address: property!.address,
      city: property!.city,
      state: property!.state,
      zipCode: property!.zipCode,
      propertyType: property!.propertyType,
      units: property!.units,
      monthlyRent: property!.monthlyRent,
      purchasePrice: property!.purchasePrice,
      currentValue: property!.currentValue,
      mortgageLoanBalance: property!.mortgageLoanBalance,
      mortgageAPR: property!.mortgageAPR,
      mortgageMonthlyPayment: property!.mortgageMonthlyPayment,
      imageURL: property!.imageURL,
      notes: property!.notes,
      createdAt: property!.createdAt,
      updatedAt: property!.updatedAt,
    };
  },
});

/**
 * Update an existing property
 */
export const update = mutation({
  args: {
    id: v.id("properties"),
    name: v.optional(v.string()),
    address: v.optional(v.string()),
    city: v.optional(v.string()),
    state: v.optional(v.string()),
    zipCode: v.optional(v.string()),
    propertyType: v.optional(v.string()),
    units: v.optional(v.number()),
    monthlyRent: v.optional(v.number()),
    purchasePrice: v.optional(v.number()),
    currentValue: v.optional(v.number()),
    mortgageLoanBalance: v.optional(v.number()),
    mortgageAPR: v.optional(v.number()),
    mortgageMonthlyPayment: v.optional(v.number()),
    clearMortgageLoanBalance: v.optional(v.boolean()),
    clearMortgageAPR: v.optional(v.boolean()),
    clearMortgageMonthlyPayment: v.optional(v.boolean()),
    imageURL: v.optional(v.string()),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const {
      id,
      clearMortgageLoanBalance,
      clearMortgageAPR,
      clearMortgageMonthlyPayment,
      ...updates
    } = args;
    const property = await ctx.db.get(id);
    if (!property) {
      throw new Error("Property not found");
    }

    const patch: Record<string, any> = {
      ...updates,
      updatedAt: Date.now(),
    };

    if (clearMortgageLoanBalance) {
      patch.mortgageLoanBalance = undefined;
    }
    if (clearMortgageAPR) {
      patch.mortgageAPR = undefined;
    }
    if (clearMortgageMonthlyPayment) {
      patch.mortgageMonthlyPayment = undefined;
    }

    await ctx.db.patch(id, {
      ...patch,
    });

    const updated = await ctx.db.get(id);
    return {
      _id: updated!._id,
      id: updated!._id,
      name: updated!.name,
      address: updated!.address,
      city: updated!.city,
      state: updated!.state,
      zipCode: updated!.zipCode,
      propertyType: updated!.propertyType,
      units: updated!.units,
      monthlyRent: updated!.monthlyRent,
      purchasePrice: updated!.purchasePrice,
      currentValue: updated!.currentValue,
      mortgageLoanBalance: updated!.mortgageLoanBalance,
      mortgageAPR: updated!.mortgageAPR,
      mortgageMonthlyPayment: updated!.mortgageMonthlyPayment,
      imageURL: updated!.imageURL,
      notes: updated!.notes,
      createdAt: updated!.createdAt,
      updatedAt: updated!.updatedAt,
    };
  },
});

/**
 * Delete a property
 */
export const deleteProperty = mutation({
  args: { id: v.id("properties") },
  handler: async (ctx, args) => {
    const property = await ctx.db.get(args.id);
    if (!property) {
      throw new Error("Property not found");
    }

    await ctx.db.delete(args.id);
    return { success: true };
  },
});

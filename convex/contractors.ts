import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

/**
 * List all contractors
 */
export const list = query({
  args: {
    userId: v.optional(v.id("users")),
    specialty: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    let query = ctx.db.query("contractors");

    if (args.userId) {
      query = query.withIndex("by_user", (q) => q.eq("userId", args.userId!));
    }

    const contractors = await query.collect();

    let filtered = contractors;
    if (args.specialty) {
      filtered = contractors.filter((c) =>
        c.specialty.includes(args.specialty!)
      );
    }

    return filtered.map((contractor) => ({
      _id: contractor._id,
      id: contractor._id,
      companyName: contractor.companyName,
      contactName: contractor.contactName,
      email: contractor.email,
      phone: contractor.phone,
      specialty: contractor.specialty,
      hourlyRate: contractor.hourlyRate,
      rating: contractor.rating,
      isPreferred: contractor.isPreferred,
      createdAt: contractor.createdAt,
      updatedAt: contractor.updatedAt,
    }));
  },
});

/**
 * Create a new contractor
 */
export const create = mutation({
  args: {
    companyName: v.string(),
    contactName: v.string(),
    email: v.string(),
    phone: v.string(),
    specialty: v.array(v.string()),
    hourlyRate: v.optional(v.number()),
    rating: v.optional(v.number()),
    isPreferred: v.boolean(),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const contractorId = await ctx.db.insert("contractors", {
      companyName: args.companyName,
      contactName: args.contactName,
      email: args.email,
      phone: args.phone,
      specialty: args.specialty,
      hourlyRate: args.hourlyRate,
      rating: args.rating,
      isPreferred: args.isPreferred,
      userId: args.userId,
      createdAt: now,
      updatedAt: now,
    });

    const contractor = await ctx.db.get(contractorId);
    return {
      _id: contractor!._id,
      id: contractor!._id,
      companyName: contractor!.companyName,
      contactName: contractor!.contactName,
      email: contractor!.email,
      phone: contractor!.phone,
      specialty: contractor!.specialty,
      hourlyRate: contractor!.hourlyRate,
      rating: contractor!.rating,
      isPreferred: contractor!.isPreferred,
      createdAt: contractor!.createdAt,
      updatedAt: contractor!.updatedAt,
    };
  },
});

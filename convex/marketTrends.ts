import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

export const list = query({
  args: {
    userId: v.optional(v.id("users")),
    propertyId: v.optional(v.id("properties")),
  },
  handler: async (ctx, args) => {
    const rows = args.userId
      ? await ctx.db
          .query("marketTrends")
          .withIndex("by_user", (idx) => idx.eq("userId", args.userId))
          .order("desc")
          .collect()
      : await ctx.db.query("marketTrends").order("desc").collect();

    if (args.propertyId) {
      return rows.filter((row) => row.propertyId === args.propertyId);
    }
    return rows;
  },
});

export const create = mutation({
  args: {
    userId: v.id("users"),
    propertyId: v.optional(v.id("properties")),
    title: v.string(),
    marketType: v.string(),
    areaLabel: v.string(),
    estimatePrice: v.optional(v.number()),
    estimateRent: v.optional(v.number()),
    yoyChangePct: v.optional(v.number()),
    demandLevel: v.optional(v.string()),
    source: v.optional(v.string()),
    sourceURL: v.optional(v.string()),
    notes: v.optional(v.string()),
    observedAt: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const id = await ctx.db.insert("marketTrends", {
      userId: args.userId,
      propertyId: args.propertyId,
      title: args.title,
      marketType: args.marketType,
      areaLabel: args.areaLabel,
      estimatePrice: args.estimatePrice,
      estimateRent: args.estimateRent,
      yoyChangePct: args.yoyChangePct,
      demandLevel: args.demandLevel,
      source: args.source,
      sourceURL: args.sourceURL,
      notes: args.notes,
      observedAt: args.observedAt ?? now,
      createdAt: now,
      updatedAt: now,
    });

    return await ctx.db.get(id);
  },
});

export const update = mutation({
  args: {
    id: v.id("marketTrends"),
    title: v.optional(v.string()),
    marketType: v.optional(v.string()),
    areaLabel: v.optional(v.string()),
    estimatePrice: v.optional(v.number()),
    estimateRent: v.optional(v.number()),
    yoyChangePct: v.optional(v.number()),
    demandLevel: v.optional(v.string()),
    source: v.optional(v.string()),
    sourceURL: v.optional(v.string()),
    notes: v.optional(v.string()),
    observedAt: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const { id, ...patch } = args;
    const existing = await ctx.db.get(id);
    if (!existing) {
      throw new Error("Market trend not found");
    }

    await ctx.db.patch(id, {
      ...patch,
      updatedAt: Date.now(),
    });

    return await ctx.db.get(id);
  },
});

export const remove = mutation({
  args: {
    id: v.id("marketTrends"),
  },
  handler: async (ctx, args) => {
    await ctx.db.delete(args.id);
    return { success: true };
  },
});

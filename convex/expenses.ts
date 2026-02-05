import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

/**
 * List expenses
 */
export const list = query({
  args: {
    userId: v.optional(v.id("users")),
    propertyId: v.optional(v.id("properties")),
  },
  handler: async (ctx, args) => {
    let query = ctx.db.query("expenses");

    if (args.propertyId) {
      query = query.withIndex("by_property", (q) =>
        q.eq("propertyId", args.propertyId!)
      );
    } else if (args.userId) {
      query = query.withIndex("by_user", (q) => q.eq("userId", args.userId!));
    }

    const expenses = await query.collect();

    return expenses.map((exp) => ({
      _id: exp._id,
      id: exp._id,
      propertyId: exp.propertyId,
      title: exp.title,
      description: exp.description,
      amount: exp.amount,
      category: exp.category,
      date: exp.date,
      isRecurring: exp.isRecurring,
      recurringFrequency: exp.recurringFrequency,
      receiptURL: exp.receiptURL,
      vendor: exp.vendor,
      notes: exp.notes,
      createdAt: exp.createdAt,
    }));
  },
});

/**
 * Create expense
 */
export const create = mutation({
  args: {
    propertyId: v.optional(v.id("properties")),
    title: v.string(),
    description: v.optional(v.string()),
    amount: v.number(),
    category: v.string(),
    date: v.number(),
    isRecurring: v.boolean(),
    recurringFrequency: v.optional(v.string()),
    receiptURL: v.optional(v.string()),
    vendor: v.optional(v.string()),
    notes: v.optional(v.string()),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const expenseId = await ctx.db.insert("expenses", {
      propertyId: args.propertyId,
      title: args.title,
      description: args.description,
      amount: args.amount,
      category: args.category,
      date: args.date,
      isRecurring: args.isRecurring,
      recurringFrequency: args.recurringFrequency,
      receiptURL: args.receiptURL,
      vendor: args.vendor,
      notes: args.notes,
      userId: args.userId,
      createdAt: now,
    });

    const expense = await ctx.db.get(expenseId);
    return {
      _id: expense!._id,
      id: expense!._id,
      propertyId: expense!.propertyId,
      title: expense!.title,
      description: expense!.description,
      amount: expense!.amount,
      category: expense!.category,
      date: expense!.date,
      isRecurring: expense!.isRecurring,
      recurringFrequency: expense!.recurringFrequency,
      receiptURL: expense!.receiptURL,
      vendor: expense!.vendor,
      notes: expense!.notes,
      createdAt: expense!.createdAt,
    };
  },
});

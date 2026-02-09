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

/**
 * Update expense
 */
export const update = mutation({
  args: {
    id: v.id("expenses"),
    propertyId: v.optional(v.id("properties")),
    clearPropertyId: v.optional(v.boolean()),
    title: v.optional(v.string()),
    description: v.optional(v.string()),
    amount: v.optional(v.number()),
    category: v.optional(v.string()),
    date: v.optional(v.number()),
    isRecurring: v.optional(v.boolean()),
    recurringFrequency: v.optional(v.string()),
    receiptURL: v.optional(v.string()),
    vendor: v.optional(v.string()),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { id, clearPropertyId, ...updates } = args;
    const expense = await ctx.db.get(id);
    if (!expense) {
      throw new Error("Expense not found");
    }

    const patch: Record<string, any> = {};

    if (clearPropertyId) {
      patch.propertyId = undefined;
    } else if (updates.propertyId !== undefined) {
      patch.propertyId = updates.propertyId;
    }

    if (updates.title !== undefined) patch.title = updates.title;
    if (updates.description !== undefined) {
      patch.description = updates.description === "" ? undefined : updates.description;
    }
    if (updates.amount !== undefined) patch.amount = updates.amount;
    if (updates.category !== undefined) patch.category = updates.category;
    if (updates.date !== undefined) patch.date = updates.date;
    if (updates.isRecurring !== undefined) patch.isRecurring = updates.isRecurring;
    if (updates.recurringFrequency !== undefined) {
      patch.recurringFrequency = updates.recurringFrequency === "" ? undefined : updates.recurringFrequency;
    }
    if (updates.receiptURL !== undefined) {
      patch.receiptURL = updates.receiptURL === "" ? undefined : updates.receiptURL;
    }
    if (updates.vendor !== undefined) {
      patch.vendor = updates.vendor === "" ? undefined : updates.vendor;
    }
    if (updates.notes !== undefined) {
      patch.notes = updates.notes === "" ? undefined : updates.notes;
    }

    await ctx.db.patch(id, patch);

    const updated = await ctx.db.get(id);
    return {
      _id: updated!._id,
      id: updated!._id,
      propertyId: updated!.propertyId,
      title: updated!.title,
      description: updated!.description,
      amount: updated!.amount,
      category: updated!.category,
      date: updated!.date,
      isRecurring: updated!.isRecurring,
      recurringFrequency: updated!.recurringFrequency,
      receiptURL: updated!.receiptURL,
      vendor: updated!.vendor,
      notes: updated!.notes,
      createdAt: updated!.createdAt,
    };
  },
});

/**
 * Delete expense
 */
export const remove = mutation({
  args: {
    id: v.id("expenses"),
  },
  handler: async (ctx, args) => {
    const expense = await ctx.db.get(args.id);
    if (!expense) {
      throw new Error("Expense not found");
    }
    await ctx.db.delete(args.id);
    return { id: args.id };
  },
});

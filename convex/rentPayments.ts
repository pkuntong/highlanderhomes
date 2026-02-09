import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

/**
 * List rent payments
 */
export const list = query({
  args: {
    userId: v.optional(v.id("users")),
    propertyId: v.optional(v.id("properties")),
    tenantId: v.optional(v.id("tenants")),
  },
  handler: async (ctx, args) => {
    let query = ctx.db.query("rentPayments");

    if (args.propertyId) {
      query = query.withIndex("by_property", (q) =>
        q.eq("propertyId", args.propertyId!)
      );
    } else if (args.tenantId) {
      query = query.withIndex("by_tenant", (q) =>
        q.eq("tenantId", args.tenantId!)
      );
    } else if (args.userId) {
      query = query.withIndex("by_user", (q) => q.eq("userId", args.userId!));
    }

    const payments = await query.collect();

    return payments.map((payment) => ({
      _id: payment._id,
      id: payment._id,
      propertyId: payment.propertyId,
      tenantId: payment.tenantId,
      amount: payment.amount,
      paymentDate: payment.paymentDate,
      dueDate: payment.dueDate,
      paymentMethod: payment.paymentMethod,
      status: payment.status,
      transactionId: payment.transactionId,
      notes: payment.notes,
      createdAt: payment.createdAt,
    }));
  },
});

/**
 * Create rent payment
 */
export const create = mutation({
  args: {
    propertyId: v.id("properties"),
    tenantId: v.optional(v.id("tenants")),
    amount: v.number(),
    paymentDate: v.number(),
    dueDate: v.optional(v.number()),
    paymentMethod: v.optional(v.string()),
    status: v.string(),
    transactionId: v.optional(v.string()),
    notes: v.optional(v.string()),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const paymentDoc: Record<string, any> = {
      propertyId: args.propertyId,
      amount: args.amount,
      paymentDate: args.paymentDate,
      dueDate: args.dueDate ?? args.paymentDate,
      status: args.status,
      userId: args.userId,
      createdAt: now,
    };

    if (args.tenantId) paymentDoc.tenantId = args.tenantId;
    if (args.paymentMethod) paymentDoc.paymentMethod = args.paymentMethod;
    if (args.transactionId) paymentDoc.transactionId = args.transactionId;
    if (args.notes) paymentDoc.notes = args.notes;

    const paymentId = await ctx.db.insert("rentPayments", paymentDoc);

    const payment = await ctx.db.get(paymentId);
    return {
      _id: payment!._id,
      id: payment!._id,
      propertyId: payment!.propertyId,
      tenantId: payment!.tenantId,
      amount: payment!.amount,
      paymentDate: payment!.paymentDate,
      dueDate: payment!.dueDate,
      paymentMethod: payment!.paymentMethod,
      status: payment!.status,
      transactionId: payment!.transactionId,
      notes: payment!.notes,
      createdAt: payment!.createdAt,
    };
  },
});

/**
 * Update rent payment
 */
export const update = mutation({
  args: {
    id: v.id("rentPayments"),
    propertyId: v.optional(v.id("properties")),
    tenantId: v.optional(v.id("tenants")),
    clearTenantId: v.optional(v.boolean()),
    amount: v.optional(v.number()),
    paymentDate: v.optional(v.number()),
    dueDate: v.optional(v.number()),
    paymentMethod: v.optional(v.string()),
    status: v.optional(v.string()),
    transactionId: v.optional(v.string()),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { id, clearTenantId, ...updates } = args;
    const payment = await ctx.db.get(id);
    if (!payment) {
      throw new Error("Rent payment not found");
    }

    const patch: Record<string, any> = {};

    if (updates.propertyId !== undefined) patch.propertyId = updates.propertyId;
    if (clearTenantId) {
      patch.tenantId = undefined;
    } else if (updates.tenantId !== undefined) {
      patch.tenantId = updates.tenantId;
    }
    if (updates.amount !== undefined) patch.amount = updates.amount;
    if (updates.paymentDate !== undefined) patch.paymentDate = updates.paymentDate;
    if (updates.dueDate !== undefined) patch.dueDate = updates.dueDate;
    if (updates.paymentMethod !== undefined) {
      patch.paymentMethod = updates.paymentMethod === "" ? undefined : updates.paymentMethod;
    }
    if (updates.status !== undefined) patch.status = updates.status;
    if (updates.transactionId !== undefined) {
      patch.transactionId = updates.transactionId === "" ? undefined : updates.transactionId;
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
      tenantId: updated!.tenantId,
      amount: updated!.amount,
      paymentDate: updated!.paymentDate,
      dueDate: updated!.dueDate,
      paymentMethod: updated!.paymentMethod,
      status: updated!.status,
      transactionId: updated!.transactionId,
      notes: updated!.notes,
      createdAt: updated!.createdAt,
    };
  },
});

/**
 * Delete rent payment
 */
export const remove = mutation({
  args: {
    id: v.id("rentPayments"),
  },
  handler: async (ctx, args) => {
    const payment = await ctx.db.get(args.id);
    if (!payment) {
      throw new Error("Rent payment not found");
    }
    await ctx.db.delete(args.id);
    return { id: args.id };
  },
});

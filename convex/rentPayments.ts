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

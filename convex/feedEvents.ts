import { v } from "convex/values";
import { query } from "./_generated/server";

/**
 * List feed events for a user
 */
export const list = query({
  args: {
    userId: v.id("users"),
    since: v.optional(v.number()),
    limit: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    let query = ctx.db
      .query("feedEvents")
      .withIndex("by_user_timestamp", (q) => q.eq("userId", args.userId))
      .order("desc");

    const events = await query.collect();

    let filtered = events;
    if (args.since) {
      filtered = events.filter((e) => e.timestamp >= args.since!);
    }

    if (args.limit) {
      filtered = filtered.slice(0, args.limit);
    }

    return filtered.map((event) => ({
      _id: event._id,
      id: event._id,
      eventType: event.eventType,
      title: event.title,
      subtitle: event.subtitle,
      detail: event.detail,
      timestamp: event.timestamp,
      isRead: event.isRead,
      isActionRequired: event.isActionRequired,
      actionLabel: event.actionLabel,
      priority: event.priority,
      propertyId: event.propertyId,
      tenantId: event.tenantId,
      maintenanceRequestId: event.maintenanceRequestId,
      contractorId: event.contractorId,
      rentPaymentId: event.rentPaymentId,
    }));
  },
});

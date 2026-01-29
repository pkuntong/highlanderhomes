import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

/**
 * List all maintenance requests
 */
export const list = query({
  args: {
    userId: v.optional(v.id("users")),
    propertyId: v.optional(v.id("properties")),
    status: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    let query = ctx.db.query("maintenanceRequests");

    if (args.status && args.userId) {
      query = query.withIndex("by_user_status", (q) =>
        q.eq("userId", args.userId!).eq("status", args.status!)
      );
    } else if (args.propertyId) {
      query = query.withIndex("by_property", (q) =>
        q.eq("propertyId", args.propertyId!)
      );
    } else if (args.userId) {
      query = query.withIndex("by_user", (q) => q.eq("userId", args.userId!));
    } else if (args.status) {
      query = query.withIndex("by_status", (q) => q.eq("status", args.status!));
    }

    const requests = await query.order("desc").collect();

    return requests.map((req) => ({
      _id: req._id,
      id: req._id,
      propertyId: req.propertyId,
      tenantId: req.tenantId,
      contractorId: req.contractorId,
      title: req.title,
      description: req.descriptionText,
      category: req.category,
      priority: req.priority,
      status: req.status,
      photoURLs: req.photoURLs,
      scheduledDate: req.scheduledDate,
      completedDate: req.completedDate,
      estimatedCost: req.estimatedCost,
      actualCost: req.actualCost,
      notes: req.notes,
      createdAt: req.createdAt,
      updatedAt: req.updatedAt,
    }));
  },
});

/**
 * Create a new maintenance request
 */
export const create = mutation({
  args: {
    propertyId: v.id("properties"),
    tenantId: v.optional(v.id("tenants")),
    title: v.string(),
    descriptionText: v.string(),
    category: v.string(),
    priority: v.string(),
    photoURLs: v.optional(v.array(v.string())),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const requestId = await ctx.db.insert("maintenanceRequests", {
      propertyId: args.propertyId,
      tenantId: args.tenantId,
      title: args.title,
      descriptionText: args.descriptionText,
      category: args.category,
      priority: args.priority,
      status: "new",
      photoURLs: args.photoURLs,
      userId: args.userId,
      createdAt: now,
      updatedAt: now,
    });

    const request = await ctx.db.get(requestId);
    return {
      _id: request!._id,
      id: request!._id,
      propertyId: request!.propertyId,
      tenantId: request!.tenantId,
      contractorId: request!.contractorId,
      title: request!.title,
      description: request!.descriptionText,
      category: request!.category,
      priority: request!.priority,
      status: request!.status,
      photoURLs: request!.photoURLs,
      scheduledDate: request!.scheduledDate,
      completedDate: request!.completedDate,
      estimatedCost: request!.estimatedCost,
      actualCost: request!.actualCost,
      notes: request!.notes,
      createdAt: request!.createdAt,
      updatedAt: request!.updatedAt,
    };
  },
});

/**
 * Update maintenance request status
 */
export const updateStatus = mutation({
  args: {
    id: v.id("maintenanceRequests"),
    status: v.string(),
  },
  handler: async (ctx, args) => {
    const request = await ctx.db.get(args.id);
    if (!request) {
      throw new Error("Maintenance request not found");
    }

    const updates: any = {
      status: args.status,
      updatedAt: Date.now(),
    };

    if (args.status === "completed") {
      updates.completedDate = Date.now();
    }

    await ctx.db.patch(args.id, updates);

    const updated = await ctx.db.get(args.id);
    return {
      _id: updated!._id,
      id: updated!._id,
      propertyId: updated!.propertyId,
      tenantId: updated!.tenantId,
      contractorId: updated!.contractorId,
      title: updated!.title,
      description: updated!.descriptionText,
      category: updated!.category,
      priority: updated!.priority,
      status: updated!.status,
      photoURLs: updated!.photoURLs,
      scheduledDate: updated!.scheduledDate,
      completedDate: updated!.completedDate,
      estimatedCost: updated!.estimatedCost,
      actualCost: updated!.actualCost,
      notes: updated!.notes,
      createdAt: updated!.createdAt,
      updatedAt: updated!.updatedAt,
    };
  },
});

/**
 * Assign a contractor to a maintenance request
 */
export const assignContractor = mutation({
  args: {
    requestId: v.id("maintenanceRequests"),
    contractorId: v.id("contractors"),
  },
  handler: async (ctx, args) => {
    const request = await ctx.db.get(args.requestId);
    if (!request) {
      throw new Error("Maintenance request not found");
    }

    await ctx.db.patch(args.requestId, {
      contractorId: args.contractorId,
      status: request.status === "new" ? "acknowledged" : request.status,
      updatedAt: Date.now(),
    });

    const updated = await ctx.db.get(args.requestId);
    return {
      _id: updated!._id,
      id: updated!._id,
      propertyId: updated!.propertyId,
      tenantId: updated!.tenantId,
      contractorId: updated!.contractorId,
      title: updated!.title,
      description: updated!.descriptionText,
      category: updated!.category,
      priority: updated!.priority,
      status: updated!.status,
      photoURLs: updated!.photoURLs,
      scheduledDate: updated!.scheduledDate,
      completedDate: updated!.completedDate,
      estimatedCost: updated!.estimatedCost,
      actualCost: updated!.actualCost,
      notes: updated!.notes,
      createdAt: updated!.createdAt,
      updatedAt: updated!.updatedAt,
    };
  },
});

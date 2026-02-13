import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

/**
 * Generate a secure one-time upload URL for document upload.
 */
export const generateUploadUrl = mutation({
  args: {},
  handler: async (ctx) => {
    return await ctx.storage.generateUploadUrl();
  },
});

/**
 * Save document metadata after file upload.
 */
export const create = mutation({
  args: {
    userId: v.id("users"),
    propertyId: v.optional(v.id("properties")),
    tenantId: v.optional(v.id("tenants")),
    title: v.string(),
    category: v.string(),
    storageId: v.id("_storage"),
    contentType: v.optional(v.string()),
    fileSizeBytes: v.optional(v.number()),
    notes: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const id = await ctx.db.insert("documents", {
      userId: args.userId,
      propertyId: args.propertyId,
      tenantId: args.tenantId,
      title: args.title,
      category: args.category,
      storageId: args.storageId,
      contentType: args.contentType,
      fileSizeBytes: args.fileSizeBytes,
      notes: args.notes,
      createdAt: now,
      updatedAt: now,
    });

    const doc = await ctx.db.get(id);
    const downloadURL = doc ? await ctx.storage.getUrl(doc.storageId) : null;
    return {
      _id: doc!._id,
      id: doc!._id,
      userId: doc!.userId,
      propertyId: doc!.propertyId,
      tenantId: doc!.tenantId,
      title: doc!.title,
      category: doc!.category,
      storageId: doc!.storageId,
      contentType: doc!.contentType,
      fileSizeBytes: doc!.fileSizeBytes,
      notes: doc!.notes,
      createdAt: doc!.createdAt,
      updatedAt: doc!.updatedAt,
      downloadURL,
    };
  },
});

/**
 * List documents for a user.
 */
export const list = query({
  args: {
    userId: v.id("users"),
    propertyId: v.optional(v.id("properties")),
    category: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    let docs: any[] = [];

    if (args.propertyId) {
      docs = await ctx.db
        .query("documents")
        .withIndex("by_property", (q) => q.eq("propertyId", args.propertyId!))
        .collect();
      docs = docs.filter((doc) => doc.userId === args.userId);
    } else if (args.category) {
      docs = await ctx.db
        .query("documents")
        .withIndex("by_user_category", (q) =>
          q.eq("userId", args.userId).eq("category", args.category!)
        )
        .collect();
    } else {
      docs = await ctx.db
        .query("documents")
        .withIndex("by_user", (q) => q.eq("userId", args.userId))
        .collect();
    }

    docs.sort((a, b) => b.updatedAt - a.updatedAt);

    return await Promise.all(
      docs.map(async (doc) => {
        const downloadURL = await ctx.storage.getUrl(doc.storageId);
        return {
          _id: doc._id,
          id: doc._id,
          userId: doc.userId,
          propertyId: doc.propertyId,
          tenantId: doc.tenantId,
          title: doc.title,
          category: doc.category,
          storageId: doc.storageId,
          contentType: doc.contentType,
          fileSizeBytes: doc.fileSizeBytes,
          notes: doc.notes,
          createdAt: doc.createdAt,
          updatedAt: doc.updatedAt,
          downloadURL,
        };
      })
    );
  },
});

/**
 * Update document metadata.
 */
export const update = mutation({
  args: {
    id: v.id("documents"),
    title: v.optional(v.string()),
    category: v.optional(v.string()),
    notes: v.optional(v.string()),
    propertyId: v.optional(v.id("properties")),
    clearPropertyId: v.optional(v.boolean()),
    tenantId: v.optional(v.id("tenants")),
    clearTenantId: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    const { id, clearPropertyId, clearTenantId, ...updates } = args;
    const doc = await ctx.db.get(id);
    if (!doc) {
      throw new Error("Document not found");
    }

    const patch: Record<string, any> = {
      updatedAt: Date.now(),
    };

    if (updates.title !== undefined) patch.title = updates.title;
    if (updates.category !== undefined) patch.category = updates.category;
    if (updates.notes !== undefined) {
      patch.notes = updates.notes === "" ? undefined : updates.notes;
    }

    if (clearPropertyId) {
      patch.propertyId = undefined;
    } else if (updates.propertyId !== undefined) {
      patch.propertyId = updates.propertyId;
    }

    if (clearTenantId) {
      patch.tenantId = undefined;
    } else if (updates.tenantId !== undefined) {
      patch.tenantId = updates.tenantId;
    }

    await ctx.db.patch(id, patch);

    const updated = await ctx.db.get(id);
    const downloadURL = updated ? await ctx.storage.getUrl(updated.storageId) : null;
    return {
      _id: updated!._id,
      id: updated!._id,
      userId: updated!.userId,
      propertyId: updated!.propertyId,
      tenantId: updated!.tenantId,
      title: updated!.title,
      category: updated!.category,
      storageId: updated!.storageId,
      contentType: updated!.contentType,
      fileSizeBytes: updated!.fileSizeBytes,
      notes: updated!.notes,
      createdAt: updated!.createdAt,
      updatedAt: updated!.updatedAt,
      downloadURL,
    };
  },
});

/**
 * Delete document metadata and underlying file.
 */
export const remove = mutation({
  args: {
    id: v.id("documents"),
  },
  handler: async (ctx, args) => {
    const doc = await ctx.db.get(args.id);
    if (!doc) {
      throw new Error("Document not found");
    }
    await ctx.storage.delete(doc.storageId);
    await ctx.db.delete(args.id);
    return { id: args.id };
  },
});

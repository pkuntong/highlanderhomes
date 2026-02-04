import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

/**
 * Get current user
 * Note: In production, get userId from auth token
 */
export const current = query({
  args: {
    userId: v.optional(v.id("users")),
  },
  handler: async (ctx, args) => {
    if (!args.userId) {
      return null;
    }

    const user = await ctx.db.get(args.userId);
    if (!user) {
      return null;
    }

    return {
      _id: user._id,
      id: user._id,
      name: user.name,
      email: user.email,
      avatarURL: user.avatarURL,
      isPremium: user.isPremium,
      emailVerified: user.emailVerified,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    };
  },
});

/**
 * Update user profile
 */
export const update = mutation({
  args: {
    userId: v.id("users"),
    name: v.optional(v.string()),
    email: v.optional(v.string()),
    avatarURL: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { userId, ...updates } = args;
    const user = await ctx.db.get(userId);
    if (!user) {
      throw new Error("User not found");
    }

    if (updates.email) {
      updates.email = updates.email.trim().toLowerCase();
    }

    await ctx.db.patch(userId, updates);

    const updated = await ctx.db.get(userId);
    return {
      _id: updated!._id,
      id: updated!._id,
      name: updated!.name,
      email: updated!.email,
      avatarURL: updated!.avatarURL,
      isPremium: updated!.isPremium,
      emailVerified: updated!.emailVerified,
      createdAt: updated!.createdAt,
      lastLoginAt: updated!.lastLoginAt,
    };
  },
});

/**
 * Delete user account and all related data
 */
export const deleteAccount = mutation({
  args: {
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const userId = args.userId;

    const deleteByUser = async (table: string) => {
      const rows = await ctx.db
        .query(table as any)
        .withIndex("by_user", (q: any) => q.eq("userId", userId))
        .collect();
      for (const row of rows) {
        await ctx.db.delete(row._id);
      }
    };

    await deleteByUser("properties");
    await deleteByUser("tenants");
    await deleteByUser("maintenanceRequests");
    await deleteByUser("contractors");
    await deleteByUser("rentPayments");
    await deleteByUser("expenses");
    await deleteByUser("feedEvents");

    await ctx.db.delete(userId);
    return { success: true };
  },
});

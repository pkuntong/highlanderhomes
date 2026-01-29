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
    avatarURL: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { userId, ...updates } = args;
    const user = await ctx.db.get(userId);
    if (!user) {
      throw new Error("User not found");
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
      createdAt: updated!.createdAt,
      lastLoginAt: updated!.lastLoginAt,
    };
  },
});

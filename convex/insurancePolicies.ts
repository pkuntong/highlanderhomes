import { v } from "convex/values";
import { mutation, query } from "./_generated/server";
import { internal } from "./_generated/api";

type InsuranceSeedInput = {
  propertyLabel: string;
  insuranceName: string;
  policyNumber: string;
  term: string;
  premium: string;
  notes?: string;
  agent?: string;
};

const DEFAULT_POLICIES: InsuranceSeedInput[] = [
  {
    propertyLabel: "3441 DUNRAN ROAD, BALTIMORE, MD 21222",
    insuranceName: "CUMBERLAND MUTUAL FIRE INS",
    policyNumber: "CD412685303",
    term: "05/15/2025 to 05/15/2026",
    premium: "$735.00",
    notes: "Paid from PennyMac (mortgage)",
    agent: "Ensurancemax LLC",
  },
  {
    propertyLabel: "1812 Guilford Ave, Baltimore, MD 21202",
    insuranceName: "Safeco",
    policyNumber: "Policy OF3278498",
    term: "Jul 30, 2025 - Jul 30, 2026",
    premium: "$3,568.00",
    notes: "Lender - SELECT PORTFOLIO SERVICINGINC",
  },
  {
    propertyLabel: "3140 Ryerson Cir, Halethorpe MD 21227",
    insuranceName: "Safeco",
    policyNumber: "Policy OF3300307",
    term: "Oct 1, 2025 - Oct 1, 2026",
    premium: "$1,452.00",
    notes: "Lender - FIRST NATIONAL BANK OF PENNSYL",
  },
  {
    propertyLabel: "7304 Mayhill Dr Gaithersburg, MD 20879",
    insuranceName: "Travelers",
    policyNumber: "613968422-653-1",
    term: "05/15/2025 to 05/15/2026",
    premium: "$1,180",
    notes: "https://selfservice.travelers.com/personal/myt/billing",
    agent: "ENSURANCEMAX LLC 301 540 8447",
  },
  {
    propertyLabel: "405 Burbank Ct, Halethorpe, MD 21227",
    insuranceName: "Travelers",
    policyNumber: "617089554 653 1",
    term: "Mar 12, 2025 to Mar 12, 2026",
    premium: "$869",
    notes: "https://selfservice.travelers.com/personal/myt",
    agent: "ENSURANCEMAX LLC 301 540 8446",
  },
  {
    propertyLabel: "19921 Silverfield dr.",
    insuranceName: "The Philadelphia Contributionship",
    policyNumber: "HO00288084",
    term: "06/30/2024 to 06/30/2025",
    premium: "$2,483",
  },
];

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

function normalizeLabel(label: string) {
  return label.toLowerCase().replace(/[^a-z0-9]/g, "");
}

function normalizePolicyNumber(value: string) {
  return value.replace(/^policy\s+/i, "").trim();
}

function parsePremium(value: string) {
  const cleaned = value.replace(/[^0-9.]/g, "");
  const parsed = Number.parseFloat(cleaned);
  return Number.isNaN(parsed) ? 0 : parsed;
}

function parseDate(value: string) {
  const cleaned = value.replace(/\s+/g, " ").trim();
  const parsed = Date.parse(cleaned);
  if (Number.isNaN(parsed)) {
    throw new Error(`Unable to parse date: "${value}"`);
  }
  return parsed;
}

function parseTerm(term: string) {
  const normalized = term
    .replace(/\s+to\s+/i, " | ")
    .replace(/\s*-\s*/g, " | ")
    .replace(/\s+–\s+/g, " | ");
  const parts = normalized
    .split("|")
    .map((part) => part.trim())
    .filter(Boolean);

  if (parts.length < 2) {
    throw new Error(`Unable to parse policy term: "${term}"`);
  }

  return {
    termStart: parseDate(parts[0]),
    termEnd: parseDate(parts[1]),
  };
}

async function resolveUserId(
  ctx: any,
  args: { userId?: string; ownerEmail?: string }
) {
  if (args.userId) return args.userId;
  if (!args.ownerEmail) {
    throw new Error("userId or ownerEmail is required.");
  }
  const user = await ctx.runQuery(internal.authInternal.findUserByEmail, {
    email: normalizeEmail(args.ownerEmail),
  });
  if (!user) {
    throw new Error("User not found for email.");
  }
  return user._id;
}

async function buildPropertyMap(ctx: any, userId: string) {
  const properties = await ctx.db
    .query("properties")
    .withIndex("by_user", (q) => q.eq("userId", userId as any))
    .collect();
  const map = new Map<string, string>();

  for (const property of properties) {
    const label = `${property.address}, ${property.city}, ${property.state} ${property.zipCode}`;
    map.set(normalizeLabel(label), property._id);
    map.set(normalizeLabel(property.name), property._id);
  }

  return map;
}

async function insertPolicies(
  ctx: any,
  userId: string,
  policies: InsuranceSeedInput[]
) {
  const existing = await ctx.db
    .query("insurancePolicies")
    .withIndex("by_user", (q) => q.eq("userId", userId as any))
    .collect();
  const existingKeys = new Set(
    existing.map(
      (policy) =>
        `${normalizeLabel(policy.propertyLabel)}|${policy.policyNumber}`.toLowerCase()
    )
  );

  const propertyMap = await buildPropertyMap(ctx, userId);

  let created = 0;
  let skipped = 0;
  const now = Date.now();

  for (const policy of policies) {
    const policyNumber = normalizePolicyNumber(policy.policyNumber);
    const key = `${normalizeLabel(policy.propertyLabel)}|${policyNumber}`.toLowerCase();
    if (existingKeys.has(key)) {
      skipped += 1;
      continue;
    }

    const { termStart, termEnd } = parseTerm(policy.term);
    const propertyId = propertyMap.get(normalizeLabel(policy.propertyLabel));

    await ctx.db.insert("insurancePolicies", {
      propertyId: propertyId as any,
      propertyLabel: policy.propertyLabel,
      insuranceName: policy.insuranceName,
      policyNumber,
      termStart,
      termEnd,
      premium: parsePremium(policy.premium),
      notes: policy.notes,
      agent: policy.agent,
      userId: userId as any,
      createdAt: now,
      updatedAt: now,
    });

    existingKeys.add(key);
    created += 1;
  }

  return { created, skipped };
}

/**
 * List all insurance policies
 */
export const list = query({
  args: {
    userId: v.optional(v.id("users")),
  },
  handler: async (ctx, args) => {
    let query = ctx.db.query("insurancePolicies");
    if (args.userId) {
      query = query.withIndex("by_user", (q) => q.eq("userId", args.userId!));
    }

    const policies = await query.collect();

    return policies.map((policy) => ({
      _id: policy._id,
      id: policy._id,
      propertyId: policy.propertyId,
      propertyLabel: policy.propertyLabel,
      insuranceName: policy.insuranceName,
      policyNumber: policy.policyNumber,
      termStart: policy.termStart,
      termEnd: policy.termEnd,
      premium: policy.premium,
      notes: policy.notes,
      agent: policy.agent,
      createdAt: policy.createdAt,
      updatedAt: policy.updatedAt,
    }));
  },
});

/**
 * Create a new insurance policy
 */
export const create = mutation({
  args: {
    propertyId: v.optional(v.id("properties")),
    propertyLabel: v.string(),
    insuranceName: v.string(),
    policyNumber: v.string(),
    termStart: v.number(),
    termEnd: v.number(),
    premium: v.number(),
    notes: v.optional(v.string()),
    agent: v.optional(v.string()),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const policyId = await ctx.db.insert("insurancePolicies", {
      propertyId: args.propertyId,
      propertyLabel: args.propertyLabel,
      insuranceName: args.insuranceName,
      policyNumber: normalizePolicyNumber(args.policyNumber),
      termStart: args.termStart,
      termEnd: args.termEnd,
      premium: args.premium,
      notes: args.notes,
      agent: args.agent,
      userId: args.userId,
      createdAt: now,
      updatedAt: now,
    });

    const policy = await ctx.db.get(policyId);
    return {
      _id: policy!._id,
      id: policy!._id,
      propertyId: policy!.propertyId,
      propertyLabel: policy!.propertyLabel,
      insuranceName: policy!.insuranceName,
      policyNumber: policy!.policyNumber,
      termStart: policy!.termStart,
      termEnd: policy!.termEnd,
      premium: policy!.premium,
      notes: policy!.notes,
      agent: policy!.agent,
      createdAt: policy!.createdAt,
      updatedAt: policy!.updatedAt,
    };
  },
});

/**
 * Update an insurance policy
 */
export const update = mutation({
  args: {
    id: v.id("insurancePolicies"),
    propertyId: v.optional(v.id("properties")),
    propertyLabel: v.optional(v.string()),
    insuranceName: v.optional(v.string()),
    policyNumber: v.optional(v.string()),
    termStart: v.optional(v.number()),
    termEnd: v.optional(v.number()),
    premium: v.optional(v.number()),
    notes: v.optional(v.string()),
    agent: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { id, ...updates } = args;
    const policy = await ctx.db.get(id);
    if (!policy) {
      throw new Error("Insurance policy not found");
    }

    const patch: Record<string, any> = {
      updatedAt: Date.now(),
    };

    if (updates.propertyId !== undefined) patch.propertyId = updates.propertyId;
    if (updates.propertyLabel !== undefined) patch.propertyLabel = updates.propertyLabel;
    if (updates.insuranceName !== undefined) patch.insuranceName = updates.insuranceName;
    if (updates.policyNumber !== undefined)
      patch.policyNumber = normalizePolicyNumber(updates.policyNumber);
    if (updates.termStart !== undefined) patch.termStart = updates.termStart;
    if (updates.termEnd !== undefined) patch.termEnd = updates.termEnd;
    if (updates.premium !== undefined) patch.premium = updates.premium;
    if (updates.notes !== undefined) patch.notes = updates.notes;
    if (updates.agent !== undefined) patch.agent = updates.agent;

    await ctx.db.patch(id, patch);

    const updated = await ctx.db.get(id);
    return {
      _id: updated!._id,
      id: updated!._id,
      propertyId: updated!.propertyId,
      propertyLabel: updated!.propertyLabel,
      insuranceName: updated!.insuranceName,
      policyNumber: updated!.policyNumber,
      termStart: updated!.termStart,
      termEnd: updated!.termEnd,
      premium: updated!.premium,
      notes: updated!.notes,
      agent: updated!.agent,
      createdAt: updated!.createdAt,
      updatedAt: updated!.updatedAt,
    };
  },
});

/**
 * Delete an insurance policy
 */
export const remove = mutation({
  args: {
    id: v.id("insurancePolicies"),
  },
  handler: async (ctx, args) => {
    const policy = await ctx.db.get(args.id);
    if (!policy) {
      throw new Error("Insurance policy not found");
    }
    await ctx.db.delete(args.id);
    return { id: args.id };
  },
});

/**
 * Seed default insurance policies for a user
 */
export const seedDefault = mutation({
  args: {
    userId: v.optional(v.id("users")),
    ownerEmail: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const userId = await resolveUserId(ctx, {
      userId: args.userId as any,
      ownerEmail: args.ownerEmail,
    });
    return await insertPolicies(ctx, userId as any, DEFAULT_POLICIES);
  },
});

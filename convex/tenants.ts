import { v } from "convex/values";
import { query, mutation } from "./_generated/server";
import { internal } from "./_generated/api";

type TenantSeedInput = {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  unit?: string;
  propertyLabel: string;
  leaseStartDate: string; // YYYY-MM-DD
  leaseEndDate: string; // YYYY-MM-DD
  monthlyRent: number;
  securityDeposit: number;
  isActive: boolean;
  notes?: string;
  emergencyContactName?: string;
  emergencyContactPhone?: string;
};

const DEFAULT_TENANTS: TenantSeedInput[] = [
  {
    firstName: "Joi",
    lastName: "White",
    email: "Queensimone100@gmail.com",
    phone: "410-536-3454",
    propertyLabel: "3140 Ryerson Cir, Halethorpe, MD 21227",
    leaseStartDate: "2019-03-25",
    leaseEndDate: "2023-03-25",
    monthlyRent: 1600,
    securityDeposit: 1500,
    isActive: true,
  },
  {
    firstName: "Shanta & Pierre",
    lastName: "Watson",
    email: "watsonpierre565@gmail.com",
    phone: "443-583-6112",
    propertyLabel: "3441 Dunran Rd., Baltimore, MD 21222",
    leaseStartDate: "2026-01-01",
    leaseEndDate: "2026-12-31",
    monthlyRent: 1700,
    securityDeposit: 1700,
    isActive: true,
    notes: "Secondary phone: 443-795-2347",
  },
  {
    firstName: "Dwayne",
    lastName: "Powell",
    email: "h2residentialcare@gmail.com",
    phone: "443-630-2900",
    propertyLabel: "1812 Guilford Ave, Baltimore, MD 21202",
    leaseStartDate: "2021-08-01",
    leaseEndDate: "2027-01-31",
    monthlyRent: 5060,
    securityDeposit: 5060,
    isActive: true,
  },
  {
    firstName: "Monique",
    lastName: "Marshal",
    email: "moniquemarshall4u@gmail.com",
    phone: "240-464-3169",
    propertyLabel: "7304 Mayhil Dr., Gaithersburg, MD 20879",
    leaseStartDate: "2022-10-01",
    leaseEndDate: "2027-09-30",
    monthlyRent: 2790,
    securityDeposit: 2790,
    isActive: true,
  },
  {
    firstName: "Enus Ariel",
    lastName: "Zepeda",
    email: "zepedahassler@gmail.com",
    phone: "423-759-2972",
    propertyLabel: "405 Burbank Court, Halethorpe, MD 21227",
    leaseStartDate: "2025-04-01",
    leaseEndDate: "2026-04-01",
    monthlyRent: 1500,
    securityDeposit: 1500,
    isActive: true,
    notes: "Secondary phone: 443-991-6663",
  },
];

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

function titleCase(value: string) {
  return value
    .toLowerCase()
    .split(" ")
    .map((part) => (part ? part[0].toUpperCase() + part.slice(1) : part))
    .join(" ");
}

function parseAddress(label: string) {
  const cleaned = label.replace(/\s+/g, " ").trim();
  const match = cleaned.match(
    /^(.*?),\s*([^,]+?)\s*,?\s*([A-Za-z]{2})\s+(\d{5})(?:-\d{4})?$/
  );
  if (!match) {
    throw new Error(`Unable to parse property address: "${label}"`);
  }
  const address = match[1].trim();
  const city = titleCase(match[2].trim());
  const state = match[3].trim().toUpperCase();
  const zipCode = match[4].trim();
  return {
    name: address,
    address,
    city,
    state,
    zipCode,
  };
}

function toDateMs(date: string) {
  return new Date(`${date}T00:00:00Z`).getTime();
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

async function ensurePropertyId(
  ctx: any,
  userId: string,
  propertyLabel: string,
  monthlyRent: number,
  propertyMap: Map<string, string>,
  createMissingProperties: boolean
) {
  const parsed = parseAddress(propertyLabel);
  const key = `${parsed.address.toLowerCase()}|${parsed.city.toLowerCase()}|${parsed.state.toLowerCase()}|${parsed.zipCode}`;
  const nameKey = parsed.name.toLowerCase();

  const existing = propertyMap.get(key) || propertyMap.get(nameKey);
  if (existing) return existing;

  if (!createMissingProperties) {
    throw new Error(
      `Property not found for "${propertyLabel}". Enable createMissingProperties to create it.`
    );
  }

  const now = Date.now();
  const propertyId = await ctx.db.insert("properties", {
    name: parsed.name,
    address: parsed.address,
    city: parsed.city,
    state: parsed.state,
    zipCode: parsed.zipCode,
    propertyType: "Single Family",
    units: 1,
    monthlyRent,
    purchasePrice: undefined,
    currentValue: undefined,
    imageURL: undefined,
    notes: undefined,
    userId: userId as any,
    createdAt: now,
    updatedAt: now,
  });

  propertyMap.set(key, propertyId);
  propertyMap.set(nameKey, propertyId);
  return propertyId;
}

async function insertTenants(
  ctx: any,
  userId: string,
  tenants: TenantSeedInput[],
  createMissingProperties: boolean
) {
  const existingTenants = await ctx.db
    .query("tenants")
    .withIndex("by_user", (q) => q.eq("userId", userId as any))
    .collect();
  const existingKeys = new Set(
    existingTenants.map((tenant) =>
      `${tenant.email}|${tenant.propertyId}`.toLowerCase()
    )
  );

  const properties = await ctx.db
    .query("properties")
    .withIndex("by_user", (q) => q.eq("userId", userId as any))
    .collect();
  const propertyMap = new Map<string, string>();
  for (const property of properties) {
    const key = `${property.address.toLowerCase()}|${property.city.toLowerCase()}|${property.state.toLowerCase()}|${property.zipCode}`;
    propertyMap.set(key, property._id);
    propertyMap.set(property.name.toLowerCase(), property._id);
  }

  let created = 0;
  let skipped = 0;
  const now = Date.now();

  for (const tenant of tenants) {
    const propertyId = await ensurePropertyId(
      ctx,
      userId,
      tenant.propertyLabel,
      tenant.monthlyRent,
      propertyMap,
      createMissingProperties
    );
    const key = `${tenant.email}|${propertyId}`.toLowerCase();
    if (existingKeys.has(key)) {
      skipped += 1;
      continue;
    }

    await ctx.db.insert("tenants", {
      firstName: tenant.firstName,
      lastName: tenant.lastName,
      email: tenant.email,
      phone: tenant.phone,
      unit: tenant.unit,
      propertyId: propertyId as any,
      leaseStartDate: toDateMs(tenant.leaseStartDate),
      leaseEndDate: toDateMs(tenant.leaseEndDate),
      monthlyRent: tenant.monthlyRent,
      securityDeposit: tenant.securityDeposit,
      isActive: tenant.isActive,
      emergencyContactName: tenant.emergencyContactName,
      emergencyContactPhone: tenant.emergencyContactPhone,
      notes: tenant.notes,
      avatarURL: undefined,
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
 * List all tenants
 */
export const list = query({
  args: {
    userId: v.optional(v.id("users")),
    propertyId: v.optional(v.id("properties")),
  },
  handler: async (ctx, args) => {
    let query = ctx.db.query("tenants");

    if (args.propertyId) {
      query = query.withIndex("by_property", (q) =>
        q.eq("propertyId", args.propertyId!)
      );
    } else if (args.userId) {
      query = query.withIndex("by_user", (q) => q.eq("userId", args.userId!));
    }

    const tenants = await query.collect();

    return tenants.map((tenant) => ({
      _id: tenant._id,
      id: tenant._id,
      firstName: tenant.firstName,
      lastName: tenant.lastName,
      email: tenant.email,
      phone: tenant.phone,
      unit: tenant.unit,
      propertyId: tenant.propertyId,
      leaseStartDate: tenant.leaseStartDate,
      leaseEndDate: tenant.leaseEndDate,
      monthlyRent: tenant.monthlyRent,
      securityDeposit: tenant.securityDeposit,
      isActive: tenant.isActive,
      emergencyContactName: tenant.emergencyContactName,
      emergencyContactPhone: tenant.emergencyContactPhone,
      notes: tenant.notes,
      avatarURL: tenant.avatarURL,
      createdAt: tenant.createdAt,
      updatedAt: tenant.updatedAt,
    }));
  },
});

/**
 * Get a single tenant by ID
 */
export const get = query({
  args: { id: v.id("tenants") },
  handler: async (ctx, args) => {
    const tenant = await ctx.db.get(args.id);
    if (!tenant) {
      throw new Error("Tenant not found");
    }

    return {
      _id: tenant._id,
      id: tenant._id,
      firstName: tenant.firstName,
      lastName: tenant.lastName,
      email: tenant.email,
      phone: tenant.phone,
      unit: tenant.unit,
      propertyId: tenant.propertyId,
      leaseStartDate: tenant.leaseStartDate,
      leaseEndDate: tenant.leaseEndDate,
      monthlyRent: tenant.monthlyRent,
      securityDeposit: tenant.securityDeposit,
      isActive: tenant.isActive,
      emergencyContactName: tenant.emergencyContactName,
      emergencyContactPhone: tenant.emergencyContactPhone,
      notes: tenant.notes,
      avatarURL: tenant.avatarURL,
      createdAt: tenant.createdAt,
      updatedAt: tenant.updatedAt,
    };
  },
});

/**
 * Create a new tenant
 */
export const create = mutation({
  args: {
    firstName: v.string(),
    lastName: v.string(),
    email: v.string(),
    phone: v.string(),
    unit: v.optional(v.string()),
    propertyId: v.id("properties"),
    leaseStartDate: v.number(),
    leaseEndDate: v.number(),
    monthlyRent: v.number(),
    securityDeposit: v.number(),
    isActive: v.boolean(),
    emergencyContactName: v.optional(v.string()),
    emergencyContactPhone: v.optional(v.string()),
    notes: v.optional(v.string()),
    avatarURL: v.optional(v.string()),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const tenantId = await ctx.db.insert("tenants", {
      firstName: args.firstName,
      lastName: args.lastName,
      email: args.email,
      phone: args.phone,
      unit: args.unit,
      propertyId: args.propertyId,
      leaseStartDate: args.leaseStartDate,
      leaseEndDate: args.leaseEndDate,
      monthlyRent: args.monthlyRent,
      securityDeposit: args.securityDeposit,
      isActive: args.isActive,
      emergencyContactName: args.emergencyContactName,
      emergencyContactPhone: args.emergencyContactPhone,
      notes: args.notes,
      avatarURL: args.avatarURL,
      userId: args.userId,
      createdAt: now,
      updatedAt: now,
    });

    const tenant = await ctx.db.get(tenantId);
    return {
      _id: tenant!._id,
      id: tenant!._id,
      firstName: tenant!.firstName,
      lastName: tenant!.lastName,
      email: tenant!.email,
      phone: tenant!.phone,
      unit: tenant!.unit,
      propertyId: tenant!.propertyId,
      leaseStartDate: tenant!.leaseStartDate,
      leaseEndDate: tenant!.leaseEndDate,
      monthlyRent: tenant!.monthlyRent,
      securityDeposit: tenant!.securityDeposit,
      isActive: tenant!.isActive,
      emergencyContactName: tenant!.emergencyContactName,
      emergencyContactPhone: tenant!.emergencyContactPhone,
      notes: tenant!.notes,
      avatarURL: tenant!.avatarURL,
      createdAt: tenant!.createdAt,
      updatedAt: tenant!.updatedAt,
    };
  },
});

/**
 * Update an existing tenant
 */
export const update = mutation({
  args: {
    id: v.id("tenants"),
    firstName: v.optional(v.string()),
    lastName: v.optional(v.string()),
    email: v.optional(v.string()),
    phone: v.optional(v.string()),
    unit: v.optional(v.string()),
    propertyId: v.optional(v.id("properties")),
    leaseStartDate: v.optional(v.number()),
    leaseEndDate: v.optional(v.number()),
    monthlyRent: v.optional(v.number()),
    securityDeposit: v.optional(v.number()),
    isActive: v.optional(v.boolean()),
    emergencyContactName: v.optional(v.string()),
    emergencyContactPhone: v.optional(v.string()),
    notes: v.optional(v.string()),
    avatarURL: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { id, ...updates } = args;
    const tenant = await ctx.db.get(id);
    if (!tenant) {
      throw new Error("Tenant not found");
    }

    await ctx.db.patch(id, {
      ...updates,
      updatedAt: Date.now(),
    });

    const updated = await ctx.db.get(id);
    return {
      _id: updated!._id,
      id: updated!._id,
      firstName: updated!.firstName,
      lastName: updated!.lastName,
      email: updated!.email,
      phone: updated!.phone,
      unit: updated!.unit,
      propertyId: updated!.propertyId,
      leaseStartDate: updated!.leaseStartDate,
      leaseEndDate: updated!.leaseEndDate,
      monthlyRent: updated!.monthlyRent,
      securityDeposit: updated!.securityDeposit,
      isActive: updated!.isActive,
      emergencyContactName: updated!.emergencyContactName,
      emergencyContactPhone: updated!.emergencyContactPhone,
      notes: updated!.notes,
      avatarURL: updated!.avatarURL,
      createdAt: updated!.createdAt,
      updatedAt: updated!.updatedAt,
    };
  },
});

/**
 * Bulk create tenants for a user
 */
export const bulkCreate = mutation({
  args: {
    userId: v.optional(v.id("users")),
    ownerEmail: v.optional(v.string()),
    createMissingProperties: v.optional(v.boolean()),
    tenants: v.array(
      v.object({
        firstName: v.string(),
        lastName: v.string(),
        email: v.string(),
        phone: v.string(),
        unit: v.optional(v.string()),
        propertyLabel: v.string(),
        leaseStartDate: v.string(),
        leaseEndDate: v.string(),
        monthlyRent: v.number(),
        securityDeposit: v.number(),
        isActive: v.boolean(),
        notes: v.optional(v.string()),
        emergencyContactName: v.optional(v.string()),
        emergencyContactPhone: v.optional(v.string()),
      })
    ),
  },
  handler: async (ctx, args) => {
    const userId = await resolveUserId(ctx, {
      userId: args.userId as any,
      ownerEmail: args.ownerEmail,
    });
    return await insertTenants(
      ctx,
      userId as any,
      args.tenants,
      args.createMissingProperties ?? false
    );
  },
});

/**
 * Seed default tenant list for a user
 */
export const seedDefault = mutation({
  args: {
    userId: v.optional(v.id("users")),
    ownerEmail: v.optional(v.string()),
    createMissingProperties: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    const userId = await resolveUserId(ctx, {
      userId: args.userId as any,
      ownerEmail: args.ownerEmail,
    });
    return await insertTenants(
      ctx,
      userId as any,
      DEFAULT_TENANTS,
      args.createMissingProperties ?? true
    );
  },
});

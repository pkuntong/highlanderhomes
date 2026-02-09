import { v } from "convex/values";
import { query, mutation } from "./_generated/server";
import { internal } from "./_generated/api";

type ContractorSeedInput = {
  companyName: string;
  contactName: string;
  address?: string;
  website?: string;
  notes?: string;
  email: string;
  phone: string;
  specialty: string[];
  hourlyRate?: number;
  rating?: number;
  isPreferred: boolean;
};

const DEFAULT_CONTRACTORS: ContractorSeedInput[] = [
  // Handyman
  {
    companyName: "5 Stars Handyman Services LLC",
    contactName: "Ivan Bautista",
    email: "ivanhandyman@yahoo.com",
    phone: "443-850-9591",
    specialty: ["Handyman"],
    isPreferred: false,
  },
  {
    companyName: "Cesar Cifuentes",
    contactName: "Cesar Cifuentes",
    email: "",
    phone: "240-644-4823",
    specialty: ["Handyman"],
    isPreferred: false,
  },
  {
    companyName: "Matt",
    contactName: "Matt",
    email: "",
    phone: "(443) 690-5965",
    specialty: ["Handyman"],
    isPreferred: false,
  },
  {
    companyName: "The Baltimore Handyman Company",
    contactName: "Office",
    email: "info@baltimorehandyman.com",
    phone: "443-352-3580",
    website: "www.baltimorehandyman.com",
    specialty: ["Handyman"],
    isPreferred: false,
  },
  {
    companyName: "The Baltimore Handyman Company",
    contactName: "Jeff Rubin",
    address: "9914 Reisterstown Rd., #312, Owings Mills, MD 21117",
    notes: "AIA - Owner",
    email: "jeff@baltimorehandyman.com",
    phone: "443-352-3580",
    website: "www.baltimoreremodeling.com",
    specialty: ["Handyman"],
    isPreferred: false,
  },
  {
    companyName: "Mr. Appliance of Owings Mills",
    contactName: "Office",
    email: "",
    phone: "(410) 753-6230",
    website: "https://www.mrappliance.com/",
    specialty: ["Appliance Repair"],
    isPreferred: false,
  },

  // Plumbing
  {
    companyName: "Mike Kubas",
    contactName: "Mike Kubas",
    email: "mjkubas1979@gmail.com",
    phone: "410-615-3405",
    specialty: ["Plumbing"],
    isPreferred: false,
  },
  {
    companyName: "Kam Za Mung",
    contactName: "Kam Za Mung",
    email: "",
    phone: "443-324-6265",
    specialty: ["Plumbing"],
    isPreferred: false,
  },
  {
    companyName: "Khai Plumbing and Drain, LLC",
    contactName: "Pau Khan Khai",
    email: "",
    phone: "240-460-5041",
    specialty: ["Plumbing"],
    isPreferred: false,
  },
  {
    companyName: "Catons Plumbing and Drain",
    contactName: "Catons Plumbing and Drain",
    email: "",
    phone: "(410) 391-8746",
    specialty: ["Plumbing"],
    isPreferred: false,
  },
  {
    companyName: "Warrior Plumbing & Heating",
    contactName: "Warrior Plumbing & Heating",
    email: "",
    phone: "(443) 967-3736",
    specialty: ["Plumbing", "HVAC"],
    isPreferred: false,
  },
  {
    companyName: "Marino Plumbing and Heating",
    contactName: "Marino Plumbing and Heating",
    email: "AWAmarinoplumbing@gmail.com",
    phone: "410-747-5615",
    specialty: ["Plumbing", "HVAC"],
    notes: "recommended by Baltimore Handyman company",
    isPreferred: false,
  },

  // Electrical
  {
    companyName: "Wayne",
    contactName: "Wayne",
    email: "",
    phone: "443-790-7702",
    specialty: ["Electrical"],
    isPreferred: false,
  },
  {
    companyName: "Scott Ronzitti",
    contactName: "Scott Ronzitti",
    email: "",
    phone: "443-250-6358",
    specialty: ["Electrical"],
    isPreferred: false,
  },
  {
    companyName: "Milton Electric",
    contactName: "Milton Electric",
    email: "",
    phone: "(410) 834-4106",
    specialty: ["Electrical"],
    isPreferred: false,
  },
  {
    companyName: "Magothy Electric",
    contactName: "Magothy Electric",
    email: "",
    phone: "(410) 220-6619",
    specialty: ["Electrical"],
    isPreferred: false,
  },

  // HVAC
  {
    companyName: "Comfort Systems",
    contactName: "Shawn Dehard",
    email: "",
    phone: "410 236-1139 (cell), 410 529-1879 (office)",
    specialty: ["HVAC"],
    isPreferred: false,
  },
  {
    companyName: "Anchor Mechanical",
    contactName: "Brian Dimick",
    email: "bdimick@anchormech.com",
    phone: "443 564-3437",
    specialty: ["HVAC"],
    isPreferred: false,
  },
  {
    companyName: "JWHC",
    contactName: "Jeremy Wheeler",
    email: "jwheeler528@gmail.com",
    phone: "443 629-7760",
    specialty: ["HVAC"],
    isPreferred: false,
  },
  {
    companyName: "Raymond Mung",
    contactName: "Raymond Mung",
    email: "",
    phone: "301-455-9580",
    specialty: ["HVAC"],
    isPreferred: false,
  },

  // Roofers
  {
    companyName: "Custom Home Renovations",
    contactName: "Jon Poe",
    email: "info@chrhomesmd.com",
    phone: "443-333-1589",
    website: "https://www.chrhomesmd.com/",
    specialty: ["Roofing"],
    isPreferred: false,
  },
  {
    companyName: "Ruff Roofers",
    contactName: "Ruff Roofers",
    email: "",
    phone: "(410) 242-2400",
    specialty: ["Roofing"],
    isPreferred: false,
  },
  {
    companyName: "Kelbie Roofing - rubber flat roof specialists",
    contactName: "Kelbie Roofing - rubber flat roof specialists",
    email: "",
    phone: "410-766-3377",
    specialty: ["Roofing"],
    isPreferred: false,
  },

  // Termite / Pest Control
  {
    companyName: "Solomon's Termite & Pest Control",
    contactName: "Solomon's Termite & Pest Control",
    email: "office@solomonspestcontrol.com",
    phone: "(410) 358-7175",
    specialty: ["Termite", "Pest Control"],
    isPreferred: false,
  },
  {
    companyName: "Troy at Bugout",
    contactName: "Troy",
    email: "",
    phone: "(410) 760-6065",
    website: "www.bugoutinc.com",
    specialty: ["Termite", "Pest Control"],
    isPreferred: false,
  },

  // Basement Waterproofing and Foundation
  {
    companyName: "Bob McCutcheon",
    contactName: "Bob McCutcheon",
    email: "",
    phone: "301-471-4690",
    specialty: ["Basement Waterproofing", "Foundation"],
    isPreferred: false,
  },
  {
    companyName: "Kowalewski Engineering & Contracting",
    contactName: "Jim Kowalewski",
    email: "Jamesmkowalewski@gmail.com",
    phone: "443-799-2340",
    specialty: ["Basement Waterproofing", "Foundation"],
    isPreferred: false,
  },
  {
    companyName: "Structural Solutions, Inc.",
    contactName: "Peter",
    email: "",
    phone: "443 797-7715",
    specialty: ["Basement Waterproofing", "Foundation"],
    isPreferred: false,
  },
];

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
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

async function insertContractors(
  ctx: any,
  userId: string,
  contractors: ContractorSeedInput[]
) {
  const existing = await ctx.db
    .query("contractors")
    .withIndex("by_user", (q) => q.eq("userId", userId as any))
    .collect();
  const existingKeys = new Set(
    existing.map((c) =>
      `${c.companyName}|${c.contactName}|${c.phone}`.toLowerCase()
    )
  );

  let created = 0;
  let skipped = 0;
  const now = Date.now();

  for (const contractor of contractors) {
    const key = `${contractor.companyName}|${contractor.contactName}|${contractor.phone}`.toLowerCase();
    if (existingKeys.has(key)) {
      skipped += 1;
      continue;
    }
    await ctx.db.insert("contractors", {
      companyName: contractor.companyName,
      contactName: contractor.contactName,
      address: contractor.address,
      website: contractor.website,
      notes: contractor.notes,
      email: contractor.email,
      phone: contractor.phone,
      specialty: contractor.specialty,
      hourlyRate: contractor.hourlyRate,
      rating: contractor.rating,
      isPreferred: contractor.isPreferred,
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
 * List all contractors
 */
export const list = query({
  args: {
    userId: v.optional(v.id("users")),
    specialty: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    let query = ctx.db.query("contractors");

    if (args.userId) {
      query = query.withIndex("by_user", (q) => q.eq("userId", args.userId!));
    }

    const contractors = await query.collect();

    let filtered = contractors;
    if (args.specialty) {
      filtered = contractors.filter((c) =>
        c.specialty.includes(args.specialty!)
      );
    }

    return filtered.map((contractor) => ({
      _id: contractor._id,
      id: contractor._id,
      companyName: contractor.companyName,
      contactName: contractor.contactName,
      address: contractor.address,
      website: contractor.website,
      notes: contractor.notes,
      email: contractor.email,
      phone: contractor.phone,
      specialty: contractor.specialty,
      hourlyRate: contractor.hourlyRate,
      rating: contractor.rating,
      isPreferred: contractor.isPreferred,
      createdAt: contractor.createdAt,
      updatedAt: contractor.updatedAt,
    }));
  },
});

/**
 * Create a new contractor
 */
export const create = mutation({
  args: {
    companyName: v.string(),
    contactName: v.string(),
    address: v.optional(v.string()),
    website: v.optional(v.string()),
    notes: v.optional(v.string()),
    email: v.string(),
    phone: v.string(),
    specialty: v.array(v.string()),
    hourlyRate: v.optional(v.number()),
    rating: v.optional(v.number()),
    isPreferred: v.boolean(),
    userId: v.id("users"),
  },
  handler: async (ctx, args) => {
    const now = Date.now();
    const contractorId = await ctx.db.insert("contractors", {
      companyName: args.companyName,
      contactName: args.contactName,
      address: args.address,
      website: args.website,
      notes: args.notes,
      email: args.email,
      phone: args.phone,
      specialty: args.specialty,
      hourlyRate: args.hourlyRate,
      rating: args.rating,
      isPreferred: args.isPreferred,
      userId: args.userId,
      createdAt: now,
      updatedAt: now,
    });

    const contractor = await ctx.db.get(contractorId);
    return {
      _id: contractor!._id,
      id: contractor!._id,
      companyName: contractor!.companyName,
      contactName: contractor!.contactName,
      address: contractor!.address,
      website: contractor!.website,
      notes: contractor!.notes,
      email: contractor!.email,
      phone: contractor!.phone,
      specialty: contractor!.specialty,
      hourlyRate: contractor!.hourlyRate,
      rating: contractor!.rating,
      isPreferred: contractor!.isPreferred,
      createdAt: contractor!.createdAt,
      updatedAt: contractor!.updatedAt,
    };
  },
});

/**
 * Update contractor
 */
export const update = mutation({
  args: {
    id: v.id("contractors"),
    companyName: v.optional(v.string()),
    contactName: v.optional(v.string()),
    address: v.optional(v.string()),
    website: v.optional(v.string()),
    notes: v.optional(v.string()),
    email: v.optional(v.string()),
    phone: v.optional(v.string()),
    specialty: v.optional(v.array(v.string())),
    hourlyRate: v.optional(v.number()),
    rating: v.optional(v.number()),
    isPreferred: v.optional(v.boolean()),
  },
  handler: async (ctx, args) => {
    const { id, ...updates } = args;
    const contractor = await ctx.db.get(id);
    if (!contractor) {
      throw new Error("Contractor not found");
    }

    await ctx.db.patch(id, {
      ...updates,
      updatedAt: Date.now(),
    });

    const updated = await ctx.db.get(id);
    return {
      _id: updated!._id,
      id: updated!._id,
      companyName: updated!.companyName,
      contactName: updated!.contactName,
      address: updated!.address,
      website: updated!.website,
      notes: updated!.notes,
      email: updated!.email,
      phone: updated!.phone,
      specialty: updated!.specialty,
      hourlyRate: updated!.hourlyRate,
      rating: updated!.rating,
      isPreferred: updated!.isPreferred,
      createdAt: updated!.createdAt,
      updatedAt: updated!.updatedAt,
    };
  },
});

/**
 * Bulk create contractors for a user
 */
export const bulkCreate = mutation({
  args: {
    userId: v.optional(v.id("users")),
    ownerEmail: v.optional(v.string()),
    contractors: v.array(
      v.object({
        companyName: v.string(),
        contactName: v.string(),
        address: v.optional(v.string()),
        website: v.optional(v.string()),
        notes: v.optional(v.string()),
        email: v.string(),
        phone: v.string(),
        specialty: v.array(v.string()),
        hourlyRate: v.optional(v.number()),
        rating: v.optional(v.number()),
        isPreferred: v.boolean(),
      })
    ),
  },
  handler: async (ctx, args) => {
    const userId = await resolveUserId(ctx, {
      userId: args.userId as any,
      ownerEmail: args.ownerEmail,
    });
    return await insertContractors(ctx, userId as any, args.contractors);
  },
});

/**
 * Seed default contractor list for a user
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
    return await insertContractors(ctx, userId as any, DEFAULT_CONTRACTORS);
  },
});

/**
 * Replace all contractors for a user with the default list
 */
export const replaceDefault = mutation({
  args: {
    userId: v.optional(v.id("users")),
    ownerEmail: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const userId = await resolveUserId(ctx, {
      userId: args.userId as any,
      ownerEmail: args.ownerEmail,
    });

    const existing = await ctx.db
      .query("contractors")
      .withIndex("by_user", (q) => q.eq("userId", userId as any))
      .collect();

    for (const contractor of existing) {
      await ctx.db.delete(contractor._id);
    }

    return await insertContractors(ctx, userId as any, DEFAULT_CONTRACTORS);
  },
});

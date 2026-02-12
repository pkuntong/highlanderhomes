/* eslint-disable */
/**
 * Generated `api` utility.
 *
 * THIS CODE IS AUTOMATICALLY GENERATED.
 *
 * To regenerate, run `npx convex dev`.
 * @module
 */

import type * as auth from "../auth.js";
import type * as authInternal from "../authInternal.js";
import type * as contractors from "../contractors.js";
import type * as expenses from "../expenses.js";
import type * as feedEvents from "../feedEvents.js";
import type * as insurancePolicies from "../insurancePolicies.js";
import type * as limits from "../limits.js";
import type * as maintenanceRequests from "../maintenanceRequests.js";
import type * as marketTrends from "../marketTrends.js";
import type * as migrations from "../migrations.js";
import type * as properties from "../properties.js";
import type * as rentPayments from "../rentPayments.js";
import type * as rentalLicenses from "../rentalLicenses.js";
import type * as screenshots from "../screenshots.js";
import type * as tenants from "../tenants.js";
import type * as users from "../users.js";

import type {
  ApiFromModules,
  FilterApi,
  FunctionReference,
} from "convex/server";

declare const fullApi: ApiFromModules<{
  auth: typeof auth;
  authInternal: typeof authInternal;
  contractors: typeof contractors;
  expenses: typeof expenses;
  feedEvents: typeof feedEvents;
  insurancePolicies: typeof insurancePolicies;
  limits: typeof limits;
  maintenanceRequests: typeof maintenanceRequests;
  marketTrends: typeof marketTrends;
  migrations: typeof migrations;
  properties: typeof properties;
  rentPayments: typeof rentPayments;
  rentalLicenses: typeof rentalLicenses;
  screenshots: typeof screenshots;
  tenants: typeof tenants;
  users: typeof users;
}>;

/**
 * A utility for referencing Convex functions in your app's public API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = api.myModule.myFunction;
 * ```
 */
export declare const api: FilterApi<
  typeof fullApi,
  FunctionReference<any, "public">
>;

/**
 * A utility for referencing Convex functions in your app's internal API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = internal.myModule.myFunction;
 * ```
 */
export declare const internal: FilterApi<
  typeof fullApi,
  FunctionReference<any, "internal">
>;

export declare const components: {};

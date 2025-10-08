/**
 * Stripe Service
 * Handles subscription billing and payment processing
 * Documentation: https://stripe.com/docs
 *
 * NOTE: This is frontend code only. For production, you need a backend to:
 * 1. Create checkout sessions
 * 2. Create customer portal sessions
 * 3. Handle webhooks
 * 4. Verify payments securely
 */

import { loadStripe } from '@stripe/stripe-js';

const STRIPE_PUBLISHABLE_KEY = import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY;

// Initialize Stripe
let stripePromise;
export const getStripe = () => {
  if (!stripePromise) {
    stripePromise = loadStripe(STRIPE_PUBLISHABLE_KEY);
  }
  return stripePromise;
};

/**
 * Pricing tiers for the application
 */
export const PRICING_TIERS = {
  FREE: {
    id: 'free',
    name: 'Free',
    price: 0,
    interval: 'month',
    features: [
      'Up to 5 properties',
      'Basic tenant management',
      'Document storage (1MB limit)',
      'Mobile app access',
    ],
    limits: {
      properties: 5,
      documents: 50,
      maintenanceRequests: 10,
    },
  },
  PRO: {
    id: 'pro',
    name: 'Pro',
    price: 29,
    interval: 'month',
    priceId: 'price_XXXXX', // Replace with actual Stripe Price ID
    features: [
      'Up to 50 properties',
      'Advanced analytics',
      'RentCast market data',
      'Bulk operations',
      'Priority support',
      'Unlimited documents',
    ],
    limits: {
      properties: 50,
      documents: Infinity,
      maintenanceRequests: Infinity,
    },
  },
  ENTERPRISE: {
    id: 'enterprise',
    name: 'Enterprise',
    price: 99,
    interval: 'month',
    priceId: 'price_YYYYY', // Replace with actual Stripe Price ID
    features: [
      'Unlimited properties',
      'Plaid payment processing',
      'Custom integrations',
      'Dedicated support',
      'White-label option',
      'Multi-user accounts',
    ],
    limits: {
      properties: Infinity,
      documents: Infinity,
      maintenanceRequests: Infinity,
    },
  },
};

/**
 * Check if user has access to a feature based on their subscription tier
 * @param {string} tier - User's subscription tier (free, pro, enterprise)
 * @param {string} feature - Feature to check (e.g., 'properties', 'documents')
 * @param {number} currentCount - Current count of the feature
 */
export function hasFeatureAccess(tier, feature, currentCount = 0) {
  const tierConfig = PRICING_TIERS[tier.toUpperCase()] || PRICING_TIERS.FREE;
  const limit = tierConfig.limits[feature];

  if (limit === Infinity) return true;
  return currentCount < limit;
}

/**
 * Get feature limit for a user's tier
 * @param {string} tier - User's subscription tier
 * @param {string} feature - Feature name
 */
export function getFeatureLimit(tier, feature) {
  const tierConfig = PRICING_TIERS[tier.toUpperCase()] || PRICING_TIERS.FREE;
  return tierConfig.limits[feature];
}

/**
 * Redirect to Stripe Checkout for subscription
 *
 * @param {string} priceId - Stripe Price ID
 * @param {string} userEmail - User's email
 * @param {string} userId - User's ID (for metadata)
 */
export async function redirectToCheckout(priceId, userEmail, userId) {
  try {
    const stripe = await getStripe();

    // Call Cloud Function to create checkout session
    const functionUrl = import.meta.env.VITE_FIREBASE_FUNCTIONS_URL ||
      'https://us-central1-highlanderhomes-4b1f3.cloudfunctions.net';

    const response = await fetch(`${functionUrl}/createCheckoutSession`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ priceId, userEmail, userId }),
    });

    if (!response.ok) {
      throw new Error('Failed to create checkout session');
    }

    const { sessionId } = await response.json();

    // Redirect to Stripe Checkout
    const { error } = await stripe.redirectToCheckout({ sessionId });

    if (error) {
      console.error('Stripe checkout error:', error);
      throw error;
    }
  } catch (error) {
    console.error('Error redirecting to checkout:', error);
    throw error;
  }
}

/**
 * Create Stripe Customer Portal session
 *
 * @param {string} customerId - Stripe Customer ID
 */
export async function openCustomerPortal(customerId) {
  try {
    const functionUrl = import.meta.env.VITE_FIREBASE_FUNCTIONS_URL ||
      'https://us-central1-highlanderhomes-4b1f3.cloudfunctions.net';

    const response = await fetch(`${functionUrl}/createPortalSession`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ customerId }),
    });

    if (!response.ok) {
      throw new Error('Failed to create portal session');
    }

    const { url } = await response.json();
    window.location.href = url;
  } catch (error) {
    console.error('Error opening customer portal:', error);
    throw error;
  }
}

/**
 * Format currency for display
 * @param {number} amount - Amount in dollars
 * @param {string} currency - Currency code (default: USD)
 */
export function formatCurrency(amount, currency = 'USD') {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
  }).format(amount);
}

/**
 * Calculate proration for mid-cycle upgrades
 * @param {number} oldPrice - Current plan price
 * @param {number} newPrice - New plan price
 * @param {number} daysRemaining - Days remaining in billing cycle
 * @param {number} totalDays - Total days in billing cycle (default: 30)
 */
export function calculateProration(oldPrice, newPrice, daysRemaining, totalDays = 30) {
  const unusedAmount = (oldPrice * daysRemaining) / totalDays;
  const newAmount = (newPrice * daysRemaining) / totalDays;
  const proratedCharge = newAmount - unusedAmount;

  return {
    unusedCredit: unusedAmount,
    proratedCharge: Math.max(0, proratedCharge),
    totalDue: Math.max(0, proratedCharge),
  };
}

export default {
  getStripe,
  PRICING_TIERS,
  hasFeatureAccess,
  getFeatureLimit,
  redirectToCheckout,
  openCustomerPortal,
  formatCurrency,
  calculateProration,
};

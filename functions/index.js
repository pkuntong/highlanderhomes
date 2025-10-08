/**
 * Firebase Cloud Functions for HighlanderHomes
 *
 * These functions provide secure backend endpoints for:
 * - Stripe subscription management
 * - Plaid bank account connections
 * - Payment processing
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);
const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');
const cors = require('cors')({ origin: true });

admin.initializeApp();

// ============================================================================
// STRIPE FUNCTIONS
// ============================================================================

/**
 * Create Stripe Checkout Session
 * Endpoint: /createCheckoutSession
 * Method: POST
 * Body: { priceId, userEmail, userId }
 */
exports.createCheckoutSession = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    try {
      const { priceId, userEmail, userId } = req.body;

      if (!priceId || !userEmail || !userId) {
        return res.status(400).json({ error: 'Missing required parameters' });
      }

      // Create or retrieve Stripe customer
      let customer;
      const existingCustomers = await stripe.customers.list({
        email: userEmail,
        limit: 1,
      });

      if (existingCustomers.data.length > 0) {
        customer = existingCustomers.data[0];
      } else {
        customer = await stripe.customers.create({
          email: userEmail,
          metadata: {
            firebaseUID: userId,
          },
        });
      }

      // Create checkout session
      const session = await stripe.checkout.sessions.create({
        customer: customer.id,
        payment_method_types: ['card'],
        line_items: [
          {
            price: priceId,
            quantity: 1,
          },
        ],
        mode: 'subscription',
        success_url: `${req.headers.origin}/dashboard?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${req.headers.origin}/pricing`,
        metadata: {
          firebaseUID: userId,
        },
      });

      res.json({ sessionId: session.id });
    } catch (error) {
      console.error('Error creating checkout session:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Create Stripe Customer Portal Session
 * Endpoint: /createPortalSession
 * Method: POST
 * Body: { customerId }
 */
exports.createPortalSession = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    try {
      const { customerId } = req.body;

      if (!customerId) {
        return res.status(400).json({ error: 'Missing customerId' });
      }

      const session = await stripe.billingPortal.sessions.create({
        customer: customerId,
        return_url: `${req.headers.origin}/dashboard`,
      });

      res.json({ url: session.url });
    } catch (error) {
      console.error('Error creating portal session:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Stripe Webhook Handler
 * Endpoint: /stripeWebhook
 * Handles subscription events from Stripe
 */
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  switch (event.type) {
    case 'checkout.session.completed':
      const session = event.data.object;
      await handleCheckoutComplete(session);
      break;

    case 'customer.subscription.updated':
    case 'customer.subscription.deleted':
      const subscription = event.data.object;
      await handleSubscriptionChange(subscription);
      break;

    case 'invoice.payment_succeeded':
      const invoice = event.data.object;
      await handlePaymentSuccess(invoice);
      break;

    case 'invoice.payment_failed':
      const failedInvoice = event.data.object;
      await handlePaymentFailure(failedInvoice);
      break;

    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  res.json({ received: true });
});

async function handleCheckoutComplete(session) {
  const firebaseUID = session.metadata.firebaseUID;
  const customerId = session.customer;
  const subscriptionId = session.subscription;

  // Update user document in Firestore
  await admin.firestore().collection('users').doc(firebaseUID).set({
    stripeCustomerId: customerId,
    stripeSubscriptionId: subscriptionId,
    subscriptionStatus: 'active',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function handleSubscriptionChange(subscription) {
  const customerId = subscription.customer;

  // Find user by customer ID
  const usersRef = admin.firestore().collection('users');
  const snapshot = await usersRef.where('stripeCustomerId', '==', customerId).limit(1).get();

  if (!snapshot.empty) {
    const userDoc = snapshot.docs[0];
    await userDoc.ref.update({
      subscriptionStatus: subscription.status,
      currentPlan: subscription.items.data[0].price.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handlePaymentSuccess(invoice) {
  // Log successful payment
  console.log('Payment succeeded:', invoice.id);
}

async function handlePaymentFailure(invoice) {
  // Notify user of payment failure
  console.error('Payment failed:', invoice.id);
}

// ============================================================================
// PLAID FUNCTIONS
// ============================================================================

// Initialize Plaid client
const plaidClient = new PlaidApi(
  new Configuration({
    basePath: PlaidEnvironments[functions.config().plaid.env],
    baseOptions: {
      headers: {
        'PLAID-CLIENT-ID': functions.config().plaid.client_id,
        'PLAID-SECRET': functions.config().plaid.secret,
      },
    },
  })
);

/**
 * Create Plaid Link Token
 * Endpoint: /createLinkToken
 * Method: POST
 * Body: { userId }
 */
exports.createLinkToken = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    try {
      const { userId } = req.body;

      if (!userId) {
        return res.status(400).json({ error: 'Missing userId' });
      }

      const response = await plaidClient.linkTokenCreate({
        user: {
          client_user_id: userId,
        },
        client_name: 'HighlanderHomes',
        products: ['auth', 'transactions'],
        country_codes: ['US'],
        language: 'en',
      });

      res.json({ link_token: response.data.link_token });
    } catch (error) {
      console.error('Error creating link token:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Exchange Plaid Public Token
 * Endpoint: /exchangePublicToken
 * Method: POST
 * Body: { publicToken, userId }
 */
exports.exchangePublicToken = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    try {
      const { publicToken, userId } = req.body;

      if (!publicToken || !userId) {
        return res.status(400).json({ error: 'Missing required parameters' });
      }

      // Exchange public token for access token
      const response = await plaidClient.itemPublicTokenExchange({
        public_token: publicToken,
      });

      const accessToken = response.data.access_token;
      const itemId = response.data.item_id;

      // Store access token securely in Firestore
      await admin.firestore().collection('plaidTokens').doc(userId).set({
        accessToken: accessToken,
        itemId: itemId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      res.json({
        success: true,
        itemId: itemId,
      });
    } catch (error) {
      console.error('Error exchanging public token:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Get Bank Accounts
 * Endpoint: /getBankAccounts
 * Method: POST
 * Body: { userId }
 */
exports.getBankAccounts = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    try {
      const { userId } = req.body;

      if (!userId) {
        return res.status(400).json({ error: 'Missing userId' });
      }

      // Get access token from Firestore
      const tokenDoc = await admin.firestore().collection('plaidTokens').doc(userId).get();

      if (!tokenDoc.exists) {
        return res.status(404).json({ error: 'No bank connection found' });
      }

      const { accessToken } = tokenDoc.data();

      // Get accounts from Plaid
      const response = await plaidClient.accountsGet({
        access_token: accessToken,
      });

      res.json({ accounts: response.data.accounts });
    } catch (error) {
      console.error('Error getting bank accounts:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

/**
 * Initiate ACH Payment
 * Endpoint: /initiatePayment
 * Method: POST
 * Body: { userId, accountId, amount, description }
 */
exports.initiatePayment = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    try {
      const { userId, accountId, amount, description } = req.body;

      if (!userId || !accountId || !amount) {
        return res.status(400).json({ error: 'Missing required parameters' });
      }

      // Get access token
      const tokenDoc = await admin.firestore().collection('plaidTokens').doc(userId).get();

      if (!tokenDoc.exists) {
        return res.status(404).json({ error: 'No bank connection found' });
      }

      const { accessToken } = tokenDoc.data();

      // Create payment record in Firestore
      const paymentRef = await admin.firestore().collection('payments').add({
        userId,
        accountId,
        amount,
        description,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Note: Actual ACH payment initiation would go here
      // This requires Plaid's Payment Initiation product
      // For now, we'll just create the record

      res.json({
        success: true,
        paymentId: paymentRef.id,
        status: 'pending',
        estimatedCompletion: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000), // 4 days
      });
    } catch (error) {
      console.error('Error initiating payment:', error);
      res.status(500).json({ error: error.message });
    }
  });
});

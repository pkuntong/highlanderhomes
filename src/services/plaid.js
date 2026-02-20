/**
 * Plaid Service
 * Handles bank account connections and ACH payments
 * Documentation: https://plaid.com/docs/
 *
 * NOTE: This is frontend code only. For production, you MUST have a backend to:
 * 1. Exchange public tokens for access tokens
 * 2. Make Plaid API calls securely
 * 3. Process ACH payments
 * 4. Store access tokens securely
 * 5. Handle webhooks
 */

const PLAID_CLIENT_ID = import.meta.env.VITE_PLAID_CLIENT_ID;
const PLAID_ENV = import.meta.env.VITE_PLAID_ENV || 'sandbox';

/**
 * Plaid Link configuration
 * Used to initialize the Plaid Link component
 */
export const PLAID_CONFIG = {
  clientName: 'HighlanderHomes',
  env: PLAID_ENV,
  product: ['auth', 'transactions'], // auth for ACH, transactions for payment history
  countryCodes: ['US'],
  language: 'en',
};

/**
 * Create a Link Token (requires backend)
 * Link tokens are required to initialize Plaid Link
 *
 * @param {string} userId - User's ID
 * @returns {Promise<string>} Link token
 */
export async function createLinkToken(userId) {
  try {
    // In production, call your backend to create a link token
    // const response = await fetch('/api/plaid/create-link-token', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({ userId }),
    // });
    // const { link_token } = await response.json();
    // return link_token;

    console.warn('Backend endpoint needed to create Plaid Link Token');
    throw new Error('Plaid integration requires a backend endpoint. See docs/PLAID_SETUP.md');
  } catch (error) {
    console.error('Error creating link token:', error);
    throw error;
  }
}

/**
 * Exchange public token for access token (requires backend)
 * After user completes Plaid Link, exchange the public token
 *
 * @param {string} publicToken - Public token from Plaid Link
 * @param {string} userId - User's ID
 * @returns {Promise<Object>} Access token and item details
 */
export async function exchangePublicToken(publicToken, userId) {
  try {
    // In production, call your backend to exchange token
    // const response = await fetch('/api/plaid/exchange-token', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({ publicToken, userId }),
    // });
    // const data = await response.json();
    // return data;

    console.warn('Backend endpoint needed to exchange Plaid public token');
    throw new Error('Token exchange requires a backend endpoint. See docs/PLAID_SETUP.md');
  } catch (error) {
    console.error('Error exchanging public token:', error);
    throw error;
  }
}

/**
 * Get bank accounts for a connected item (requires backend)
 *
 * @param {string} accessToken - Plaid access token
 * @returns {Promise<Array>} List of bank accounts
 */
export async function getBankAccounts(accessToken) {
  try {
    // In production, call your backend
    // const response = await fetch('/api/plaid/accounts', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({ accessToken }),
    // });
    // const { accounts } = await response.json();
    // return accounts;

    console.warn('Backend endpoint needed to fetch bank accounts');
    throw new Error('Fetching accounts requires a backend endpoint');
  } catch (error) {
    console.error('Error fetching bank accounts:', error);
    throw error;
  }
}

/**
 * Initiate ACH payment (requires backend)
 *
 * @param {Object} params
 * @param {string} params.accessToken - Plaid access token
 * @param {string} params.accountId - Bank account ID
 * @param {number} params.amount - Payment amount in dollars
 * @param {string} params.description - Payment description
 * @returns {Promise<Object>} Payment details
 */
export async function initiateACHPayment({ accessToken, accountId, amount, description }) {
  try {
    // In production, call your backend to initiate ACH payment
    // const response = await fetch('/api/plaid/payment', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({ accessToken, accountId, amount, description }),
    // });
    // const payment = await response.json();
    // return payment;

    console.warn('Backend endpoint needed to initiate ACH payment');
    throw new Error('ACH payments require a backend endpoint. See docs/PLAID_SETUP.md');
  } catch (error) {
    console.error('Error initiating ACH payment:', error);
    throw error;
  }
}

/**
 * Get transaction history (requires backend)
 *
 * @param {string} accessToken - Plaid access token
 * @param {Date} startDate - Start date for transactions
 * @param {Date} endDate - End date for transactions
 * @returns {Promise<Array>} List of transactions
 */
export async function getTransactions(accessToken, startDate, endDate) {
  try {
    // In production, call your backend
    // const response = await fetch('/api/plaid/transactions', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({
    //     accessToken,
    //     startDate: startDate.toISOString().split('T')[0],
    //     endDate: endDate.toISOString().split('T')[0],
    //   }),
    // });
    // const { transactions } = await response.json();
    // return transactions;

    console.warn('Backend endpoint needed to fetch transactions');
    throw new Error('Fetching transactions requires a backend endpoint');
  } catch (error) {
    console.error('Error fetching transactions:', error);
    throw error;
  }
}

/**
 * Remove bank connection (requires backend)
 *
 * @param {string} accessToken - Plaid access token
 * @returns {Promise<boolean>} Success status
 */
export async function removeBankConnection(accessToken) {
  try {
    // In production, call your backend
    // const response = await fetch('/api/plaid/remove-item', {
    //   method: 'POST',
    //   headers: { 'Content-Type': 'application/json' },
    //   body: JSON.stringify({ accessToken }),
    // });
    // const { success } = await response.json();
    // return success;

    console.warn('Backend endpoint needed to remove bank connection');
    throw new Error('Removing connection requires a backend endpoint');
  } catch (error) {
    console.error('Error removing bank connection:', error);
    throw error;
  }
}

/**
 * Format account number for display (mask sensitive data)
 * @param {string} accountNumber - Full account number
 * @returns {string} Masked account number (e.g., "****1234")
 */
export function maskAccountNumber(accountNumber) {
  if (!accountNumber) return '';
  const lastFour = accountNumber.slice(-4);
  return `****${lastFour}`;
}

/**
 * Format bank account type
 * @param {string} type - Account type from Plaid
 * @returns {string} Formatted type
 */
export function formatAccountType(type) {
  const types = {
    depository: 'Checking/Savings',
    credit: 'Credit Card',
    loan: 'Loan',
    investment: 'Investment',
  };
  return types[type] || type;
}

/**
 * Plaid Link success handler
 * Call this when user successfully connects their bank
 *
 * @param {string} publicToken - Public token from Plaid Link
 * @param {Object} metadata - Metadata from Plaid Link
 * @param {string} userId - User's ID
 * @param {Function} onSuccess - Callback after successful connection
 */
export async function handlePlaidSuccess(publicToken, metadata, userId, onSuccess) {
  try {
    console.log('Plaid Link Success:', metadata);

    // Exchange token and store it in the backend.
    const result = await exchangePublicToken(publicToken, userId);

    if (onSuccess) {
      onSuccess(result);
    }

    return result;
  } catch (error) {
    console.error('Error handling Plaid success:', error);
    throw error;
  }
}

/**
 * Calculate ACH processing time
 * ACH payments typically take 3-5 business days
 *
 * @param {Date} initiationDate - Payment initiation date
 * @returns {Object} Estimated dates
 */
export function estimateACHProcessingTime(initiationDate = new Date()) {
  const addBusinessDays = (date, days) => {
    let currentDate = new Date(date);
    let addedDays = 0;

    while (addedDays < days) {
      currentDate.setDate(currentDate.getDate() + 1);
      const dayOfWeek = currentDate.getDay();
      // Skip weekends
      if (dayOfWeek !== 0 && dayOfWeek !== 6) {
        addedDays++;
      }
    }

    return currentDate;
  };

  return {
    earliest: addBusinessDays(initiationDate, 3),
    latest: addBusinessDays(initiationDate, 5),
    typical: addBusinessDays(initiationDate, 4),
  };
}

export default {
  PLAID_CONFIG,
  createLinkToken,
  exchangePublicToken,
  getBankAccounts,
  initiateACHPayment,
  getTransactions,
  removeBankConnection,
  maskAccountNumber,
  formatAccountType,
  handlePlaidSuccess,
  estimateACHProcessingTime,
};

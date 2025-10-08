/**
 * RentCast API Service
 * Provides methods for property valuation, rent estimates, and market data
 * Documentation: https://developers.rentcast.io
 */

const RENTCAST_BASE_URL = 'https://api.rentcast.io/v1';
const API_KEY = import.meta.env.VITE_RENTCAST_API_KEY;

/**
 * Make a request to the RentCast API
 * @param {string} endpoint - API endpoint path
 * @param {Object} params - Query parameters
 * @returns {Promise<Object>} API response data
 */
async function rentcastRequest(endpoint, params = {}) {
  if (!API_KEY) {
    throw new Error('RentCast API key is not configured. Please add VITE_RENTCAST_API_KEY to your .env file');
  }

  const queryString = new URLSearchParams(params).toString();
  const url = `${RENTCAST_BASE_URL}${endpoint}${queryString ? `?${queryString}` : ''}`;

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Api-Key': API_KEY,
      },
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `RentCast API error: ${response.status} ${response.statusText}`);
    }

    return await response.json();
  } catch (error) {
    console.error('RentCast API Error:', error);
    throw error;
  }
}

/**
 * Get long-term rent estimate for a property
 * @param {Object} params - Property parameters
 * @param {string} params.address - Full property address
 * @param {string} params.zipCode - Property zip code
 * @param {number} [params.bedrooms] - Number of bedrooms
 * @param {number} [params.bathrooms] - Number of bathrooms
 * @param {number} [params.squareFootage] - Property square footage
 * @param {string} [params.propertyType] - Property type (e.g., 'Single Family', 'Condo')
 * @returns {Promise<Object>} Rent estimate data with comparables
 */
export async function getRentEstimate(params) {
  const endpoint = '/avm/rent/long-term';
  return await rentcastRequest(endpoint, params);
}

/**
 * Get property value estimate (AVM)
 * @param {Object} params - Property parameters
 * @param {string} params.address - Full property address
 * @param {string} params.zipCode - Property zip code
 * @param {number} [params.bedrooms] - Number of bedrooms
 * @param {number} [params.bathrooms] - Number of bathrooms
 * @param {number} [params.squareFootage] - Property square footage
 * @param {string} [params.propertyType] - Property type
 * @returns {Promise<Object>} Value estimate data
 */
export async function getPropertyValue(params) {
  const endpoint = '/avm/value';
  return await rentcastRequest(endpoint, params);
}

/**
 * Get property records/data
 * @param {Object} params - Search parameters
 * @param {string} [params.address] - Property address
 * @param {string} [params.city] - City name
 * @param {string} [params.state] - State abbreviation
 * @param {string} [params.zipCode] - Zip code
 * @param {number} [params.radius] - Search radius in miles
 * @param {string} [params.propertyType] - Property type filter
 * @param {string} [params.bedrooms] - Bedroom range (e.g., '2:4')
 * @param {string} [params.bathrooms] - Bathroom range
 * @param {number} [params.limit] - Max results (default 25, max 500)
 * @returns {Promise<Object>} Property records data
 */
export async function getPropertyRecords(params) {
  const endpoint = '/properties';
  return await rentcastRequest(endpoint, params);
}

/**
 * Get market statistics for a zip code
 * @param {string} zipCode - Zip code to get market data for
 * @returns {Promise<Object>} Market statistics data
 */
export async function getMarketStatistics(zipCode) {
  const endpoint = '/markets';
  return await rentcastRequest(endpoint, { zipCode });
}

/**
 * Get rental listings for an area
 * @param {Object} params - Search parameters
 * @param {string} [params.city] - City name
 * @param {string} [params.state] - State abbreviation
 * @param {string} [params.zipCode] - Zip code
 * @param {number} [params.limit] - Max results
 * @returns {Promise<Object>} Rental listings data
 */
export async function getRentalListings(params) {
  const endpoint = '/listings/rental/long-term';
  return await rentcastRequest(endpoint, params);
}

/**
 * Get sale listings for an area
 * @param {Object} params - Search parameters
 * @param {string} [params.city] - City name
 * @param {string} [params.state] - State abbreviation
 * @param {string} [params.zipCode] - Zip code
 * @param {number} [params.limit] - Max results
 * @returns {Promise<Object>} Sale listings data
 */
export async function getSaleListings(params) {
  const endpoint = '/listings/sale';
  return await rentcastRequest(endpoint, params);
}

/**
 * Get comprehensive property analysis (combines multiple API calls)
 * @param {Object} property - Property object with address details
 * @returns {Promise<Object>} Combined analysis data
 */
export async function getPropertyAnalysis(property) {
  try {
    const params = {
      address: property.address,
      zipCode: property.zipcode || property.zipCode,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      squareFootage: property.squareFootage || property.footage,
      propertyType: property.type || 'Single Family',
    };

    // Fetch rent estimate and property value in parallel
    const [rentData, valueData] = await Promise.all([
      getRentEstimate(params).catch(err => ({ error: err.message })),
      getPropertyValue(params).catch(err => ({ error: err.message })),
    ]);

    return {
      rentEstimate: rentData,
      valueEstimate: valueData,
      fetchedAt: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Error fetching property analysis:', error);
    throw error;
  }
}

/**
 * Cache market data in Firestore for a property
 * @param {string} propertyId - Property ID
 * @param {Object} marketData - Market data to cache
 * @param {Object} db - Firestore database instance
 */
export async function cacheMarketData(propertyId, marketData, db) {
  try {
    const { setDoc, doc } = await import('firebase/firestore');
    await setDoc(doc(db, 'marketData', propertyId), {
      ...marketData,
      updatedAt: new Date().toISOString(),
    }, { merge: true });
  } catch (error) {
    console.error('Error caching market data:', error);
  }
}

/**
 * Get cached market data from Firestore
 * @param {string} propertyId - Property ID
 * @param {Object} db - Firestore database instance
 * @param {number} maxAgeHours - Maximum age of cached data in hours (default 24)
 * @returns {Promise<Object|null>} Cached market data or null if expired/not found
 */
export async function getCachedMarketData(propertyId, db, maxAgeHours = 24) {
  try {
    const { getDoc, doc } = await import('firebase/firestore');
    const docSnap = await getDoc(doc(db, 'marketData', propertyId));

    if (!docSnap.exists()) {
      return null;
    }

    const data = docSnap.data();
    const updatedAt = new Date(data.updatedAt);
    const hoursAgo = (Date.now() - updatedAt.getTime()) / (1000 * 60 * 60);

    // Return null if data is older than maxAgeHours
    if (hoursAgo > maxAgeHours) {
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error getting cached market data:', error);
    return null;
  }
}

export default {
  getRentEstimate,
  getPropertyValue,
  getPropertyRecords,
  getMarketStatistics,
  getRentalListings,
  getSaleListings,
  getPropertyAnalysis,
  cacheMarketData,
  getCachedMarketData,
};

# RentCast API Integration Documentation

## Overview

Highlander Homes now integrates with the RentCast API to provide real-time market intelligence, including:
- **Rent Estimates** - AI-powered rental price estimates based on property characteristics
- **Property Valuations** - Automated valuation models (AVM) for property values
- **Market Analysis** - Comparative market data and pricing recommendations
- **Comparable Properties** - Similar properties for benchmarking

## Getting Started

### 1. Get Your RentCast API Key

1. Visit [RentCast.io](https://www.rentcast.io) and create an account
2. Navigate to your API dashboard
3. Generate a new API key
4. Copy your API key

### 2. Configure Environment Variables

Add your RentCast API key to your `.env` file:

```env
VITE_RENTCAST_API_KEY=your-rentcast-api-key-here
```

**Important:** Never commit your `.env` file to version control. The API key should remain secret.

### 3. Pricing Tiers

RentCast offers several pricing plans:

- **Free Tier**: 50 API requests/month (ideal for testing)
- **Starter**: 500 requests/month
- **Professional**: 2,500 requests/month
- **Enterprise**: Custom volume pricing

[View current pricing](https://www.rentcast.io/pricing)

## Features Implemented

### 1. Market Analytics Dashboard Widget

**Location:** Dashboard sidebar (for first property)

**Features:**
- Real-time rent estimate with market comparison
- Property value estimate (AVM)
- Price range (low/high estimates)
- Underpriced/Overpriced indicators
- Number of comparable properties used
- Auto-refresh capability
- 24-hour caching to optimize API usage

**Usage:**
The widget automatically loads when you view the Dashboard. It shows market data for your first property and caches results for 24 hours.

### 2. Property Card Market Estimates

**Location:** Dashboard property cards

**Features:**
- Market rent estimate badge
- Percentage difference vs current rent
- Visual indicators (up/down arrows)
- Color-coded badges (green=underpriced, red=overpriced)

**Display Logic:**
- Only shows if difference is ≥5% from current rent
- Automatically pulls from cached data when available
- Updates when market data is refreshed

### 3. Property Details Dialog - Market Analysis Tab

**Location:** Properties page → View Details (eye icon) → Market Analysis tab

**Features:**
- Complete market intelligence for selected property
- Three tabs: Details, Financials, Market Analysis
- Full rent estimate breakdown
- Property value estimate
- Comparable properties count
- Manual refresh option
- Last updated timestamp

**How to Access:**
1. Go to Properties page
2. Hover over any property card
3. Click the eye icon (View Details)
4. Click "Market Analysis" tab

## API Service Module

### Location
`src/services/rentcast.js`

### Available Functions

#### `getRentEstimate(params)`
Get long-term rent estimate for a property.

```javascript
import { getRentEstimate } from '@/services/rentcast';

const estimate = await getRentEstimate({
  address: "123 Main St",
  zipCode: "12345",
  bedrooms: 3,
  bathrooms: 2,
  squareFootage: 1500,
  propertyType: "Single Family"
});
```

#### `getPropertyValue(params)`
Get property value estimate (AVM).

```javascript
import { getPropertyValue } from '@/services/rentcast';

const value = await getPropertyValue({
  address: "123 Main St",
  zipCode: "12345",
  bedrooms: 3,
  bathrooms: 2,
  squareFootage: 1500
});
```

#### `getPropertyAnalysis(property)`
Get comprehensive analysis (rent + value estimates in parallel).

```javascript
import { getPropertyAnalysis } from '@/services/rentcast';

const analysis = await getPropertyAnalysis({
  address: "123 Main St",
  zipcode: "12345",
  bedrooms: 3,
  bathrooms: 2,
  squareFootage: 1500
});

// Returns:
// {
//   rentEstimate: { ... },
//   valueEstimate: { ... },
//   fetchedAt: "2025-01-01T00:00:00.000Z"
// }
```

#### `getCachedMarketData(propertyId, db, maxAgeHours = 24)`
Retrieve cached market data from Firestore.

```javascript
import { getCachedMarketData } from '@/services/rentcast';
import { db } from '@/firebase';

const cached = await getCachedMarketData(propertyId, db, 24);
if (cached) {
  // Use cached data
} else {
  // Fetch fresh data
}
```

#### `cacheMarketData(propertyId, marketData, db)`
Save market data to Firestore cache.

```javascript
import { cacheMarketData } from '@/services/rentcast';
import { db } from '@/firebase';

await cacheMarketData(propertyId, analysisData, db);
```

## Data Caching Strategy

To optimize API usage and costs, the integration implements intelligent caching:

### Firestore Cache Collection
- **Collection:** `marketData`
- **Document ID:** Property ID
- **TTL:** 24 hours (configurable)

### Cache Flow
1. Check Firestore for existing market data
2. If found and <24 hours old, use cached data
3. If not found or expired, fetch from RentCast API
4. Save new data to Firestore
5. Return fresh data

### Benefits
- Reduces API calls by ~95% for frequently viewed properties
- Faster load times (Firestore < 100ms vs API ~1-2s)
- Lower costs (stay within free tier longer)
- Graceful handling of API rate limits

## Error Handling

The integration includes comprehensive error handling:

### API Key Missing
```
Error: RentCast API key is not configured
```
**Solution:** Add `VITE_RENTCAST_API_KEY` to your `.env` file

### API Rate Limit Exceeded
```
Error: RentCast API error: 429 Too Many Requests
```
**Solution:**
- Wait for rate limit reset
- Upgrade to higher pricing tier
- Rely on cached data

### Invalid Property Data
```
Error: RentCast API error: 400 Bad Request
```
**Solution:** Ensure property has valid address, zipcode, and basic details

### Network Issues
All network errors are caught and logged. The UI displays user-friendly error messages with retry options.

## Best Practices

### 1. Property Data Quality
Ensure properties have complete data for accurate estimates:
- ✅ Full street address
- ✅ Valid zip code
- ✅ Accurate bedroom/bathroom count
- ✅ Correct square footage
- ✅ Property type (Single Family, Condo, etc.)

### 2. API Usage Optimization
- Let the caching system work (don't force refresh unnecessarily)
- Batch property updates when possible
- Monitor your API usage in RentCast dashboard

### 3. Data Interpretation
- Rent estimates are AI predictions, not guarantees
- Use price ranges for decision making
- Consider local market conditions
- Compare with actual rental listings

## Firestore Database Structure

### marketData Collection
```javascript
{
  // Document ID: property.id
  rentEstimate: {
    rent: 2500,
    rentRangeLow: 2300,
    rentRangeHigh: 2700,
    comparables: [...]
  },
  valueEstimate: {
    price: 450000,
    priceRangeLow: 425000,
    priceRangeHigh: 475000
  },
  fetchedAt: "2025-01-01T00:00:00.000Z",
  updatedAt: "2025-01-01T00:00:00.000Z"
}
```

## Troubleshooting

### Market data not loading
1. Check browser console for errors
2. Verify API key in `.env` file
3. Ensure property has complete address data
4. Check RentCast API status page

### Stale data showing
1. Click refresh button in MarketAnalytics widget
2. Check cache expiration (24 hours default)
3. Clear Firestore cache if needed

### "Underpriced/Overpriced" not showing
- Requires minimum 5% difference between current and market rent
- Ensure property has `monthlyRent` value set
- Check that market estimate was successful

## Future Enhancements

Potential additions to the RentCast integration:

- [ ] Automated daily market data updates (Cloud Functions)
- [ ] Historical rent trend tracking
- [ ] Market alert notifications (price changes >10%)
- [ ] Bulk property analysis
- [ ] Market reports export (PDF/CSV)
- [ ] Neighborhood-level market statistics
- [ ] Seasonal pricing recommendations
- [ ] ROI calculations with market data

## API Reference

### RentCast API Endpoints Used

| Endpoint | Purpose | Rate Limit |
|----------|---------|------------|
| `/v1/avm/rent/long-term` | Get rent estimates | Included in plan |
| `/v1/avm/value` | Get property values | Included in plan |
| `/v1/properties` | Get property records | Included in plan |

### Response Examples

**Rent Estimate Response:**
```json
{
  "rent": 2500,
  "rentRangeLow": 2300,
  "rentRangeHigh": 2700,
  "correlation": 0.95,
  "comparables": [
    {
      "id": "...",
      "address": "456 Oak St",
      "rent": 2450,
      "bedrooms": 3,
      "bathrooms": 2,
      "squareFootage": 1480
    }
  ]
}
```

**Value Estimate Response:**
```json
{
  "price": 450000,
  "priceRangeLow": 425000,
  "priceRangeHigh": 475000,
  "correlation": 0.92
}
```

## Support

For RentCast API issues:
- Email: support@rentcast.io
- Documentation: https://developers.rentcast.io
- Live chat: Available on RentCast website

For Highlander Homes integration issues:
- Email: highlanderhomes22@gmail.com
- Phone: 240-449-4338

---

**Last Updated:** October 8, 2025
**Integration Version:** 1.0.0
**RentCast API Version:** v1

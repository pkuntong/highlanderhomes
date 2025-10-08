import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  TrendingUp,
  DollarSign,
  Home,
  RefreshCw,
  AlertCircle,
  CheckCircle,
} from "lucide-react";
import { getPropertyAnalysis, getCachedMarketData, cacheMarketData } from "@/services/rentcast";
import { db } from "@/firebase";

export default function MarketDataCard({ property }) {
  const [marketData, setMarketData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchMarketData = async (forceRefresh = false) => {
    setLoading(true);
    setError(null);

    try {
      // Try to get cached data first (unless forcing refresh)
      if (!forceRefresh) {
        const cached = await getCachedMarketData(property.id, db, 24);
        if (cached) {
          setMarketData(cached);
          setLoading(false);
          return;
        }
      }

      // Fetch fresh data from RentCast
      const data = await getPropertyAnalysis(property);

      // Cache the data
      await cacheMarketData(property.id, data, db);

      setMarketData(data);
    } catch (err) {
      console.error('Error fetching market data:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (value) => {
    if (!value) return 'N/A';
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 0,
    }).format(value);
  };

  const calculateROI = () => {
    if (!marketData?.rentEstimate?.rent || !marketData?.valueEstimate?.price) {
      return null;
    }

    const monthlyRent = marketData.rentEstimate.rent;
    const propertyValue = marketData.valueEstimate.price;
    const annualRent = monthlyRent * 12;
    const grossYield = (annualRent / propertyValue) * 100;

    return grossYield.toFixed(2);
  };

  if (!marketData && !loading && !error) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Market Data
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground mb-4">
            Get estimated property value and rent estimates powered by RentCast
          </p>
          <Button onClick={() => fetchMarketData()} size="sm">
            <RefreshCw className="h-4 w-4 mr-2" />
            Load Market Data
          </Button>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Market Data
          </CardTitle>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => fetchMarketData(true)}
            disabled={loading}
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {error && (
          <div className="flex items-center gap-2 text-sm text-red-600 bg-red-50 dark:bg-red-900/20 p-3 rounded">
            <AlertCircle className="h-4 w-4" />
            <span>{error}</span>
          </div>
        )}

        {loading && (
          <div className="flex items-center justify-center py-8">
            <RefreshCw className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        )}

        {marketData && !loading && (
          <>
            {/* Property Value Estimate */}
            {marketData.valueEstimate && !marketData.valueEstimate.error && (
              <div className="border-b pb-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <Home className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm font-medium">Property Value</span>
                  </div>
                  <Badge variant="secondary">
                    {marketData.valueEstimate.confidence}% confidence
                  </Badge>
                </div>
                <div className="text-2xl font-bold text-green-600 dark:text-green-400">
                  {formatCurrency(marketData.valueEstimate.price)}
                </div>
                <div className="flex gap-2 mt-2 text-xs text-muted-foreground">
                  <span>Low: {formatCurrency(marketData.valueEstimate.priceRangeLow)}</span>
                  <span>•</span>
                  <span>High: {formatCurrency(marketData.valueEstimate.priceRangeHigh)}</span>
                </div>
                {marketData.valueEstimate.pricePerSquareFoot && (
                  <div className="mt-2 text-sm text-muted-foreground">
                    ${marketData.valueEstimate.pricePerSquareFoot}/sq ft
                  </div>
                )}
              </div>
            )}

            {/* Rent Estimate */}
            {marketData.rentEstimate && !marketData.rentEstimate.error && (
              <div className="border-b pb-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <DollarSign className="h-4 w-4 text-muted-foreground" />
                    <span className="text-sm font-medium">Est. Monthly Rent</span>
                  </div>
                  <Badge variant="secondary">
                    {marketData.rentEstimate.confidence}% confidence
                  </Badge>
                </div>
                <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                  {formatCurrency(marketData.rentEstimate.rent)}
                  <span className="text-sm font-normal text-muted-foreground">/mo</span>
                </div>
                <div className="flex gap-2 mt-2 text-xs text-muted-foreground">
                  <span>Low: {formatCurrency(marketData.rentEstimate.rentRangeLow)}</span>
                  <span>•</span>
                  <span>High: {formatCurrency(marketData.rentEstimate.rentRangeHigh)}</span>
                </div>

                {/* Compare to actual rent if available */}
                {property.monthlyRent && (
                  <div className="mt-3 p-2 bg-blue-50 dark:bg-blue-900/20 rounded text-sm">
                    <div className="flex items-center justify-between">
                      <span>Your rent:</span>
                      <span className="font-medium">{formatCurrency(property.monthlyRent)}/mo</span>
                    </div>
                    {marketData.rentEstimate.rent > property.monthlyRent && (
                      <div className="flex items-center gap-1 text-green-600 dark:text-green-400 mt-1">
                        <TrendingUp className="h-3 w-3" />
                        <span className="text-xs">
                          Below market by {formatCurrency(marketData.rentEstimate.rent - property.monthlyRent)}
                        </span>
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}

            {/* ROI Calculation */}
            {calculateROI() && (
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  <span className="text-sm font-medium">Gross Rental Yield</span>
                </div>
                <div className="text-xl font-bold text-purple-600 dark:text-purple-400">
                  {calculateROI()}%
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  Annual rent / Property value
                </p>
              </div>
            )}

            {/* Last Updated */}
            <div className="pt-2 border-t text-xs text-muted-foreground">
              Last updated: {new Date(marketData.fetchedAt).toLocaleDateString()}
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}

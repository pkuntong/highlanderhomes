import { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { TrendingUp, TrendingDown, DollarSign, RefreshCw, AlertCircle } from 'lucide-react';
import { getPropertyAnalysis, getCachedMarketData, cacheMarketData } from '@/services/rentcast';
import { db } from '@/firebase';

const MarketAnalytics = ({ property }) => {
  const [marketData, setMarketData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [lastUpdated, setLastUpdated] = useState(null);

  useEffect(() => {
    loadMarketData();
  }, [property?.id]);

  const loadMarketData = async (forceRefresh = false) => {
    if (!property) return;

    setLoading(true);
    setError(null);

    try {
      // Try to get cached data first (unless forcing refresh)
      if (!forceRefresh) {
        const cached = await getCachedMarketData(property.id, db, 24);
        if (cached) {
          setMarketData(cached);
          setLastUpdated(new Date(cached.updatedAt));
          setLoading(false);
          return;
        }
      }

      // Fetch fresh data from RentCast
      const analysis = await getPropertyAnalysis(property);

      // Cache the data
      await cacheMarketData(property.id, analysis, db);

      setMarketData(analysis);
      setLastUpdated(new Date());
    } catch (err) {
      console.error('Error loading market data:', err);
      setError(err.message || 'Failed to load market data');
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = () => {
    loadMarketData(true);
  };

  if (!property) {
    return null;
  }

  if (loading && !marketData) {
    return (
      <Card className="glass">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Market Intelligence
          </CardTitle>
          <CardDescription>Loading market data...</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Skeleton className="h-20 w-full" />
          <Skeleton className="h-20 w-full" />
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card className="glass border-destructive/50">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-destructive">
            <AlertCircle className="h-5 w-5" />
            Market Data Error
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground mb-4">{error}</p>
          <Button onClick={handleRefresh} variant="outline" size="sm">
            <RefreshCw className="h-4 w-4 mr-2" />
            Try Again
          </Button>
        </CardContent>
      </Card>
    );
  }

  if (!marketData) {
    return (
      <Card className="glass">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5" />
            Market Intelligence
          </CardTitle>
          <CardDescription>Get AI-powered market insights</CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={handleRefresh} className="w-full">
            <RefreshCw className="h-4 w-4 mr-2" />
            Load Market Data
          </Button>
        </CardContent>
      </Card>
    );
  }

  const rentEstimate = marketData.rentEstimate;
  const valueEstimate = marketData.valueEstimate;
  const currentRent = property.monthlyRent || 0;
  const estimatedRent = rentEstimate?.rent || rentEstimate?.price || 0;
  const estimatedValue = valueEstimate?.price || 0;

  // Calculate rent difference
  const rentDiff = estimatedRent - currentRent;
  const rentDiffPercent = currentRent > 0 ? ((rentDiff / currentRent) * 100).toFixed(1) : 0;
  const isUnderpriced = rentDiff > 0;
  const isOverpriced = rentDiff < 0;

  return (
    <Card className="glass">
      <CardHeader>
        <div className="flex items-start justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5" />
              Market Intelligence
            </CardTitle>
            <CardDescription className="mt-1">
              AI-powered property analysis
            </CardDescription>
          </div>
          <Button
            onClick={handleRefresh}
            variant="ghost"
            size="sm"
            disabled={loading}
            className="h-8 w-8 p-0"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Rent Estimate */}
        {rentEstimate && !rentEstimate.error && (
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium text-muted-foreground">Market Rent Estimate</span>
              <Badge variant={isUnderpriced ? 'default' : isOverpriced ? 'destructive' : 'secondary'}>
                {isUnderpriced ? 'Underpriced' : isOverpriced ? 'Overpriced' : 'Fair'}
              </Badge>
            </div>
            <div className="flex items-baseline gap-3">
              <span className="text-3xl font-bold text-gradient">
                ${estimatedRent.toLocaleString()}
              </span>
              <span className="text-sm text-muted-foreground">/month</span>
            </div>
            {currentRent > 0 && (
              <div className="flex items-center gap-2 text-sm">
                <span className="text-muted-foreground">vs Current:</span>
                <span className="font-medium">${currentRent.toLocaleString()}</span>
                <div className={`flex items-center gap-1 ${isUnderpriced ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'}`}>
                  {isUnderpriced ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
                  <span className="font-medium">
                    {Math.abs(rentDiffPercent)}%
                  </span>
                </div>
              </div>
            )}
            {rentEstimate.rentRangeLow && rentEstimate.rentRangeHigh && (
              <div className="text-xs text-muted-foreground">
                Range: ${rentEstimate.rentRangeLow.toLocaleString()} - ${rentEstimate.rentRangeHigh.toLocaleString()}
              </div>
            )}
          </div>
        )}

        {/* Property Value Estimate */}
        {valueEstimate && !valueEstimate.error && estimatedValue > 0 && (
          <div className="space-y-3 pt-4 border-t border-border/50">
            <span className="text-sm font-medium text-muted-foreground">Estimated Property Value</span>
            <div className="flex items-baseline gap-3">
              <DollarSign className="h-5 w-5 text-muted-foreground" />
              <span className="text-2xl font-bold">
                ${estimatedValue.toLocaleString()}
              </span>
            </div>
            {valueEstimate.priceRangeLow && valueEstimate.priceRangeHigh && (
              <div className="text-xs text-muted-foreground">
                Range: ${valueEstimate.priceRangeLow.toLocaleString()} - ${valueEstimate.priceRangeHigh.toLocaleString()}
              </div>
            )}
          </div>
        )}

        {/* Last Updated */}
        {lastUpdated && (
          <div className="pt-4 border-t border-border/50">
            <p className="text-xs text-muted-foreground">
              Last updated: {lastUpdated.toLocaleString()}
            </p>
          </div>
        )}

        {/* Comparables Count */}
        {rentEstimate?.comparables?.length > 0 && (
          <div className="text-xs text-muted-foreground">
            Based on {rentEstimate.comparables.length} comparable properties
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default MarketAnalytics;

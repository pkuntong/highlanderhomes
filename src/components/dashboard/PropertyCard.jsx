import { InteractiveCard, CardContent, CardFooter } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { MapPin, Bed, Bath, Square, DollarSign, TrendingUp, TrendingDown } from "lucide-react";
import { useState, useEffect } from "react";
import { getCachedMarketData } from "@/services/rentcast";
import { db } from "@/firebase";

const PropertyCard = ({ property }) => {
  const [isHovered, setIsHovered] = useState(false);
  const [marketEstimate, setMarketEstimate] = useState(null);

  useEffect(() => {
    const loadMarketEstimate = async () => {
      if (!property?.id) return;
      const cached = await getCachedMarketData(property.id, db, 24);
      if (cached?.rentEstimate) {
        setMarketEstimate(cached.rentEstimate);
      }
    };
    loadMarketEstimate();
  }, [property?.id]);

  const getStatusColor = (status) => {
    switch (status) {
      case "occupied":
        return "bg-accent-emerald/20 text-accent-emerald border-accent-emerald/30";
      case "vacant":
        return "bg-accent-gold/20 text-accent-gold border-accent-gold/30";
      case "maintenance":
        return "bg-destructive/20 text-destructive border-destructive/30";
      default:
        return "bg-muted text-foreground-muted border-border";
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case "occupied":
        return "🏡";
      case "vacant":
        return "🔑";
      case "maintenance":
        return "🔧";
      default:
        return "🏠";
    }
  };

  return (
    <InteractiveCard 
      className="group overflow-hidden"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {/* Property Image */}
      <div className="relative h-48 bg-gradient-to-br from-muted to-muted-foreground/10 overflow-hidden">
        {property.imageBase64 || property.imageUrl ? (
          <img 
            src={property.imageBase64 || property.imageUrl} 
            alt={property.address || "Property image"} 
            className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
          />
        ) : (
          <div className="h-full w-full flex items-center justify-center text-6xl text-foreground-muted">
            🏠
          </div>
        )}
        
        {/* Status Badge */}
        <div className="absolute top-4 right-4">
          <Badge className={`${getStatusColor(property.status)} border backdrop-blur-sm font-medium`}>
            <span className="mr-1">{getStatusIcon(property.status)}</span>
            {property.status ? property.status.charAt(0).toUpperCase() + property.status.slice(1) : "Unknown"}
          </Badge>
        </div>

        {/* Gradient Overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/20 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
      </div>

      <CardContent className="p-6 space-y-4">
        {/* Property Address */}
        <div className="space-y-2">
          <h3 className="text-xl font-bold text-premium line-clamp-1">
            {property.address || "Unknown Address"}
          </h3>
          <div className="flex items-center text-foreground-muted">
            <MapPin size={14} className="mr-1.5" />
            <p className="text-sm">
              {[property.city, property.state, property.zipCode].filter(Boolean).join(", ") || "Location not specified"}
            </p>
          </div>
        </div>

        {/* Property Details */}
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div className="flex items-center space-x-2">
            <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-primary-50">
              <Bed size={16} className="text-primary" />
            </div>
            <div>
              <p className="font-semibold text-premium">{property.bedrooms ?? 0}</p>
              <p className="text-xs text-foreground-muted">Bedrooms</p>
            </div>
          </div>
          
          <div className="flex items-center space-x-2">
            <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-accent-emerald/10">
              <Bath size={16} className="text-accent-emerald" />
            </div>
            <div>
              <p className="font-semibold text-premium">{(property.fullBathrooms ?? 0) + (property.halfBathrooms ?? 0)}</p>
              <p className="text-xs text-foreground-muted">Bathrooms</p>
            </div>
          </div>
          
          <div className="flex items-center space-x-2 col-span-2">
            <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-accent-gold/10">
              <Square size={16} className="text-accent-gold" />
            </div>
            <div>
              <p className="font-semibold text-premium">
                {typeof property.squareFootage === 'number' ? property.squareFootage.toLocaleString() : 'N/A'}
              </p>
              <p className="text-xs text-foreground-muted">Square Feet</p>
            </div>
          </div>
        </div>
      </CardContent>

      {/* Premium Footer */}
      <CardFooter className="border-t border-border-subtle bg-gradient-to-r from-background-elevated to-background p-6">
        <div className="w-full space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <div className="flex items-center justify-center w-10 h-10 rounded-xl bg-gradient-to-br from-primary to-primary-600">
                <DollarSign size={18} className="text-primary-foreground" />
              </div>
              <div>
                <p className="text-2xl font-bold text-premium">
                  ${typeof property.monthlyRent === 'number' ? property.monthlyRent.toLocaleString() : 0}
                </p>
                <p className="text-xs text-foreground-muted">per month</p>
              </div>
            </div>

            <div className={`transition-all duration-300 ${isHovered ? 'opacity-100 translate-x-0' : 'opacity-0 translate-x-4'}`}>
              <div className="text-right">
                <p className="text-sm font-medium text-accent-emerald">
                  ${(typeof property.monthlyRent === 'number' ? property.monthlyRent * 12 : 0).toLocaleString()}
                </p>
                <p className="text-xs text-foreground-muted">annual</p>
              </div>
            </div>
          </div>

          {/* Market Estimate Badge */}
          {marketEstimate && marketEstimate.rent && (
            <div className="flex items-center justify-between pt-2 border-t border-border/50">
              <span className="text-xs text-muted-foreground">Market Estimate:</span>
              <div className="flex items-center gap-2">
                <span className="text-sm font-semibold">${marketEstimate.rent.toLocaleString()}/mo</span>
                {(() => {
                  const currentRent = property.monthlyRent || 0;
                  const estimatedRent = marketEstimate.rent;
                  const diff = estimatedRent - currentRent;
                  const diffPercent = currentRent > 0 ? ((diff / currentRent) * 100).toFixed(0) : 0;
                  const isUnderpriced = diff > 0;

                  if (Math.abs(diffPercent) < 5) return null;

                  return (
                    <Badge variant={isUnderpriced ? "default" : "destructive"} className="text-xs px-2 py-0.5">
                      {isUnderpriced ? <TrendingUp className="h-3 w-3 mr-1" /> : <TrendingDown className="h-3 w-3 mr-1" />}
                      {Math.abs(diffPercent)}%
                    </Badge>
                  );
                })()}
              </div>
            </div>
          )}
        </div>
      </CardFooter>
    </InteractiveCard>
  );
};

export default PropertyCard;

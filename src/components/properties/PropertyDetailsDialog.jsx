import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { MapPin, Bed, Bath, Square, DollarSign, Calendar, Home } from "lucide-react";
import MarketAnalytics from "@/components/dashboard/MarketAnalytics";
import MarketDataCard from "@/components/market/MarketDataCard";

const PropertyDetailsDialog = ({ property, open, onOpenChange }) => {
  if (!property) return null;

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

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl font-bold text-premium">
            {property.address}
          </DialogTitle>
          <div className="flex items-center gap-2 text-muted-foreground">
            <MapPin className="h-4 w-4" />
            <span>
              {[property.city, property.state, property.zipCode].filter(Boolean).join(", ")}
            </span>
            <Badge className={`ml-2 ${getStatusColor(property.status)}`}>
              {property.status}
            </Badge>
          </div>
        </DialogHeader>

        <Tabs defaultValue="details" className="mt-6">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="details">Details</TabsTrigger>
            <TabsTrigger value="financials">Financials</TabsTrigger>
            <TabsTrigger value="market">Market Analysis</TabsTrigger>
          </TabsList>

          {/* Details Tab */}
          <TabsContent value="details" className="space-y-6 mt-6">
            {/* Property Image */}
            {(property.imageBase64 || property.imageUrl) && (
              <div className="relative h-64 rounded-lg overflow-hidden bg-muted">
                <img
                  src={property.imageBase64 || property.imageUrl}
                  alt={property.address}
                  className="w-full h-full object-cover"
                />
              </div>
            )}

            {/* Property Specs */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="glass p-4 rounded-lg">
                <div className="flex items-center gap-2 text-muted-foreground mb-2">
                  <Bed className="h-4 w-4" />
                  <span className="text-sm">Bedrooms</span>
                </div>
                <p className="text-2xl font-bold text-premium">{property.bedrooms || 0}</p>
              </div>

              <div className="glass p-4 rounded-lg">
                <div className="flex items-center gap-2 text-muted-foreground mb-2">
                  <Bath className="h-4 w-4" />
                  <span className="text-sm">Bathrooms</span>
                </div>
                <p className="text-2xl font-bold text-premium">
                  {(property.fullBathrooms || 0) + (property.halfBathrooms || 0)}
                </p>
              </div>

              <div className="glass p-4 rounded-lg">
                <div className="flex items-center gap-2 text-muted-foreground mb-2">
                  <Square className="h-4 w-4" />
                  <span className="text-sm">Square Feet</span>
                </div>
                <p className="text-2xl font-bold text-premium">
                  {property.squareFootage?.toLocaleString() || 'N/A'}
                </p>
              </div>

              <div className="glass p-4 rounded-lg">
                <div className="flex items-center gap-2 text-muted-foreground mb-2">
                  <Calendar className="h-4 w-4" />
                  <span className="text-sm">Year Built</span>
                </div>
                <p className="text-2xl font-bold text-premium">{property.yearBuilt || 'N/A'}</p>
              </div>
            </div>

            {/* Description */}
            {property.description && (
              <div className="glass p-4 rounded-lg">
                <h3 className="font-semibold text-premium mb-2">Description</h3>
                <p className="text-muted-foreground">{property.description}</p>
              </div>
            )}

            {/* Lease Information */}
            <div className="glass p-4 rounded-lg">
              <h3 className="font-semibold text-premium mb-3">Lease Information</h3>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-muted-foreground">Lease Type:</span>
                  <p className="font-medium mt-1">{property.leaseType || 'Not specified'}</p>
                </div>
                <div>
                  <span className="text-muted-foreground">Payment Status:</span>
                  <p className="font-medium mt-1 capitalize">{property.paymentStatus || 'pending'}</p>
                </div>
              </div>
            </div>
          </TabsContent>

          {/* Financials Tab */}
          <TabsContent value="financials" className="space-y-6 mt-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Monthly Rent */}
              <div className="glass p-6 rounded-lg">
                <div className="flex items-center gap-2 text-muted-foreground mb-3">
                  <DollarSign className="h-5 w-5" />
                  <span className="text-sm font-medium">Monthly Rent</span>
                </div>
                <p className="text-4xl font-bold text-gradient">
                  ${property.monthlyRent?.toLocaleString() || 0}
                </p>
                <p className="text-sm text-muted-foreground mt-2">per month</p>
              </div>

              {/* Annual Revenue */}
              <div className="glass p-6 rounded-lg">
                <div className="flex items-center gap-2 text-muted-foreground mb-3">
                  <DollarSign className="h-5 w-5" />
                  <span className="text-sm font-medium">Annual Revenue</span>
                </div>
                <p className="text-4xl font-bold text-accent-emerald">
                  ${((property.monthlyRent || 0) * 12).toLocaleString()}
                </p>
                <p className="text-sm text-muted-foreground mt-2">per year</p>
              </div>
            </div>

            {/* Payment History Placeholder */}
            <div className="glass p-6 rounded-lg">
              <h3 className="font-semibold text-premium mb-3">Payment History</h3>
              <p className="text-sm text-muted-foreground">
                Payment history will be displayed here once integrated with payment tracking system.
              </p>
            </div>
          </TabsContent>

          {/* Market Analysis Tab */}
          <TabsContent value="market" className="mt-6 space-y-4">
            <MarketDataCard property={property} />
            <MarketAnalytics property={property} />
          </TabsContent>
        </Tabs>
      </DialogContent>
    </Dialog>
  );
};

export default PropertyDetailsDialog;

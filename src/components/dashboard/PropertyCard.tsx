import { Property } from "@/types";
import { Card, CardContent, CardFooter } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface PropertyCardProps {
  property: Property;
}

const PropertyCard = ({ property }: PropertyCardProps) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case "occupied":
        return "bg-green-100 text-green-800";
      case "vacant":
        return "bg-yellow-100 text-yellow-800";
      case "maintenance":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  return (
    <Card className="overflow-hidden">
      <div className="h-40 bg-gray-200">
        <img 
          src={property.imageBase64 || property.imageUrl} 
          alt={property.address} 
          className="h-full w-full object-cover"
        />
      </div>
      <CardContent className="pt-4">
        <div className="flex justify-between items-start mb-2">
          <h3 className="font-medium text-lg">{property.address}</h3>
          <Badge className={getStatusColor(property.status)}>
            {property.status.charAt(0).toUpperCase() + property.status.slice(1)}
          </Badge>
        </div>
        <p className="text-sm text-gray-600">
          {property.city}, {property.state} {property.zipCode}
        </p>
        <div className="mt-3 flex items-center justify-between text-sm">
          <div>
            <span className="font-medium">{property.bedrooms}</span> beds
          </div>
          <div>
            <span className="font-medium">{property.fullBathrooms}</span> full baths
          </div>
          <div>
            <span className="font-medium">{property.halfBathrooms}</span> half baths
          </div>
          <div>
            <span className="font-medium">{property.squareFootage?.toLocaleString?.() || ''}</span> sqft
          </div>
        </div>
      </CardContent>
      <CardFooter className="border-t border-gray-100 bg-gray-50 px-4 py-3">
        <p className="font-medium text-highlander-700">${property.monthlyRent.toLocaleString()}/month</p>
      </CardFooter>
    </Card>
  );
};

export default PropertyCard;


import { useState } from "react";
import PageLayout from "@/components/layout/PageLayout";
import PropertyCard from "@/components/dashboard/PropertyCard";
import { properties } from "@/data/mockData";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Building, Plus } from "lucide-react";

const Properties = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  const filteredProperties = properties.filter((property) => {
    // Filter by status
    if (statusFilter !== "all" && property.status !== statusFilter) {
      return false;
    }

    // Filter by search term
    const searchLower = searchTerm.toLowerCase();
    return (
      property.address.toLowerCase().includes(searchLower) ||
      property.city.toLowerCase().includes(searchLower) ||
      property.state.toLowerCase().includes(searchLower) ||
      property.zipCode.toLowerCase().includes(searchLower)
    );
  });

  return (
    <PageLayout title="Properties">
      <div className="mb-6 flex flex-col md:flex-row gap-4 md:justify-between md:items-center">
        <div className="flex flex-col md:flex-row gap-4 md:items-center">
          <div className="relative">
            <Input
              type="text"
              placeholder="Search properties..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full md:w-80"
            />
          </div>

          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-full md:w-40">
              <SelectValue placeholder="Filter by status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Properties</SelectItem>
              <SelectItem value="occupied">Occupied</SelectItem>
              <SelectItem value="vacant">Vacant</SelectItem>
              <SelectItem value="maintenance">Maintenance</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <Button className="md:self-end">
          <Plus className="mr-2 h-4 w-4" /> Add Property
        </Button>
      </div>

      {filteredProperties.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filteredProperties.map((property) => (
            <PropertyCard key={property.id} property={property} />
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center py-12 text-center">
          <div className="rounded-full bg-highlander-100 p-3 text-highlander-700 mb-4">
            <Building size={24} />
          </div>
          <h3 className="text-lg font-medium mb-1">No properties found</h3>
          <p className="text-gray-500 mb-4">
            {searchTerm
              ? "Try adjusting your search or filters"
              : "Add your first property to get started"}
          </p>
          <Button>
            <Plus className="mr-2 h-4 w-4" /> Add Property
          </Button>
        </div>
      )}
    </PageLayout>
  );
};

export default Properties;

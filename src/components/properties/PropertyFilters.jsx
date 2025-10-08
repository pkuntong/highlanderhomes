import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Search, X, Filter, SlidersHorizontal } from "lucide-react";
import { useState } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Slider } from "@/components/ui/slider";

export default function PropertyFilters({
  searchTerm,
  setSearchTerm,
  statusFilter,
  setStatusFilter,
  paymentFilter,
  setPaymentFilter,
  rentRange,
  setRentRange,
  cityFilter,
  setCityFilter,
  cities
}) {
  const [showAdvanced, setShowAdvanced] = useState(false);

  const handleClearFilters = () => {
    setSearchTerm("");
    setStatusFilter("all");
    setPaymentFilter("all");
    setRentRange([0, 10000]);
    setCityFilter("all");
  };

  const hasActiveFilters = searchTerm || statusFilter !== "all" || paymentFilter !== "all" || cityFilter !== "all" || rentRange[0] > 0 || rentRange[1] < 10000;

  return (
    <div className="space-y-4 mb-6">
      {/* Main Search Bar */}
      <div className="flex flex-col md:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <Input
            type="text"
            placeholder="Search by address, city, or zip code..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10 pr-10"
          />
          {searchTerm && (
            <button
              onClick={() => setSearchTerm("")}
              className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
            >
              <X className="h-4 w-4" />
            </button>
          )}
        </div>

        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-full md:w-40">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="occupied">Occupied</SelectItem>
            <SelectItem value="vacant">Vacant</SelectItem>
            <SelectItem value="maintenance">Maintenance</SelectItem>
          </SelectContent>
        </Select>

        <Select value={paymentFilter} onValueChange={setPaymentFilter}>
          <SelectTrigger className="w-full md:w-40">
            <SelectValue placeholder="Payment" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Payments</SelectItem>
            <SelectItem value="paid">Paid</SelectItem>
            <SelectItem value="pending">Pending</SelectItem>
            <SelectItem value="overdue">Overdue</SelectItem>
          </SelectContent>
        </Select>

        <Button
          variant="outline"
          onClick={() => setShowAdvanced(!showAdvanced)}
          className="w-full md:w-auto"
        >
          <SlidersHorizontal className="h-4 w-4 mr-2" />
          {showAdvanced ? "Hide" : "More"} Filters
        </Button>

        {hasActiveFilters && (
          <Button
            variant="ghost"
            onClick={handleClearFilters}
            className="w-full md:w-auto"
          >
            <X className="h-4 w-4 mr-2" />
            Clear All
          </Button>
        )}
      </div>

      {/* Advanced Filters */}
      {showAdvanced && (
        <Card>
          <CardContent className="pt-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* City Filter */}
              <div>
                <label className="block text-sm font-medium mb-2">City</label>
                <Select value={cityFilter} onValueChange={setCityFilter}>
                  <SelectTrigger>
                    <SelectValue placeholder="All Cities" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Cities</SelectItem>
                    {cities.map(city => (
                      <SelectItem key={city} value={city}>{city}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Rent Range Slider */}
              <div>
                <label className="block text-sm font-medium mb-2">
                  Monthly Rent Range: ${rentRange[0]} - ${rentRange[1]}
                </label>
                <Slider
                  min={0}
                  max={10000}
                  step={100}
                  value={rentRange}
                  onValueChange={setRentRange}
                  className="mt-2"
                />
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>$0</span>
                  <span>$10,000+</span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Active Filters Summary */}
      {hasActiveFilters && (
        <div className="flex flex-wrap gap-2 items-center text-sm">
          <span className="text-gray-600">Active filters:</span>
          {searchTerm && (
            <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-full">
              Search: "{searchTerm}"
            </span>
          )}
          {statusFilter !== "all" && (
            <span className="px-2 py-1 bg-green-100 text-green-800 rounded-full">
              Status: {statusFilter}
            </span>
          )}
          {paymentFilter !== "all" && (
            <span className="px-2 py-1 bg-purple-100 text-purple-800 rounded-full">
              Payment: {paymentFilter}
            </span>
          )}
          {cityFilter !== "all" && (
            <span className="px-2 py-1 bg-orange-100 text-orange-800 rounded-full">
              City: {cityFilter}
            </span>
          )}
          {(rentRange[0] > 0 || rentRange[1] < 10000) && (
            <span className="px-2 py-1 bg-pink-100 text-pink-800 rounded-full">
              Rent: ${rentRange[0]} - ${rentRange[1]}
            </span>
          )}
        </div>
      )}
    </div>
  );
}

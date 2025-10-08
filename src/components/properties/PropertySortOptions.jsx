import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ArrowUpDown } from "lucide-react";

export default function PropertySortOptions({ sortBy, setSortBy }) {
  return (
    <div className="flex items-center gap-2">
      <ArrowUpDown className="h-4 w-4 text-gray-500" />
      <span className="text-sm font-medium text-gray-700">Sort by:</span>
      <Select value={sortBy} onValueChange={setSortBy}>
        <SelectTrigger className="w-[180px]">
          <SelectValue placeholder="Sort by..." />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="address-asc">Address (A-Z)</SelectItem>
          <SelectItem value="address-desc">Address (Z-A)</SelectItem>
          <SelectItem value="rent-high">Rent (High to Low)</SelectItem>
          <SelectItem value="rent-low">Rent (Low to High)</SelectItem>
          <SelectItem value="status-occupied">Status: Occupied First</SelectItem>
          <SelectItem value="status-vacant">Status: Vacant First</SelectItem>
          <SelectItem value="city-asc">City (A-Z)</SelectItem>
          <SelectItem value="recent">Recently Added</SelectItem>
        </SelectContent>
      </Select>
    </div>
  );
}

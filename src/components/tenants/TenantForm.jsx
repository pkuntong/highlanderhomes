import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export default function TenantForm({
  form,
  onFormChange,
  onSubmit,
  onCancel,
  isEditing,
  properties = []
}) {
  const handleSelectChange = (value) => {
    // Convert "none" to empty string for no property assigned
    const propertyId = value === "none" ? "" : value;
    onFormChange({ target: { name: 'propertyId', value: propertyId } });
  };

  return (
    <form onSubmit={onSubmit} className="mb-6 p-6 border rounded-lg bg-white dark:bg-gray-800 shadow-sm">
      <h3 className="text-lg font-semibold mb-4">
        {isEditing ? "Edit Tenant" : "Add New Tenant"}
      </h3>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Name */}
        <div>
          <Label htmlFor="name">Full Name *</Label>
          <Input
            name="name"
            id="name"
            value={form.name}
            onChange={onFormChange}
            placeholder="John Doe"
            required
          />
        </div>

        {/* Email */}
        <div>
          <Label htmlFor="email">Email Address *</Label>
          <Input
            name="email"
            id="email"
            value={form.email}
            onChange={onFormChange}
            placeholder="john@example.com"
            type="email"
            required
          />
        </div>

        {/* Phone */}
        <div>
          <Label htmlFor="phone">Phone Number *</Label>
          <Input
            name="phone"
            id="phone"
            value={form.phone}
            onChange={onFormChange}
            placeholder="(555) 123-4567"
            type="tel"
            required
          />
        </div>

        {/* Property Assignment */}
        <div>
          <Label htmlFor="propertyId">Assigned Property</Label>
          <Select
            value={form.propertyId || "none"}
            onValueChange={handleSelectChange}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select a property" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="none">No property assigned</SelectItem>
              {properties.map(property => (
                <SelectItem key={property.id} value={property.id}>
                  {property.address}, {property.city}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {/* Lease Start Date */}
        <div>
          <Label htmlFor="leaseStartDate">Lease Start Date *</Label>
          <Input
            name="leaseStartDate"
            id="leaseStartDate"
            value={form.leaseStartDate}
            onChange={onFormChange}
            type="date"
            required
          />
        </div>

        {/* Lease End Date */}
        <div>
          <Label htmlFor="leaseEndDate">Lease End Date *</Label>
          <Input
            name="leaseEndDate"
            id="leaseEndDate"
            value={form.leaseEndDate}
            onChange={onFormChange}
            type="date"
            required
          />
        </div>

        {/* Monthly Rent */}
        <div>
          <Label htmlFor="monthlyRent">Monthly Rent</Label>
          <Input
            name="monthlyRent"
            id="monthlyRent"
            value={form.monthlyRent || ""}
            onChange={onFormChange}
            placeholder="1500"
            type="number"
            step="0.01"
          />
        </div>

        {/* Security Deposit */}
        <div>
          <Label htmlFor="securityDeposit">Security Deposit</Label>
          <Input
            name="securityDeposit"
            id="securityDeposit"
            value={form.securityDeposit || ""}
            onChange={onFormChange}
            placeholder="1500"
            type="number"
            step="0.01"
          />
        </div>

        {/* Notes */}
        <div className="md:col-span-2">
          <Label htmlFor="notes">Notes</Label>
          <Textarea
            name="notes"
            id="notes"
            value={form.notes}
            onChange={onFormChange}
            placeholder="Additional information about the tenant..."
            rows={3}
          />
        </div>
      </div>

      <div className="flex gap-2 mt-6 justify-end">
        <Button variant="outline" type="button" onClick={onCancel}>
          Cancel
        </Button>
        <Button type="submit">
          {isEditing ? "Update" : "Add"} Tenant
        </Button>
      </div>
    </form>
  );
}

import { useMemo, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Edit3, Search } from "lucide-react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { useAuth } from "@/contexts/AuthContext";
import { listProperties, listTenants, updateProperty } from "@/services/dataService";
import { formatCurrency } from "@/lib/format";

function parseNumber(value) {
  if (value === "" || value === null || value === undefined) {
    return undefined;
  }
  const next = Number(value);
  return Number.isFinite(next) ? next : undefined;
}

export default function Properties() {
  const { currentUser } = useAuth();
  const userId = currentUser?._id;
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedProperty, setSelectedProperty] = useState(null);
  const [form, setForm] = useState({});

  const propertiesQuery = useQuery({
    queryKey: ["properties", userId],
    queryFn: () => listProperties(userId),
    enabled: Boolean(userId),
  });

  const tenantsQuery = useQuery({
    queryKey: ["tenants", userId],
    queryFn: () => listTenants(userId),
    enabled: Boolean(userId),
  });

  const updateMutation = useMutation({
    mutationFn: updateProperty,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["properties", userId] });
      setSelectedProperty(null);
    },
  });

  const tenantCountByProperty = useMemo(() => {
    const map = new Map();
    for (const tenant of tenantsQuery.data || []) {
      if (!tenant.isActive) continue;
      map.set(tenant.propertyId, (map.get(tenant.propertyId) || 0) + 1);
    }
    return map;
  }, [tenantsQuery.data]);

  const filtered = useMemo(() => {
    const term = searchTerm.trim().toLowerCase();
    if (!term) {
      return propertiesQuery.data || [];
    }
    return (propertiesQuery.data || []).filter((property) => {
      const haystack = [
        property.name,
        property.address,
        property.city,
        property.state,
        property.zipCode,
      ]
        .join(" ")
        .toLowerCase();
      return haystack.includes(term);
    });
  }, [propertiesQuery.data, searchTerm]);

  function openEdit(property) {
    setSelectedProperty(property);
    setForm({
      name: property.name || "",
      address: property.address || "",
      city: property.city || "",
      state: property.state || "",
      zipCode: property.zipCode || "",
      propertyType: property.propertyType || "Single Family",
      units: String(property.units ?? 1),
      monthlyRent: String(property.monthlyRent ?? 0),
      mortgageLoanBalance: property.mortgageLoanBalance ?? "",
      mortgageAPR: property.mortgageAPR ?? "",
      mortgageMonthlyPayment: property.mortgageMonthlyPayment ?? "",
      notes: property.notes || "",
    });
  }

  function handleSave() {
    if (!selectedProperty) return;
    updateMutation.mutate({
      id: selectedProperty._id,
      name: form.name.trim(),
      address: form.address.trim(),
      city: form.city.trim(),
      state: form.state.trim(),
      zipCode: form.zipCode.trim(),
      propertyType: form.propertyType.trim(),
      units: parseNumber(form.units) || 1,
      monthlyRent: parseNumber(form.monthlyRent) || 0,
      mortgageLoanBalance: parseNumber(form.mortgageLoanBalance),
      mortgageAPR: parseNumber(form.mortgageAPR),
      mortgageMonthlyPayment: parseNumber(form.mortgageMonthlyPayment),
      notes: form.notes.trim() || undefined,
      clearMortgageLoanBalance: form.mortgageLoanBalance === "",
      clearMortgageAPR: form.mortgageAPR === "",
      clearMortgageMonthlyPayment: form.mortgageMonthlyPayment === "",
    });
  }

  return (
    <PageLayout
      title="Properties"
      onRefresh={() => {
        propertiesQuery.refetch();
        tenantsQuery.refetch();
      }}
      isRefreshing={propertiesQuery.isFetching || tenantsQuery.isFetching}
    >
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Portfolio</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="relative max-w-md">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchTerm}
                onChange={(event) => setSearchTerm(event.target.value)}
                placeholder="Search by address or city"
                className="pl-9"
              />
            </div>
          </CardContent>
        </Card>

        {propertiesQuery.isLoading ? (
          <Card>
            <CardContent className="py-10 text-center text-muted-foreground">
              Loading properties...
            </CardContent>
          </Card>
        ) : null}

        {propertiesQuery.error ? (
          <Card>
            <CardContent className="py-6 text-sm text-red-600">
              {propertiesQuery.error.message}
            </CardContent>
          </Card>
        ) : null}

        {!propertiesQuery.isLoading && !propertiesQuery.error ? (
          <div className="grid gap-4">
            {filtered.map((property) => (
              <Card key={property._id}>
                <CardContent className="pt-6">
                  <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
                    <div className="space-y-2">
                      <div className="flex items-center gap-2">
                        <h3 className="text-lg font-semibold">{property.name || property.address}</h3>
                        <Badge variant="outline">{property.propertyType}</Badge>
                      </div>
                      <p className="text-sm text-muted-foreground">
                        {property.address}, {property.city}, {property.state} {property.zipCode}
                      </p>
                      <div className="grid gap-1 text-sm sm:grid-cols-2 lg:grid-cols-4 lg:gap-4">
                        <p>
                          <span className="text-muted-foreground">Rent:</span>{" "}
                          <span className="font-medium">{formatCurrency(property.monthlyRent)}</span>
                        </p>
                        <p>
                          <span className="text-muted-foreground">Units:</span>{" "}
                          <span className="font-medium">{property.units}</span>
                        </p>
                        <p>
                          <span className="text-muted-foreground">Tenants:</span>{" "}
                          <span className="font-medium">{tenantCountByProperty.get(property._id) || 0}</span>
                        </p>
                        <p>
                          <span className="text-muted-foreground">Mortgage:</span>{" "}
                          <span className="font-medium">
                            {property.mortgageMonthlyPayment
                              ? formatCurrency(property.mortgageMonthlyPayment)
                              : "—"}
                          </span>
                        </p>
                      </div>
                    </div>
                    <Button variant="outline" size="sm" onClick={() => openEdit(property)}>
                      <Edit3 className="mr-2 h-4 w-4" />
                      Edit
                    </Button>
                  </div>
                </CardContent>
              </Card>
            ))}
            {filtered.length === 0 ? (
              <Card>
                <CardContent className="py-10 text-center text-muted-foreground">
                  No matching properties found.
                </CardContent>
              </Card>
            ) : null}
          </div>
        ) : null}
      </div>

      <Dialog open={Boolean(selectedProperty)} onOpenChange={(open) => !open && setSelectedProperty(null)}>
        <DialogContent className="max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Edit Property</DialogTitle>
          </DialogHeader>

          <div className="grid gap-3 py-2">
            <div className="space-y-1">
              <Label>Name</Label>
              <Input
                value={form.name || ""}
                onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))}
              />
            </div>
            <div className="space-y-1">
              <Label>Address</Label>
              <Input
                value={form.address || ""}
                onChange={(event) => setForm((prev) => ({ ...prev, address: event.target.value }))}
              />
            </div>

            <div className="grid gap-3 sm:grid-cols-3">
              <div className="space-y-1">
                <Label>City</Label>
                <Input
                  value={form.city || ""}
                  onChange={(event) => setForm((prev) => ({ ...prev, city: event.target.value }))}
                />
              </div>
              <div className="space-y-1">
                <Label>State</Label>
                <Input
                  value={form.state || ""}
                  onChange={(event) => setForm((prev) => ({ ...prev, state: event.target.value }))}
                />
              </div>
              <div className="space-y-1">
                <Label>ZIP</Label>
                <Input
                  value={form.zipCode || ""}
                  onChange={(event) => setForm((prev) => ({ ...prev, zipCode: event.target.value }))}
                />
              </div>
            </div>

            <div className="grid gap-3 sm:grid-cols-3">
              <div className="space-y-1">
                <Label>Type</Label>
                <Input
                  value={form.propertyType || ""}
                  onChange={(event) =>
                    setForm((prev) => ({ ...prev, propertyType: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>Units</Label>
                <Input
                  type="number"
                  min="1"
                  value={form.units || ""}
                  onChange={(event) => setForm((prev) => ({ ...prev, units: event.target.value }))}
                />
              </div>
              <div className="space-y-1">
                <Label>Monthly rent</Label>
                <Input
                  type="number"
                  min="0"
                  value={form.monthlyRent || ""}
                  onChange={(event) =>
                    setForm((prev) => ({ ...prev, monthlyRent: event.target.value }))
                  }
                />
              </div>
            </div>

            <div className="grid gap-3 sm:grid-cols-3">
              <div className="space-y-1">
                <Label>Loan balance</Label>
                <Input
                  type="number"
                  min="0"
                  value={form.mortgageLoanBalance}
                  onChange={(event) =>
                    setForm((prev) => ({ ...prev, mortgageLoanBalance: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>APR (%)</Label>
                <Input
                  type="number"
                  min="0"
                  step="0.01"
                  value={form.mortgageAPR}
                  onChange={(event) => setForm((prev) => ({ ...prev, mortgageAPR: event.target.value }))}
                />
              </div>
              <div className="space-y-1">
                <Label>Monthly mortgage payment</Label>
                <Input
                  type="number"
                  min="0"
                  value={form.mortgageMonthlyPayment}
                  onChange={(event) =>
                    setForm((prev) => ({ ...prev, mortgageMonthlyPayment: event.target.value }))
                  }
                />
              </div>
            </div>

            <div className="space-y-1">
              <Label>Notes</Label>
              <Input
                value={form.notes || ""}
                onChange={(event) => setForm((prev) => ({ ...prev, notes: event.target.value }))}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setSelectedProperty(null)}>
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={updateMutation.isPending}>
              {updateMutation.isPending ? "Saving..." : "Save changes"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </PageLayout>
  );
}

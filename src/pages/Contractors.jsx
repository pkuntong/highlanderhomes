import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus, Search } from "lucide-react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useAuth } from "@/contexts/AuthContext";
import { createContractor, listContractors, updateContractor } from "@/services/dataService";

function normalizeWebsite(value) {
  const trimmed = (value || "").trim();
  if (!trimmed) return "";
  if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
    return trimmed;
  }
  return `https://${trimmed}`;
}

function parseSpecialty(value) {
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

export default function Contractors() {
  const { currentUser } = useAuth();
  const userId = currentUser?._id;
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState("");
  const [specialtyFilter, setSpecialtyFilter] = useState("all");
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [createForm, setCreateForm] = useState({
    companyName: "",
    contactName: "",
    phone: "",
    email: "",
    address: "",
    website: "",
    notes: "",
    specialty: "",
  });
  const [editForm, setEditForm] = useState({
    companyName: "",
    contactName: "",
    phone: "",
    email: "",
    address: "",
    website: "",
    notes: "",
    specialty: "",
  });

  const contractorsQuery = useQuery({
    queryKey: ["contractors", userId, "all"],
    queryFn: () => listContractors(userId),
    enabled: Boolean(userId),
  });

  const createMutation = useMutation({
    mutationFn: createContractor,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["contractors", userId] });
      setIsCreateOpen(false);
      setCreateForm({
        companyName: "",
        contactName: "",
        phone: "",
        email: "",
        address: "",
        website: "",
        notes: "",
        specialty: "",
      });
    },
  });

  const updateMutation = useMutation({
    mutationFn: updateContractor,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["contractors", userId] });
      setEditing(null);
    },
  });

  const specialties = useMemo(() => {
    const set = new Set();
    for (const contractor of contractorsQuery.data || []) {
      for (const item of contractor.specialty || []) {
        set.add(item);
      }
    }
    return [...set].sort((a, b) => a.localeCompare(b));
  }, [contractorsQuery.data]);

  const filtered = useMemo(() => {
    const term = searchTerm.trim().toLowerCase();
    return (contractorsQuery.data || []).filter((contractor) => {
      if (specialtyFilter !== "all" && !(contractor.specialty || []).includes(specialtyFilter)) {
        return false;
      }
      if (!term) return true;
      const haystack = [
        contractor.companyName,
        contractor.contactName,
        contractor.phone,
        contractor.email,
        contractor.address,
        contractor.website,
      ]
        .join(" ")
        .toLowerCase();
      return haystack.includes(term);
    });
  }, [contractorsQuery.data, searchTerm, specialtyFilter]);

  function openEdit(contractor) {
    setEditing(contractor);
    setEditForm({
      companyName: contractor.companyName || "",
      contactName: contractor.contactName || "",
      phone: contractor.phone || "",
      email: contractor.email || "",
      address: contractor.address || "",
      website: contractor.website || "",
      notes: contractor.notes || "",
      specialty: (contractor.specialty || []).join(", "),
    });
  }

  return (
    <PageLayout
      title="Contractors"
      onRefresh={() => contractorsQuery.refetch()}
      isRefreshing={contractorsQuery.isFetching}
    >
      <div className="space-y-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <CardTitle className="text-base">Directory</CardTitle>
            <Button onClick={() => setIsCreateOpen(true)} className="gap-2">
              <Plus className="h-4 w-4" />
              Add contractor
            </Button>
          </CardHeader>
          <CardContent className="grid gap-3 md:grid-cols-2">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchTerm}
                onChange={(event) => setSearchTerm(event.target.value)}
                placeholder="Search company, contact, phone, email..."
                className="pl-9"
              />
            </div>
            <select
              value={specialtyFilter}
              onChange={(event) => setSpecialtyFilter(event.target.value)}
              className="h-10 rounded-md border bg-background px-3 text-sm"
            >
              <option value="all">All categories</option>
              {specialties.map((specialty) => (
                <option key={specialty} value={specialty}>
                  {specialty}
                </option>
              ))}
            </select>
          </CardContent>
        </Card>

        <div className="grid gap-4">
          {filtered.map((contractor) => (
            <Card key={contractor._id}>
              <CardContent className="pt-6">
                <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
                  <div className="space-y-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="text-lg font-semibold">{contractor.companyName}</h3>
                      {(contractor.specialty || []).map((item) => (
                        <Badge key={item} variant="outline">
                          {item}
                        </Badge>
                      ))}
                    </div>
                    <p className="text-sm text-muted-foreground">{contractor.contactName}</p>
                    <div className="grid gap-1 text-sm">
                      <a href={`tel:${contractor.phone}`} className="text-primary underline underline-offset-4">
                        {contractor.phone}
                      </a>
                      {contractor.email ? (
                        <a
                          href={`mailto:${contractor.email}`}
                          className="text-primary underline underline-offset-4"
                        >
                          {contractor.email}
                        </a>
                      ) : null}
                      {contractor.website ? (
                        <a
                          href={normalizeWebsite(contractor.website)}
                          target="_blank"
                          rel="noreferrer"
                          className="text-primary underline underline-offset-4 break-all"
                        >
                          {contractor.website}
                        </a>
                      ) : null}
                      {contractor.address ? <p className="text-muted-foreground">{contractor.address}</p> : null}
                      {contractor.notes ? <p className="text-muted-foreground">{contractor.notes}</p> : null}
                    </div>
                  </div>
                  <Button variant="outline" size="sm" onClick={() => openEdit(contractor)}>
                    Edit
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
          {filtered.length === 0 ? (
            <Card>
              <CardContent className="py-10 text-center text-muted-foreground">
                No contractors found.
              </CardContent>
            </Card>
          ) : null}
        </div>
      </div>

      <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add contractor</DialogTitle>
          </DialogHeader>
          <div className="grid gap-3">
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1">
                <Label>Company</Label>
                <Input
                  value={createForm.companyName}
                  onChange={(event) =>
                    setCreateForm((prev) => ({ ...prev, companyName: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>Contact</Label>
                <Input
                  value={createForm.contactName}
                  onChange={(event) =>
                    setCreateForm((prev) => ({ ...prev, contactName: event.target.value }))
                  }
                />
              </div>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1">
                <Label>Phone</Label>
                <Input
                  value={createForm.phone}
                  onChange={(event) => setCreateForm((prev) => ({ ...prev, phone: event.target.value }))}
                />
              </div>
              <div className="space-y-1">
                <Label>Email</Label>
                <Input
                  value={createForm.email}
                  onChange={(event) => setCreateForm((prev) => ({ ...prev, email: event.target.value }))}
                />
              </div>
            </div>
            <div className="space-y-1">
              <Label>Address</Label>
              <Input
                value={createForm.address}
                onChange={(event) => setCreateForm((prev) => ({ ...prev, address: event.target.value }))}
              />
            </div>
            <div className="space-y-1">
              <Label>Website</Label>
              <Input
                value={createForm.website}
                onChange={(event) => setCreateForm((prev) => ({ ...prev, website: event.target.value }))}
              />
            </div>
            <div className="space-y-1">
              <Label>Categories (comma separated)</Label>
              <Input
                value={createForm.specialty}
                onChange={(event) =>
                  setCreateForm((prev) => ({ ...prev, specialty: event.target.value }))
                }
              />
            </div>
            <div className="space-y-1">
              <Label>Notes</Label>
              <Input
                value={createForm.notes}
                onChange={(event) => setCreateForm((prev) => ({ ...prev, notes: event.target.value }))}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={() =>
                createMutation.mutate({
                  userId,
                  companyName: createForm.companyName.trim(),
                  contactName: createForm.contactName.trim(),
                  phone: createForm.phone.trim(),
                  email: createForm.email.trim(),
                  address: createForm.address.trim() || undefined,
                  website: createForm.website.trim() || undefined,
                  notes: createForm.notes.trim() || undefined,
                  specialty: parseSpecialty(createForm.specialty),
                  isPreferred: false,
                })
              }
              disabled={
                createMutation.isPending ||
                !createForm.companyName.trim() ||
                !createForm.contactName.trim() ||
                !createForm.phone.trim()
              }
            >
              {createMutation.isPending ? "Saving..." : "Save contractor"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(editing)} onOpenChange={(open) => !open && setEditing(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit contractor</DialogTitle>
          </DialogHeader>
          <div className="grid gap-3">
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1">
                <Label>Company</Label>
                <Input
                  value={editForm.companyName}
                  onChange={(event) =>
                    setEditForm((prev) => ({ ...prev, companyName: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>Contact</Label>
                <Input
                  value={editForm.contactName}
                  onChange={(event) =>
                    setEditForm((prev) => ({ ...prev, contactName: event.target.value }))
                  }
                />
              </div>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1">
                <Label>Phone</Label>
                <Input
                  value={editForm.phone}
                  onChange={(event) => setEditForm((prev) => ({ ...prev, phone: event.target.value }))}
                />
              </div>
              <div className="space-y-1">
                <Label>Email</Label>
                <Input
                  value={editForm.email}
                  onChange={(event) => setEditForm((prev) => ({ ...prev, email: event.target.value }))}
                />
              </div>
            </div>
            <div className="space-y-1">
              <Label>Address</Label>
              <Input
                value={editForm.address}
                onChange={(event) => setEditForm((prev) => ({ ...prev, address: event.target.value }))}
              />
            </div>
            <div className="space-y-1">
              <Label>Website</Label>
              <Input
                value={editForm.website}
                onChange={(event) => setEditForm((prev) => ({ ...prev, website: event.target.value }))}
              />
            </div>
            <div className="space-y-1">
              <Label>Categories</Label>
              <Input
                value={editForm.specialty}
                onChange={(event) => setEditForm((prev) => ({ ...prev, specialty: event.target.value }))}
              />
            </div>
            <div className="space-y-1">
              <Label>Notes</Label>
              <Input
                value={editForm.notes}
                onChange={(event) => setEditForm((prev) => ({ ...prev, notes: event.target.value }))}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditing(null)}>
              Cancel
            </Button>
            <Button
              onClick={() =>
                updateMutation.mutate({
                  id: editing._id,
                  companyName: editForm.companyName.trim(),
                  contactName: editForm.contactName.trim(),
                  phone: editForm.phone.trim(),
                  email: editForm.email.trim(),
                  address: editForm.address.trim() || undefined,
                  website: editForm.website.trim() || undefined,
                  notes: editForm.notes.trim() || undefined,
                  specialty: parseSpecialty(editForm.specialty),
                })
              }
              disabled={updateMutation.isPending}
            >
              {updateMutation.isPending ? "Saving..." : "Save changes"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </PageLayout>
  );
}

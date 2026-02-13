import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus } from "lucide-react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useAuth } from "@/contexts/AuthContext";
import {
  createMaintenanceRequest,
  listContractors,
  listMaintenanceRequests,
  listProperties,
  updateMaintenanceRequest,
  updateMaintenanceStatus,
} from "@/services/dataService";
import { formatCurrency, formatDate } from "@/lib/format";

const PRIORITIES = ["low", "normal", "high", "urgent", "emergency"];
const STATUSES = [
  "new",
  "acknowledged",
  "scheduled",
  "inProgress",
  "awaitingParts",
  "completed",
  "cancelled",
];

function parseNumber(value) {
  if (value === "" || value === null || value === undefined) {
    return undefined;
  }
  const next = Number(value);
  return Number.isFinite(next) ? next : undefined;
}

export default function MaintenanceRequests() {
  const { currentUser } = useAuth();
  const userId = currentUser?._id;
  const queryClient = useQueryClient();

  const [statusFilter, setStatusFilter] = useState("all");
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [editingRequest, setEditingRequest] = useState(null);

  const [newForm, setNewForm] = useState({
    propertyId: "",
    title: "",
    category: "General",
    priority: "normal",
    descriptionText: "",
  });

  const [editForm, setEditForm] = useState({
    title: "",
    category: "",
    priority: "normal",
    descriptionText: "",
    notes: "",
    estimatedCost: "",
    actualCost: "",
  });

  const propertiesQuery = useQuery({
    queryKey: ["properties", userId],
    queryFn: () => listProperties(userId),
    enabled: Boolean(userId),
  });

  const contractorsQuery = useQuery({
    queryKey: ["contractors", userId, "all"],
    queryFn: () => listContractors(userId),
    enabled: Boolean(userId),
  });

  const maintenanceQuery = useQuery({
    queryKey: ["maintenance", userId],
    queryFn: () => listMaintenanceRequests(userId),
    enabled: Boolean(userId),
  });

  const createMutation = useMutation({
    mutationFn: createMaintenanceRequest,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["maintenance", userId] });
      setIsCreateOpen(false);
      setNewForm({
        propertyId: "",
        title: "",
        category: "General",
        priority: "normal",
        descriptionText: "",
      });
    },
  });

  const updateMutation = useMutation({
    mutationFn: updateMaintenanceRequest,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["maintenance", userId] });
      setEditingRequest(null);
    },
  });

  const statusMutation = useMutation({
    mutationFn: updateMaintenanceStatus,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["maintenance", userId] });
    },
  });

  const propertyMap = useMemo(
    () =>
      Object.fromEntries(
        (propertiesQuery.data || []).map((property) => [
          property._id,
          property.name || `${property.address}, ${property.city}`,
        ])
      ),
    [propertiesQuery.data]
  );

  const contractorMap = useMemo(
    () =>
      Object.fromEntries(
        (contractorsQuery.data || []).map((contractor) => [
          contractor._id,
          contractor.companyName,
        ])
      ),
    [contractorsQuery.data]
  );

  const filteredRequests = useMemo(() => {
    const requests = maintenanceQuery.data || [];
    if (statusFilter === "all") {
      return requests;
    }
    return requests.filter((request) => request.status === statusFilter);
  }, [maintenanceQuery.data, statusFilter]);

  function handleCreateRequest() {
    createMutation.mutate({
      userId,
      propertyId: newForm.propertyId,
      title: newForm.title.trim(),
      category: newForm.category.trim() || "General",
      priority: newForm.priority,
      descriptionText: newForm.descriptionText.trim(),
    });
  }

  function openEditDialog(request) {
    setEditingRequest(request);
    setEditForm({
      title: request.title || "",
      category: request.category || "",
      priority: request.priority || "normal",
      descriptionText: request.description || "",
      notes: request.notes || "",
      estimatedCost: request.estimatedCost ?? "",
      actualCost: request.actualCost ?? "",
    });
  }

  function handleSaveEdit() {
    if (!editingRequest) return;
    updateMutation.mutate({
      id: editingRequest._id,
      title: editForm.title.trim(),
      category: editForm.category.trim(),
      priority: editForm.priority,
      descriptionText: editForm.descriptionText.trim(),
      notes: editForm.notes.trim() || undefined,
      estimatedCost: parseNumber(editForm.estimatedCost),
      actualCost: parseNumber(editForm.actualCost),
    });
  }

  return (
    <PageLayout
      title="Maintenance"
      onRefresh={() => maintenanceQuery.refetch()}
      isRefreshing={maintenanceQuery.isFetching}
    >
      <div className="space-y-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <CardTitle className="text-base">Requests</CardTitle>
            <Button type="button" onClick={() => setIsCreateOpen(true)} className="gap-2">
              <Plus className="h-4 w-4" />
              New request
            </Button>
          </CardHeader>
          <CardContent className="flex flex-wrap items-center gap-2">
            <Label htmlFor="statusFilter" className="text-sm text-muted-foreground">
              Status
            </Label>
            <select
              id="statusFilter"
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value)}
              className="h-9 rounded-md border bg-background px-3 text-sm"
            >
              <option value="all">All</option>
              {STATUSES.map((status) => (
                <option key={status} value={status}>
                  {status}
                </option>
              ))}
            </select>
          </CardContent>
        </Card>

        {maintenanceQuery.isLoading ? (
          <Card>
            <CardContent className="py-10 text-center text-muted-foreground">
              Loading maintenance requests...
            </CardContent>
          </Card>
        ) : null}

        {maintenanceQuery.error ? (
          <Card>
            <CardContent className="py-6 text-sm text-red-600">
              {maintenanceQuery.error.message}
            </CardContent>
          </Card>
        ) : null}

        {!maintenanceQuery.isLoading && !maintenanceQuery.error ? (
          <div className="grid gap-4">
            {filteredRequests.map((request) => (
              <Card key={request._id}>
                <CardContent className="pt-6">
                  <div className="space-y-3">
                    <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                      <div>
                        <h3 className="text-lg font-semibold">{request.title}</h3>
                        <p className="text-sm text-muted-foreground">
                          {propertyMap[request.propertyId] || "Unknown property"}
                        </p>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge variant="outline">{request.priority}</Badge>
                        <select
                          value={request.status}
                          onChange={(event) =>
                            statusMutation.mutate({
                              id: request._id,
                              status: event.target.value,
                            })
                          }
                          className="h-9 rounded-md border bg-background px-2 text-sm"
                        >
                          {STATUSES.map((status) => (
                            <option key={status} value={status}>
                              {status}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>

                    <p className="text-sm">{request.description}</p>

                    <div className="grid gap-1 text-xs text-muted-foreground sm:grid-cols-2 lg:grid-cols-4">
                      <p>Category: {request.category}</p>
                      <p>
                        Contractor:{" "}
                        {request.contractorId ? contractorMap[request.contractorId] || "Assigned" : "Unassigned"}
                      </p>
                      <p>Estimated: {request.estimatedCost ? formatCurrency(request.estimatedCost) : "—"}</p>
                      <p>Updated: {formatDate(request.updatedAt)}</p>
                    </div>

                    <div className="flex justify-end">
                      <Button variant="outline" size="sm" onClick={() => openEditDialog(request)}>
                        Edit details
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
            {filteredRequests.length === 0 ? (
              <Card>
                <CardContent className="py-10 text-center text-muted-foreground">
                  No requests in this status.
                </CardContent>
              </Card>
            ) : null}
          </div>
        ) : null}
      </div>

      <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>New maintenance request</DialogTitle>
          </DialogHeader>

          <div className="space-y-3">
            <div className="space-y-1">
              <Label>Property</Label>
              <select
                value={newForm.propertyId}
                onChange={(event) =>
                  setNewForm((prev) => ({ ...prev, propertyId: event.target.value }))
                }
                className="h-10 w-full rounded-md border bg-background px-3 text-sm"
              >
                <option value="">Select property</option>
                {(propertiesQuery.data || []).map((property) => (
                  <option key={property._id} value={property._id}>
                    {property.name || property.address}
                  </option>
                ))}
              </select>
            </div>

            <div className="space-y-1">
              <Label>Title</Label>
              <Input
                value={newForm.title}
                onChange={(event) => setNewForm((prev) => ({ ...prev, title: event.target.value }))}
              />
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1">
                <Label>Category</Label>
                <Input
                  value={newForm.category}
                  onChange={(event) =>
                    setNewForm((prev) => ({ ...prev, category: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>Priority</Label>
                <select
                  value={newForm.priority}
                  onChange={(event) =>
                    setNewForm((prev) => ({ ...prev, priority: event.target.value }))
                  }
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                >
                  {PRIORITIES.map((priority) => (
                    <option key={priority} value={priority}>
                      {priority}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="space-y-1">
              <Label>Description</Label>
              <Textarea
                value={newForm.descriptionText}
                onChange={(event) =>
                  setNewForm((prev) => ({ ...prev, descriptionText: event.target.value }))
                }
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button
              onClick={handleCreateRequest}
              disabled={
                createMutation.isPending ||
                !newForm.propertyId ||
                !newForm.title.trim() ||
                !newForm.descriptionText.trim()
              }
            >
              {createMutation.isPending ? "Saving..." : "Create request"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(editingRequest)} onOpenChange={(open) => !open && setEditingRequest(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit request</DialogTitle>
          </DialogHeader>

          <div className="space-y-3">
            <div className="space-y-1">
              <Label>Title</Label>
              <Input
                value={editForm.title}
                onChange={(event) => setEditForm((prev) => ({ ...prev, title: event.target.value }))}
              />
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1">
                <Label>Category</Label>
                <Input
                  value={editForm.category}
                  onChange={(event) =>
                    setEditForm((prev) => ({ ...prev, category: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>Priority</Label>
                <select
                  value={editForm.priority}
                  onChange={(event) =>
                    setEditForm((prev) => ({ ...prev, priority: event.target.value }))
                  }
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                >
                  {PRIORITIES.map((priority) => (
                    <option key={priority} value={priority}>
                      {priority}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="space-y-1">
              <Label>Description</Label>
              <Textarea
                value={editForm.descriptionText}
                onChange={(event) =>
                  setEditForm((prev) => ({ ...prev, descriptionText: event.target.value }))
                }
              />
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-1">
                <Label>Estimated cost</Label>
                <Input
                  type="number"
                  min="0"
                  value={editForm.estimatedCost}
                  onChange={(event) =>
                    setEditForm((prev) => ({ ...prev, estimatedCost: event.target.value }))
                  }
                />
              </div>
              <div className="space-y-1">
                <Label>Actual cost</Label>
                <Input
                  type="number"
                  min="0"
                  value={editForm.actualCost}
                  onChange={(event) =>
                    setEditForm((prev) => ({ ...prev, actualCost: event.target.value }))
                  }
                />
              </div>
            </div>

            <div className="space-y-1">
              <Label>Notes</Label>
              <Textarea
                value={editForm.notes}
                onChange={(event) => setEditForm((prev) => ({ ...prev, notes: event.target.value }))}
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setEditingRequest(null)}>
              Cancel
            </Button>
            <Button onClick={handleSaveEdit} disabled={updateMutation.isPending}>
              {updateMutation.isPending ? "Saving..." : "Save changes"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </PageLayout>
  );
}

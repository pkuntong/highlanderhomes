import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Eye, FileImage, FileText, Loader2, Search, Trash2, Upload } from "lucide-react";
import { useSearchParams } from "react-router-dom";
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
import {
  createDocument,
  generateDocumentUploadUrl,
  listDocuments,
  listProperties,
  removeDocument,
  updateDocument,
} from "@/services/dataService";
import { formatDate } from "@/lib/format";

const CATEGORIES = [
  "lease",
  "insurance",
  "contractor",
  "receipt",
  "tax",
  "photo",
  "other",
];

function formatBytes(bytes) {
  const value = Number(bytes || 0);
  if (!value) return "—";
  if (value < 1024) return `${value} B`;
  if (value < 1024 * 1024) return `${(value / 1024).toFixed(1)} KB`;
  if (value < 1024 * 1024 * 1024) return `${(value / (1024 * 1024)).toFixed(1)} MB`;
  return `${(value / (1024 * 1024 * 1024)).toFixed(1)} GB`;
}

function isImageDocument(document) {
  return String(document?.contentType || "").startsWith("image/");
}

function isPdfDocument(document) {
  return String(document?.contentType || "").includes("pdf");
}

export default function Documents() {
  const { currentUser } = useAuth();
  const userId = currentUser?._id;
  const queryClient = useQueryClient();
  const [searchParams, setSearchParams] = useSearchParams();

  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [propertyFilter, setPropertyFilter] = useState("all");

  const [selectedFile, setSelectedFile] = useState(null);
  const [uploadForm, setUploadForm] = useState({
    title: "",
    category: "lease",
    propertyId: "",
    notes: "",
  });

  const [editingDocument, setEditingDocument] = useState(null);
  const [previewDocument, setPreviewDocument] = useState(null);
  const [editForm, setEditForm] = useState({
    title: "",
    category: "other",
    propertyId: "",
    notes: "",
  });

  useEffect(() => {
    const propertyIdParam = searchParams.get("propertyId");
    const categoryParam = searchParams.get("category");
    setCategoryFilter(categoryParam || "all");
    if (!propertyIdParam) {
      setPropertyFilter("all");
      return;
    }
    setPropertyFilter(propertyIdParam);
  }, [searchParams]);

  const propertiesQuery = useQuery({
    queryKey: ["properties", userId],
    queryFn: () => listProperties(userId),
    enabled: Boolean(userId),
  });

  const documentsQuery = useQuery({
    queryKey: ["documents", userId],
    queryFn: () => listDocuments(userId),
    enabled: Boolean(userId),
  });

  const uploadMutation = useMutation({
    mutationFn: async () => {
      if (!selectedFile) {
        throw new Error("Pick a file first.");
      }
      const uploadUrl = await generateDocumentUploadUrl();
      const uploadResponse = await fetch(uploadUrl, {
        method: "POST",
        headers: {
          "Content-Type": selectedFile.type || "application/octet-stream",
        },
        body: selectedFile,
      });

      if (!uploadResponse.ok) {
        throw new Error("Upload failed.");
      }

      const { storageId } = await uploadResponse.json();

      return createDocument({
        userId,
        propertyId: uploadForm.propertyId || undefined,
        title: uploadForm.title.trim() || selectedFile.name,
        category: uploadForm.category,
        storageId,
        contentType: selectedFile.type || "application/octet-stream",
        fileSizeBytes: selectedFile.size,
        notes: uploadForm.notes.trim() || undefined,
      });
    },
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["documents", userId] });
      setSelectedFile(null);
      setUploadForm({
        title: "",
        category: "lease",
        propertyId: "",
        notes: "",
      });
    },
  });

  const updateMutation = useMutation({
    mutationFn: updateDocument,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["documents", userId] });
      setEditingDocument(null);
    },
  });

  const removeMutation = useMutation({
    mutationFn: removeDocument,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["documents", userId] });
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

  const filteredDocuments = useMemo(() => {
    const term = searchTerm.trim().toLowerCase();
    return (documentsQuery.data || []).filter((document) => {
      if (categoryFilter !== "all" && document.category !== categoryFilter) {
        return false;
      }
      if (propertyFilter !== "all") {
        if (propertyFilter === "portfolio") {
          if (document.propertyId) return false;
        } else if (document.propertyId !== propertyFilter) {
          return false;
        }
      }
      if (!term) return true;
      const haystack = [document.title, document.notes, document.category]
        .join(" ")
        .toLowerCase();
      return haystack.includes(term);
    });
  }, [documentsQuery.data, categoryFilter, propertyFilter, searchTerm]);

  function startEdit(document) {
    setEditingDocument(document);
    setEditForm({
      title: document.title || "",
      category: document.category || "other",
      propertyId: document.propertyId || "",
      notes: document.notes || "",
    });
  }

  return (
    <PageLayout
      title="Documents"
      onRefresh={() => documentsQuery.refetch()}
      isRefreshing={documentsQuery.isFetching}
    >
      <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Secure Vault</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Upload leases, contracts, insurance documents, PDFs, and photos. Files are stored in Convex file storage and linked to your account.
            </p>

            <div className="grid gap-3 md:grid-cols-2">
              <div className="space-y-1">
                <Label htmlFor="document-file">Document file</Label>
                <Input
                  id="document-file"
                  type="file"
                  onChange={(event) => {
                    const file = event.target.files?.[0] || null;
                    setSelectedFile(file);
                    if (file) {
                      setUploadForm((prev) => ({
                        ...prev,
                        title: prev.title || file.name,
                      }));
                    }
                  }}
                />
              </div>
              <div className="space-y-1">
                <Label>Title</Label>
                <Input
                  value={uploadForm.title}
                  onChange={(event) =>
                    setUploadForm((prev) => ({ ...prev, title: event.target.value }))
                  }
                  placeholder="Lease - 3441 Dunran"
                />
              </div>
            </div>

            <div className="grid gap-3 md:grid-cols-3">
              <div className="space-y-1">
                <Label>Category</Label>
                <select
                  value={uploadForm.category}
                  onChange={(event) =>
                    setUploadForm((prev) => ({ ...prev, category: event.target.value }))
                  }
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                >
                  {CATEGORIES.map((category) => (
                    <option key={category} value={category}>
                      {category}
                    </option>
                  ))}
                </select>
              </div>
              <div className="space-y-1">
                <Label>Property</Label>
                <select
                  value={uploadForm.propertyId}
                  onChange={(event) =>
                    setUploadForm((prev) => ({ ...prev, propertyId: event.target.value }))
                  }
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                >
                  <option value="">Portfolio-level</option>
                  {(propertiesQuery.data || []).map((property) => (
                    <option key={property._id} value={property._id}>
                      {property.name || property.address}
                    </option>
                  ))}
                </select>
              </div>
              <div className="space-y-1">
                <Label>Notes</Label>
                <Input
                  value={uploadForm.notes}
                  onChange={(event) =>
                    setUploadForm((prev) => ({ ...prev, notes: event.target.value }))
                  }
                  placeholder="Optional notes"
                />
              </div>
            </div>

            <Button
              onClick={() => uploadMutation.mutate()}
              disabled={!selectedFile || uploadMutation.isPending}
              className="gap-2"
            >
              {uploadMutation.isPending ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Uploading...
                </>
              ) : (
                <>
                  <Upload className="h-4 w-4" />
                  Upload document
                </>
              )}
            </Button>

            {uploadMutation.error ? (
              <p className="text-sm text-red-600">{uploadMutation.error.message}</p>
            ) : null}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Saved Documents</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="grid gap-3 md:grid-cols-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  value={searchTerm}
                  onChange={(event) => setSearchTerm(event.target.value)}
                  className="pl-9"
                  placeholder="Search documents"
                />
              </div>
              <select
                value={categoryFilter}
                onChange={(event) => {
                  const value = event.target.value;
                  setCategoryFilter(value);
                  const nextParams = new URLSearchParams(searchParams);
                  if (value === "all") {
                    nextParams.delete("category");
                  } else {
                    nextParams.set("category", value);
                  }
                  setSearchParams(nextParams, { replace: true });
                }}
                className="h-10 rounded-md border bg-background px-3 text-sm"
              >
                <option value="all">All categories</option>
                {CATEGORIES.map((category) => (
                  <option key={category} value={category}>
                    {category}
                  </option>
                ))}
              </select>
              <select
                value={propertyFilter}
                onChange={(event) => {
                  const value = event.target.value;
                  setPropertyFilter(value);
                  const nextParams = new URLSearchParams(searchParams);
                  if (value === "all") {
                    nextParams.delete("propertyId");
                    setSearchParams(nextParams, { replace: true });
                  } else {
                    nextParams.set("propertyId", value);
                    setSearchParams(nextParams, { replace: true });
                  }
                }}
                className="h-10 rounded-md border bg-background px-3 text-sm"
              >
                <option value="all">All properties</option>
                <option value="portfolio">Portfolio-level</option>
                {(propertiesQuery.data || []).map((property) => (
                  <option key={property._id} value={property._id}>
                    {property.name || property.address}
                  </option>
                ))}
              </select>
            </div>

            <div className="grid gap-3">
              {filteredDocuments.map((document) => (
                <div
                  key={document._id}
                  className="flex flex-col gap-2 rounded-md border p-3 md:flex-row md:items-center md:justify-between"
                >
                  <div className="flex items-center gap-3">
                    <div className="h-14 w-14 overflow-hidden rounded-md border bg-muted flex items-center justify-center">
                      {isImageDocument(document) && document.downloadURL ? (
                        <img
                          src={document.downloadURL}
                          alt={document.title}
                          className="h-full w-full object-cover"
                          loading="lazy"
                        />
                      ) : isPdfDocument(document) ? (
                        <span className="text-xs font-semibold text-muted-foreground">PDF</span>
                      ) : (
                        <FileImage className="h-5 w-5 text-muted-foreground" />
                      )}
                    </div>
                    <div className="space-y-1">
                      <p className="font-medium flex items-center gap-2">
                        <FileText className="h-4 w-4 text-primary" />
                        {document.title}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        {propertyMap[document.propertyId] || "Portfolio-level"} • {formatDate(document.createdAt)} • {formatBytes(document.fileSizeBytes)}
                      </p>
                      {document.notes ? (
                        <p className="text-xs text-muted-foreground">{document.notes}</p>
                      ) : null}
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <Badge variant="outline">{document.category}</Badge>
                    <Button size="sm" variant="outline" onClick={() => setPreviewDocument(document)}>
                      <Eye className="h-4 w-4 mr-1" />
                      Preview
                    </Button>
                    {document.downloadURL ? (
                      <Button asChild size="sm" variant="outline">
                        <a href={document.downloadURL} target="_blank" rel="noreferrer">
                          Open
                        </a>
                      </Button>
                    ) : null}
                    <Button size="sm" variant="outline" onClick={() => startEdit(document)}>
                      Edit
                    </Button>
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => removeMutation.mutate(document._id)}
                      disabled={removeMutation.isPending}
                    >
                      <Trash2 className="h-4 w-4 text-red-600" />
                    </Button>
                  </div>
                </div>
              ))}

              {filteredDocuments.length === 0 ? (
                <p className="text-center text-sm text-muted-foreground py-8">
                  No documents found.
                </p>
              ) : null}
            </div>
          </CardContent>
        </Card>
      </div>

      <Dialog open={Boolean(previewDocument)} onOpenChange={(open) => !open && setPreviewDocument(null)}>
        <DialogContent className="max-w-4xl">
          <DialogHeader>
            <DialogTitle>{previewDocument?.title || "Document preview"}</DialogTitle>
          </DialogHeader>

          {previewDocument ? (
            <div className="space-y-3">
              {isImageDocument(previewDocument) && previewDocument.downloadURL ? (
                <img
                  src={previewDocument.downloadURL}
                  alt={previewDocument.title}
                  className="max-h-[70vh] w-full rounded-md border object-contain bg-muted"
                />
              ) : isPdfDocument(previewDocument) && previewDocument.downloadURL ? (
                <iframe
                  src={previewDocument.downloadURL}
                  title={previewDocument.title}
                  className="h-[70vh] w-full rounded-md border bg-muted"
                />
              ) : (
                <div className="rounded-md border p-6 text-sm text-muted-foreground">
                  Preview is not available for this file type. Use Open to download/view.
                </div>
              )}
            </div>
          ) : null}

          <DialogFooter>
            <Button variant="outline" onClick={() => setPreviewDocument(null)}>
              Close
            </Button>
            {previewDocument?.downloadURL ? (
              <Button asChild>
                <a href={previewDocument.downloadURL} target="_blank" rel="noreferrer">
                  Open in new tab
                </a>
              </Button>
            ) : null}
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={Boolean(editingDocument)} onOpenChange={(open) => !open && setEditingDocument(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit document</DialogTitle>
          </DialogHeader>

          <div className="grid gap-3">
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
                <select
                  value={editForm.category}
                  onChange={(event) =>
                    setEditForm((prev) => ({ ...prev, category: event.target.value }))
                  }
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                >
                  {CATEGORIES.map((category) => (
                    <option key={category} value={category}>
                      {category}
                    </option>
                  ))}
                </select>
              </div>
              <div className="space-y-1">
                <Label>Property</Label>
                <select
                  value={editForm.propertyId}
                  onChange={(event) =>
                    setEditForm((prev) => ({ ...prev, propertyId: event.target.value }))
                  }
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                >
                  <option value="">Portfolio-level</option>
                  {(propertiesQuery.data || []).map((property) => (
                    <option key={property._id} value={property._id}>
                      {property.name || property.address}
                    </option>
                  ))}
                </select>
              </div>
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
            <Button variant="outline" onClick={() => setEditingDocument(null)}>
              Cancel
            </Button>
            <Button
              onClick={() =>
                updateMutation.mutate({
                  id: editingDocument._id,
                  title: editForm.title.trim(),
                  category: editForm.category,
                  notes: editForm.notes.trim() || undefined,
                  propertyId: editForm.propertyId || undefined,
                  clearPropertyId: editForm.propertyId === "",
                })
              }
              disabled={updateMutation.isPending}
            >
              {updateMutation.isPending ? "Saving..." : "Save"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </PageLayout>
  );
}

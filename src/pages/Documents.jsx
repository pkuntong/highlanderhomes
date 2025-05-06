import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { FileText, Plus, Edit, Trash2 } from "lucide-react";

const LOCAL_STORAGE_KEY = "highlanderhomes_documents";

const mockDocuments = [
  { id: 1, name: "Property Insurance - 123 Highland Ave", type: "PDF", date: "2025-03-15" },
  { id: 2, name: "Lease Agreement - 101 Bluegrass Ln", type: "DOCX", date: "2025-01-10" },
  { id: 3, name: "Inspection Report - 456 Bourbon St", type: "PDF", date: "2024-12-05" },
  { id: 4, name: "Maintenance Contract - HVAC Systems", type: "PDF", date: "2024-10-20" },
];

const emptyDocument = { id: '', name: '', type: '', date: '', fileBase64: '' };

const Documents = () => {
  const [documents, setDocuments] = useState(() => {
    const stored = localStorage.getItem(LOCAL_STORAGE_KEY);
    return stored ? JSON.parse(stored) : mockDocuments;
  });
  const [isEditing, setIsEditing] = useState(false);
  const [editIndex, setEditIndex] = useState(null);
  const [form, setForm] = useState(emptyDocument);

  useEffect(() => {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(documents));
  }, [documents]);

  const handleEdit = (index) => {
    setEditIndex(index);
    setForm(documents[index]);
    setIsEditing(true);
  };

  const handleDelete = (index) => {
    if (window.confirm("Are you sure you want to delete this document?")) {
      setDocuments((prev) => prev.filter((_, i) => i !== index));
    }
  };

  const handleAdd = () => {
    setEditIndex(null);
    setForm({ ...emptyDocument, id: Date.now().toString() });
    setIsEditing(true);
  };

  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleFileUpload = (e) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setForm((prev) => ({ ...prev, fileBase64: reader.result }));
      };
      reader.readAsDataURL(file);
    }
  };

  const handleFormSubmit = (e) => {
    e.preventDefault();
    if (editIndex !== null) {
      setDocuments((prev) => prev.map((d, i) => (i === editIndex ? form : d)));
    } else {
      setDocuments((prev) => [...prev, form]);
    }
    setIsEditing(false);
    setForm(emptyDocument);
    setEditIndex(null);
  };

  const handleCancel = () => {
    setIsEditing(false);
    setForm(emptyDocument);
    setEditIndex(null);
  };

  return (
    <PageLayout title="Documents">
      <div className="mb-6 flex justify-between items-center">
        <h2 className="text-lg font-semibold">Property Documents</h2>
        <Button onClick={handleAdd}>
          <Plus className="mr-2 h-4 w-4" /> Upload Document
        </Button>
      </div>

      {isEditing && (
        <form onSubmit={handleFormSubmit} className="mb-6 p-4 border rounded bg-gray-50">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="name">Document Name</label>
              <Input name="name" id="name" value={form.name} onChange={handleFormChange} placeholder="Document Name" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="type">Type</label>
              <Input name="type" id="type" value={form.type} onChange={handleFormChange} placeholder="Type (PDF, DOCX, etc.)" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="date">Date</label>
              <Input name="date" id="date" value={form.date} onChange={handleFormChange} placeholder="YYYY-MM-DD" type="date" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="fileUpload">Upload File</label>
              <Input name="fileUpload" id="fileUpload" type="file" accept="application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,image/*" onChange={handleFileUpload} />
              {form.fileBase64 && (
                <span className="block text-xs text-green-600 mt-2">File uploaded</span>
              )}
            </div>
          </div>
          <div className="flex gap-2 mt-4 justify-end">
            <Button variant="outline" type="button" onClick={handleCancel}>Cancel</Button>
            <Button type="submit">{editIndex !== null ? "Update" : "Add"} Document</Button>
          </div>
        </form>
      )}

      {documents.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {documents.map((document, idx) => (
            <Card key={document.id} className="relative group hover:bg-gray-50">
              <CardContent className="p-4 flex items-center">
                <div className="p-3 bg-highlander-100 rounded-lg mr-3">
                  <FileText className="h-6 w-6 text-highlander-700" />
                </div>
                <div className="flex-1">
                  <h3 className="font-medium text-sm">{document.name}</h3>
                  <div className="flex justify-between mt-1">
                    <span className="text-xs text-gray-500">{document.type}</span>
                    <span className="text-xs text-gray-500">
                      {new Date(document.date).toLocaleDateString()}
                    </span>
                  </div>
                </div>
                <div className="absolute top-2 right-2 flex gap-2 opacity-0 group-hover:opacity-100 transition">
                  <Button size="icon" variant="outline" onClick={() => handleEdit(idx)}><Edit className="h-4 w-4" /></Button>
                  <Button size="icon" variant="destructive" onClick={() => handleDelete(idx)}><Trash2 className="h-4 w-4" /></Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <FileText className="h-10 w-10 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-medium mb-2">No documents yet</h3>
            <p className="text-gray-500 mb-4">
              Upload property-related documents to keep everything in one place
            </p>
            <Button onClick={handleAdd}>
              <Plus className="mr-2 h-4 w-4" /> Upload Document
            </Button>
          </CardContent>
        </Card>
      )}
    </PageLayout>
  );
};

export default Documents;

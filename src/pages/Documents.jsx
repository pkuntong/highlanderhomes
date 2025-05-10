import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { FileText, Plus, Edit, Trash2, Eye, Home } from "lucide-react";
import { db } from "@/firebase";
import {
  collection,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  doc
} from "firebase/firestore";
import React from "react";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

// Simple Modal component
function Modal({ open, onClose, children }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div className="bg-white rounded-lg shadow-lg max-w-2xl w-full p-6 relative">
        <button className="absolute top-2 right-2 text-gray-500 hover:text-gray-700" onClick={onClose}>&times;</button>
        {children}
      </div>
    </div>
  );
}

const CATEGORY_OPTIONS = [
  "Legal Document",
  "Inspection Report",
  "Floorplan",
  "Insurance",
  "Other"
];

const emptyDocument = { name: '', type: '', date: '', fileBase64: '', house_id: '', category: '', fileName: '', fileType: '' };

const Documents = () => {
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editIndex, setEditIndex] = useState(null);
  const [form, setForm] = useState(emptyDocument);
  const [modalOpen, setModalOpen] = useState(false);
  const [modalDoc, setModalDoc] = useState(null);
  const [properties, setProperties] = useState([]);
  const [activeHouse, setActiveHouse] = useState("all");

  // Fetch documents from Firestore on mount
  useEffect(() => {
    async function fetchDocuments() {
      setLoading(true);
      const querySnapshot = await getDocs(collection(db, "documents"));
      const docsData = querySnapshot.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() }));
      setDocuments(docsData);
      setLoading(false);
    }
    fetchDocuments();
    // Expose fetchDocuments for later use
    Documents.fetchDocuments = fetchDocuments;
  }, []);

  // Fetch properties for house dropdown
  useEffect(() => {
    async function fetchProperties() {
      const querySnapshot = await getDocs(collection(db, "properties"));
      setProperties(querySnapshot.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() })));
    }
    fetchProperties();
  }, []);

  const handleEdit = (index) => {
    setEditIndex(index);
    setForm(documents[index]);
    setIsEditing(true);
  };

  const handleDelete = async (index) => {
    if (window.confirm("Are you sure you want to delete this document?")) {
      const document = documents[index];
      await deleteDoc(doc(db, "documents", document.id));
      await Documents.fetchDocuments();
    }
  };

  const handleAdd = () => {
    setEditIndex(null);
    setForm(emptyDocument);
    setIsEditing(true);
  };

  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleFileUpload = (e) => {
    const file = e.target.files?.[0];
    if (file) {
      // Check file size - Firestore has a 1MB limit for document size
      if (file.size > 900000) { // ~900KB to leave room for other document data
        alert("File is too large. Please upload a file smaller than 900KB or use a file storage service instead.");
        return;
      }
      
      // For small files, we can store them directly in Firestore
      const reader = new FileReader();
      reader.onloadend = () => {
        setForm((prev) => ({ ...prev, fileBase64: reader.result, fileName: file.name, fileType: file.type }));
      };
      reader.readAsDataURL(file);
    }
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    try {
      // Validate form data
      if (!form.name || !form.date || !form.house_id) {
        alert("Please fill in all required fields");
        return;
      }
      
      // Check if file is too large for Firestore
      if (form.fileBase64 && form.fileBase64.length > 900000) {
        alert("File is too large for storage. Please use a smaller file (less than 900KB).");
        return;
      }
      
      // Prepare document data
      const docData = {
        name: form.name,
        type: form.type || form.fileType || '',
        date: form.date,
        house_id: form.house_id,
        category: form.category || '',
        fileName: form.fileName || '',
        fileType: form.fileType || '',
        fileBase64: form.fileBase64 || ''
      };
      
      if (editIndex !== null) {
        // Update
        const documentRef = doc(db, "documents", documents[editIndex].id);
        await updateDoc(documentRef, docData);
      } else {
        // Add new document
        await addDoc(collection(db, "documents"), docData);
      }
      
      await Documents.fetchDocuments();
      setIsEditing(false);
      setForm(emptyDocument);
      setEditIndex(null);
    } catch (error) {
      console.error("Error saving document:", error);
      alert(`Failed to save document: ${error.message}`);
    }
  };

  const handleCancel = () => {
    setIsEditing(false);
    setForm(emptyDocument);
    setEditIndex(null);
  };

  const handleView = (doc) => {
    setModalDoc(doc);
    setModalOpen(true);
  };

  const handleCloseModal = () => {
    setModalOpen(false);
    setModalDoc(null);
  };

  if (loading) return <div>Loading documents...</div>;

  // Filter documents based on active house
  const filteredDocuments = activeHouse === "all" 
    ? documents 
    : documents.filter(doc => doc.house_id === activeHouse);

  return (
    <PageLayout title="Documents">
      <Modal open={modalOpen} onClose={handleCloseModal}>
        {modalDoc && modalDoc.fileBase64 && (
          <div>
            <h2 className="text-lg font-semibold mb-4">{modalDoc.name}</h2>
            {modalDoc.type.toLowerCase().includes('pdf') ? (
              <iframe src={modalDoc.fileBase64} title={modalDoc.name} className="w-full h-96 border rounded" />
            ) : modalDoc.type.toLowerCase().match(/jpg|jpeg|png|gif|bmp|webp/) ? (
              <img src={modalDoc.fileBase64} alt={modalDoc.name} className="max-h-96 mx-auto" />
            ) : (
              <div className="text-gray-500">Preview not available for this file type.</div>
            )}
          </div>
        )}
      </Modal>
      <div className="mb-6 flex justify-between items-center">
        <h2 className="text-lg font-semibold">Property Documents</h2>
        <Button onClick={handleAdd}>
          <Plus className="mr-2 h-4 w-4" /> Upload Document
        </Button>
      </div>
      
      {/* House Tabs */}
      <Tabs value={activeHouse} onValueChange={setActiveHouse} className="mb-6">
        <TabsList className="mb-4 flex flex-wrap">
          <TabsTrigger value="all" className="flex items-center">
            <Home className="mr-2 h-4 w-4" /> All Properties
          </TabsTrigger>
          {properties.map((property) => (
            <TabsTrigger key={property.id} value={property.id} className="flex items-center">
              <Home className="mr-2 h-4 w-4" />
              {property.address.split(',')[0]}
            </TabsTrigger>
          ))}
        </TabsList>
      </Tabs>

      {isEditing && (
        <form onSubmit={handleFormSubmit} className="mb-6 p-4 border rounded bg-gray-50">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="name">Document Name</label>
              <Input name="name" id="name" value={form.name} onChange={handleFormChange} placeholder="Document Name" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="house_id">Property</label>
              <select
                name="house_id"
                id="house_id"
                value={form.house_id}
                onChange={handleFormChange}
                className="border rounded px-2 py-1 w-full"
                required
              >
                <option value="">Select Property</option>
                {properties.map((property) => (
                  <option key={property.id} value={property.id}>
                    {property.address} {property.city ? `(${property.city})` : ""}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="type">Type</label>
              <Input name="type" id="type" value={form.type} onChange={handleFormChange} placeholder="Type (PDF, DOCX, etc.)" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="category">Category</label>
              <select
                name="category"
                id="category"
                value={form.category}
                onChange={handleFormChange}
                className="border rounded px-2 py-1 w-full"
              >
                <option value="">Select Category</option>
                {CATEGORY_OPTIONS.map((cat) => (
                  <option key={cat} value={cat}>{cat}</option>
                ))}
              </select>
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

      {filteredDocuments.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredDocuments.map((document, idx) => (
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
                  {activeHouse === "all" && document.house_id && (
                    <div className="mt-1">
                      <span className="text-xs text-highlander-600 bg-highlander-50 px-2 py-0.5 rounded-full">
                        {properties.find(p => p.id === document.house_id)?.address.split(',')[0] || "Unknown Property"}
                      </span>
                    </div>
                  )}
                </div>
                <div className="absolute top-2 right-2 flex gap-2 opacity-0 group-hover:opacity-100 transition">
                  <Button size="icon" variant="outline" onClick={() => handleEdit(idx)}><Edit className="h-4 w-4" /></Button>
                  <Button size="icon" variant="destructive" onClick={() => handleDelete(idx)}><Trash2 className="h-4 w-4" /></Button>
                  {document.fileBase64 && (
                    <>
                      <Button size="icon" variant="outline" onClick={() => handleView(document)} title="View">
                        <Eye className="h-4 w-4" />
                      </Button>
                      <a
                        href={document.fileBase64}
                        download={document.name || 'document'}
                        target="_blank"
                        rel="noopener noreferrer"
                      >
                        <Button size="icon" variant="outline" asChild>
                          <span title="Download"><FileText className="h-4 w-4" /></span>
                        </Button>
                      </a>
                    </>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <FileText className="h-10 w-10 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-medium mb-2">
              {activeHouse === "all" ? "No documents yet" : "No documents for this property"}
            </h3>
            <p className="text-gray-500 mb-4">
              {activeHouse === "all" 
                ? "Upload property-related documents to keep everything in one place" 
                : "Upload documents for this property to keep everything organized"}
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

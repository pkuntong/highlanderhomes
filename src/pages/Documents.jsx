import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { FileText, Plus, Edit, Trash2, Eye, Home, Lock, Shield } from "lucide-react";
import { db, storage, auth } from "@/firebase";
import {
  collection,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  query,
  where,
  getDoc
} from "firebase/firestore";
import React from "react";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useAuth } from "@/contexts/AuthContext";
import { uploadSecureFile, deleteSecureFile, addSecureDocument, updateSecureDocument } from "@/utils/secureStorage";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";

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
  const { currentUser, isAuthenticated } = useAuth();
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editIndex, setEditIndex] = useState(null);
  const [form, setForm] = useState(emptyDocument);
  const [modalOpen, setModalOpen] = useState(false);
  const [modalDoc, setModalDoc] = useState(null);
  const [properties, setProperties] = useState([]);
  const [activeHouse, setActiveHouse] = useState("all");
  const [uploadProgress, setUploadProgress] = useState(null);
  const [error, setError] = useState(null);

  // Fetch documents from Firestore on mount with security checks
  useEffect(() => {
    async function fetchDocuments() {
      if (!isAuthenticated) {
        setDocuments([]);
        setLoading(false);
        return;
      }
      
      setLoading(true);
      setError(null);
      
      try {
        // Get all documents the user has access to
        const querySnapshot = await getDocs(collection(db, "documents"));
        const docsData = querySnapshot.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() }));
        setDocuments(docsData);
      } catch (err) {
        console.error("Error fetching documents:", err);
        setError("Failed to load documents. Please try again.");
        setDocuments([]);
      } finally {
        setLoading(false);
      }
    }
    
    fetchDocuments();
    // Expose fetchDocuments for later use
    Documents.fetchDocuments = fetchDocuments;
  }, [isAuthenticated]);

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
      try {
        setError(null);
        const document = documents[index];
        
        // If the document has an associated file in storage, delete that first
        if (document.filePath) {
          await deleteSecureFile(document.filePath);
        }
        
        // Then delete the document record from Firestore
        await deleteDoc(doc(db, "documents", document.id));
        await Documents.fetchDocuments();
      } catch (err) {
        console.error("Error deleting document:", err);
        setError("Failed to delete document: " + err.message);
      }
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
      // Check file size (100MB limit)
      const maxSize = 100 * 1024 * 1024; // 100MB in bytes
      if (file.size > maxSize) {
        setError(`File size too large. Maximum allowed size is 100MB. Your file is ${(file.size / 1024 / 1024).toFixed(1)}MB.`);
        e.target.value = ''; // Clear the file input
        return;
      }
      
      // Clear any previous error
      setError(null);
      
      // Set basic file information in the form
      setForm((prev) => ({ 
        ...prev, 
        fileName: file.name, 
        fileType: file.type,
        fileSize: file.size,
        fileObj: file // Store the file object for later secure upload
      }));
      
      // Add a file preview if it's an image
      if (file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onloadend = () => {
          setForm((prev) => ({ ...prev, filePreview: reader.result }));
        };
        reader.readAsDataURL(file);
      }
    }
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    try {
      setError(null);
      setUploadProgress(0);
      
      // Validate form data
      if (!form.name || !form.date || !form.house_id) {
        setError("Please fill in all required fields");
        return;
      }
      
      // Prepare base document data without file
      const docData = {
        name: form.name,
        type: form.type || form.fileType || '',
        date: form.date,
        house_id: form.house_id,
        category: form.category || '',
        fileName: form.fileName || '',
        fileType: form.fileType || ''
      };
      
      // Handle file upload if there's a file
      let fileData = {};
      if (form.fileObj) {
        try {
          setUploadProgress(10);
          // Upload file to secure storage
          const fileInfo = await uploadSecureFile(
            form.fileObj, 
            'documents', 
            { house_id: form.house_id, category: form.category }
          );
          setUploadProgress(70);
          
          // Add file details to document data
          fileData = {
            fileUrl: fileInfo.url,
            filePath: fileInfo.path,
            fileName: fileInfo.name,
            fileType: fileInfo.type,
            fileSize: fileInfo.size
          };
        } catch (fileError) {
          console.error("Error uploading file:", fileError);
          setError("Failed to upload file: " + fileError.message);
          return;
        }
      }
      
      setUploadProgress(80);
      
      // Combine document data with file data
      const completeDocData = { ...docData, ...fileData };
      
      if (editIndex !== null) {
        // If updating an existing document
        const documentId = documents[editIndex].id;
        const currentDoc = documents[editIndex];
        
        // If changing files, delete the old file first
        if (form.fileObj && currentDoc.filePath) {
          await deleteSecureFile(currentDoc.filePath);
        }
        
        // Update document
        await updateSecureDocument(documentId, completeDocData);
      } else {
        // Add new document with security metadata
        await addSecureDocument(completeDocData);
      }
      
      setUploadProgress(100);
      await Documents.fetchDocuments();
      setIsEditing(false);
      setForm(emptyDocument);
      setEditIndex(null);
      setUploadProgress(null);
    } catch (error) {
      console.error("Error saving document:", error);
      setError(`Failed to save document: ${error.message}`);
      setUploadProgress(null);
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
        {modalDoc && (
          <div>
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold">{modalDoc.name}</h2>
              {modalDoc.createdBy && modalDoc.createdAt && (
                <div className="text-xs text-gray-500 flex items-center">
                  <Shield className="h-3 w-3 mr-1" />
                  <span>
                    Added {new Date(modalDoc.createdAt).toLocaleDateString()}
                  </span>
                </div>
              )}
            </div>
            
            {modalDoc.fileUrl ? (
              <>
                {modalDoc.fileType?.toLowerCase().includes('pdf') ? (
                  <iframe src={modalDoc.fileUrl} title={modalDoc.name} className="w-full h-96 border rounded" />
                ) : modalDoc.fileType?.toLowerCase().match(/jpg|jpeg|png|gif|bmp|webp/) ? (
                  <img src={modalDoc.fileUrl} alt={modalDoc.name} className="max-h-96 mx-auto" />
                ) : (
                  <div className="flex flex-col items-center justify-center p-8 border rounded bg-gray-50">
                    <FileText className="h-12 w-12 text-gray-400 mb-4" />
                    <p className="text-center text-gray-600 mb-2">Preview not available for this file type</p>
                    <a
                      href={modalDoc.fileUrl}
                      download={modalDoc.fileName || modalDoc.name}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="mt-2 inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-highlander-600 hover:bg-highlander-700"
                    >
                      Download File
                    </a>
                  </div>
                )}
              </>
            ) : modalDoc.fileBase64 ? (
              <>
                {modalDoc.fileType?.toLowerCase().includes('pdf') ? (
                  <iframe src={modalDoc.fileBase64} title={modalDoc.name} className="w-full h-96 border rounded" />
                ) : modalDoc.fileType?.toLowerCase().match(/jpg|jpeg|png|gif|bmp|webp/) ? (
                  <img src={modalDoc.fileBase64} alt={modalDoc.name} className="max-h-96 mx-auto" />
                ) : (
                  <div className="text-gray-500">Preview not available for this file type.</div>
                )}
              </>
            ) : (
              <div className="text-gray-500">No file attached to this document.</div>
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
      
      {error && (
        <Alert variant="destructive" className="mb-4">
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}
      
      {uploadProgress !== null && (
        <div className="w-full mb-4">
          <div className="w-full bg-gray-200 rounded-full h-2.5">
            <div 
              className="bg-highlander-600 h-2.5 rounded-full" 
              style={{ width: `${uploadProgress}%` }}
            ></div>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            {uploadProgress < 100 ? `Uploading document... ${uploadProgress}%` : 'Upload complete!'}
          </p>
        </div>
      )}
      
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
              <label className="block text-sm font-medium mb-1" htmlFor="fileUpload">Upload File (Max 100MB)</label>
              <Input 
                name="fileUpload" 
                id="fileUpload" 
                type="file" 
                accept="application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-powerpoint,application/vnd.openxmlformats-officedocument.presentationml.presentation,text/*,image/*,video/*,audio/*" 
                onChange={handleFileUpload} 
              />
              {form.fileObj && (
                <div className="block text-xs text-green-600 mt-2">
                  File selected: {form.fileName} ({(form.fileSize / 1024).toFixed(0)} KB)
                </div>
              )}
              <div className="text-xs text-gray-500 mt-1">
                Supported: PDF, Word, Excel, PowerPoint, Images, Videos, Audio, Text files
              </div>
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
                <div className="p-3 bg-highlander-100 rounded-lg mr-3 relative">
                  <FileText className="h-6 w-6 text-highlander-700" />
                  {document.filePath && (
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <div className="absolute -top-1 -right-1 bg-green-100 rounded-full p-0.5">
                            <Lock className="h-3 w-3 text-green-600" />
                          </div>
                        </TooltipTrigger>
                        <TooltipContent>
                          <p className="text-xs">Securely stored file</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  )}
                </div>
                <div className="flex-1">
                  <h3 className="font-medium text-sm">{document.name}</h3>
                  <div className="flex justify-between mt-1">
                    <span className="text-xs text-gray-500">
                      {document.fileType || document.type}
                      {document.fileSize && ` (${(document.fileSize / 1024).toFixed(0)} KB)`}
                    </span>
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
                  {document.createdAt && (
                    <div className="mt-1 flex items-center">
                      <Shield className="h-3 w-3 mr-1 text-gray-400" />
                      <span className="text-xs text-gray-400">
                        Added {new Date(document.createdAt).toLocaleDateString()}
                      </span>
                    </div>
                  )}
                </div>
                <div className="absolute top-2 right-2 flex gap-2 opacity-0 group-hover:opacity-100 transition">
                  <Button size="icon" variant="outline" onClick={() => handleEdit(idx)}><Edit className="h-4 w-4" /></Button>
                  <Button size="icon" variant="destructive" onClick={() => handleDelete(idx)}><Trash2 className="h-4 w-4" /></Button>
                  
                  {(document.fileUrl || document.fileBase64) && (
                    <>
                      <Button size="icon" variant="outline" onClick={() => handleView(document)} title="View">
                        <Eye className="h-4 w-4" />
                      </Button>
                      
                      {document.fileUrl ? (
                        <a
                          href={document.fileUrl}
                          download={document.fileName || document.name || 'document'}
                          target="_blank"
                          rel="noopener noreferrer"
                        >
                          <Button size="icon" variant="outline" asChild>
                            <span title="Download"><FileText className="h-4 w-4" /></span>
                          </Button>
                        </a>
                      ) : document.fileBase64 && (
                        <a
                          href={document.fileBase64}
                          download={document.fileName || document.name || 'document'}
                          target="_blank"
                          rel="noopener noreferrer"
                        >
                          <Button size="icon" variant="outline" asChild>
                            <span title="Download"><FileText className="h-4 w-4" /></span>
                          </Button>
                        </a>
                      )}
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

import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Plus, User, Edit, Trash2 } from "lucide-react";
import { db } from "@/firebase";
import {
  collection,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  getDoc,
  setDoc
} from "firebase/firestore";

const emptyTenant = {
  name: '',
  email: '',
  phone: '',
  leaseStartDate: '',
  leaseEndDate: '',
  notes: '',
};

const Tenants = () => {
  const [tenants, setTenants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editIndex, setEditIndex] = useState(null);
  const [form, setForm] = useState(emptyTenant);
  const [deleteErrorIndex, setDeleteErrorIndex] = useState(null);

  // Function to remove duplicate tenants based on email address
  const cleanupDuplicateTenants = async () => {
    console.log('Running duplicate tenant cleanup...');
    try {
      // Get all tenants from Firestore
      const querySnapshot = await getDocs(collection(db, "tenants"));
      
      // Group tenants by email to find duplicates
      const emailMap = {};
      const duplicates = [];
      
      querySnapshot.forEach(docSnap => {
        const data = docSnap.data();
        const id = docSnap.id;
        const email = data.email;
        
        if (email) {
          // If we've seen this email before, we have a duplicate
          if (emailMap[email]) {
            // Keep the one with the more recent lastUpdated timestamp or createdAt
            const existing = emailMap[email];
            const existingTimestamp = existing.data.lastUpdated || existing.data.createdAt || '1900-01-01';
            const currentTimestamp = data.lastUpdated || data.createdAt || '1900-01-01';
            
            if (currentTimestamp > existingTimestamp) {
              // This one is newer, so the existing one is the duplicate
              duplicates.push(existing.id);
              emailMap[email] = { id, data };
            } else {
              // Existing one is newer, so this is the duplicate
              duplicates.push(id);
            }
          } else {
            // First time seeing this email
            emailMap[email] = { id, data };
          }
        }
      });
      
      // Delete duplicates
      if (duplicates.length > 0) {
        console.log(`Found ${duplicates.length} duplicate tenants to clean up:`);
        console.log(duplicates);
        
        for (const dupId of duplicates) {
          console.log(`Deleting duplicate tenant ${dupId}`);
          await deleteDoc(doc(db, "tenants", dupId));
        }
        
        return true; // Return true if we cleaned up something
      } else {
        console.log('No duplicate tenants found.');
        return false;
      }
    } catch (error) {
      console.error('Error cleaning up duplicate tenants:', error);
      return false;
    }
  };

  // Fetch tenants from Firestore on mount
  useEffect(() => {
    async function fetchTenants() {
      setLoading(true);
      console.log('Fetching latest tenants data from Firestore...');
      
      try {
        // Force a fresh query from Firestore
        const querySnapshot = await getDocs(collection(db, "tenants"));
        
        // Process the results
        const tenantsData = querySnapshot.docs.map(docSnap => {
          const data = docSnap.data();
          return { id: docSnap.id, ...data };
        });
        
        console.log('Fetched', tenantsData.length, 'tenants:', tenantsData);
        
        // Update state with fresh data
        setTenants(tenantsData);
        console.log('Tenants state updated');
      } catch (error) {
        console.error('Error fetching tenants:', error);
      } finally {
        setLoading(false);
      }
    }
    
    fetchTenants();
    // Expose fetchTenants for later use
    Tenants.fetchTenants = fetchTenants;
  }, []);

  const handleEdit = (index) => {
    const tenant = tenants[index];
    
    if (!tenant || !tenant.id) {
      alert('Error: Cannot edit this tenant - missing ID');
      return;
    }
    
    console.log('EDITING TENANT:', tenant);
    console.log('WITH ID:', tenant.id);
    
    // Store BOTH the tenant ID and the index
    setEditIndex({
      index: index,
      tenantId: tenant.id  // Store the actual ID explicitly
    });
    
    // Make a clean copy and ensure ID is included
    setForm({
      ...tenant,
      id: tenant.id  // Make absolutely sure ID is included
    });
    
    setIsEditing(true);
  };

  const handleDelete = async (index) => {
    const tenant = tenants[index];
    if (window.confirm("Are you sure you want to delete this tenant?")) {
      try {
        if (tenant.id) {
          await deleteDoc(doc(db, "tenants", tenant.id));
        }
        setTenants(prev => prev.filter((_, i) => i !== index));
        setDeleteErrorIndex(null);
        await Tenants.fetchTenants();
      } catch (error) {
        console.error("Error deleting tenant:", error);
        alert(`Failed to delete tenant: ${error.message}. You can now force remove this tenant from the list.`);
        setDeleteErrorIndex(index);
      }
    }
  };

  const handleAdd = () => {
    setEditIndex(null);
    setForm(emptyTenant);
    setIsEditing(true);
  };

  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    
    // Create a timestamp to track this specific update
    const updateTimestamp = new Date().toISOString();
    
    if (editIndex !== null) {
      // Since we changed editIndex to store both index and ID, we need to extract the tenantId
      const tenantId = editIndex.tenantId || form.id;
      
      console.log('=========== TENANT UPDATE ==========');
      console.log('Tenant ID from editIndex:', editIndex.tenantId);
      console.log('Tenant ID from form:', form.id);
      console.log('Using Tenant ID:', tenantId);
      console.log('Form data:', form);
      
      // VERIFY we have a valid ID before proceeding
      if (!tenantId) {
        console.error('CRITICAL ERROR: Missing tenant ID for update!');
        alert('Cannot update tenant: Missing ID. Please try refreshing the page and try again.');
        return;
      }

      // Create reference to the EXACT document
      const tenantRef = doc(db, "tenants", tenantId);
      
      // Add a timestamp to the form data for tracking this update
      const updatedForm = {
        ...form,
        lastUpdated: updateTimestamp,
      };
      
      try {
        // Ensure all required fields are present
        const requiredFields = ["name", "email", "phone", "leaseStartDate", "leaseEndDate"];
        const missingFields = requiredFields.filter(field => !updatedForm[field]);
        if (missingFields.length > 0) {
          throw new Error(`Missing required fields: ${missingFields.join(", ")}`);
        }
        
        // First, attempt to get the current document
        const docSnapshot = await getDoc(tenantRef);
        const exists = docSnapshot.exists();
        console.log(`[${updateTimestamp}] Document exists check:`, exists);
        
        // Direct approach that prevents any possibility of duplication
        if (exists) {
          console.log(`[${updateTimestamp}] Tenant document exists, updating directly with ID: ${tenantId}`);
          // Use direct update - this is most reliable
          await updateDoc(tenantRef, updatedForm);
        } else {
          console.log(`[${updateTimestamp}] Tenant document doesn't exist, creating with ID: ${tenantId}`);
          // Create the document with EXPLICIT ID
          await setDoc(tenantRef, {
            ...updatedForm,
            id: tenantId,  // Ensure ID is consistent
            createdAt: updateTimestamp
          });
        }
        console.log(`[${updateTimestamp}] Tenant document operation completed successfully`);
        
        // Verify the update was successful
        const verifySnapshot = await getDoc(tenantRef);
        if (verifySnapshot.exists()) {
          console.log(`[${updateTimestamp}] Verification - Tenant saved with data:`, verifySnapshot.data());
        } else {
          console.error(`[${updateTimestamp}] Error: Tenant still not found after save attempt!`);
        }
        
        // Run the duplicate cleanup to fix any duplicate tenants
        console.log(`[${updateTimestamp}] Running duplicate cleanup...`);
        const cleanupResult = await cleanupDuplicateTenants();
        if (cleanupResult) {
          console.log(`[${updateTimestamp}] Cleanup removed duplicate tenants`);
        }
        
        // Refresh the tenants list from Firestore
        console.log(`[${updateTimestamp}] Refreshing tenants list from Firestore...`);
        await Tenants.fetchTenants();
        
        // Show success message
        alert(`Tenant updated successfully!`);
        
        // Reset the form state
        setIsEditing(false);
        setForm(emptyTenant);
        setEditIndex(null);
      } catch (error) {
        console.error(`[${updateTimestamp}] Error updating tenant:`, error);
        alert(`Failed to update tenant: ${error.message}. Please try again.`);
      }
    } else {
      // Add
      try {
        const docRef = await addDoc(collection(db, "tenants"), form);
        console.log("Added new tenant with ID:", docRef.id);
        await Tenants.fetchTenants();
        setIsEditing(false);
        setForm(emptyTenant);
        setEditIndex(null);
      } catch (error) {
        console.error("Error adding tenant:", error);
        alert(`Failed to add tenant: ${error.message}. Please try again.`);
      }
    }
  };

  const handleCancel = () => {
    setIsEditing(false);
    setForm(emptyTenant);
    setEditIndex(null);
  };

  if (loading) return <div>Loading tenants...</div>;

  return (
    <PageLayout title="Tenants">
      <div className="mb-6 flex justify-between items-center">
        <h2 className="text-lg font-semibold">Tenant Management</h2>
        <div className="flex gap-2">
          <Button onClick={handleAdd}>
            <Plus className="mr-2 h-4 w-4" /> Add Tenant
          </Button>
          <Button variant="outline" onClick={async () => {
            await cleanupDuplicateTenants();
            await Tenants.fetchTenants();
            alert('Tenants refreshed and duplicates removed');
          }}>
            Refresh & Clean Tenants
          </Button>
          <Button variant="destructive" onClick={() => { if(window.confirm('Are you sure you want to clear all tenants?')) setTenants([]); }}>
            Clear All Tenants
          </Button>
        </div>
      </div>

      {isEditing && (
        <form onSubmit={handleFormSubmit} className="mb-6 p-4 border rounded bg-gray-50">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="name">Name</label>
              <Input name="name" id="name" value={form.name} onChange={handleFormChange} placeholder="Tenant Name" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="email">Email</label>
              <Input name="email" id="email" value={form.email} onChange={handleFormChange} placeholder="Email" type="email" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="phone">Phone</label>
              <Input name="phone" id="phone" value={form.phone} onChange={handleFormChange} placeholder="Phone" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="leaseStartDate">Lease Start Date</label>
              <Input name="leaseStartDate" id="leaseStartDate" value={form.leaseStartDate} onChange={handleFormChange} placeholder="YYYY-MM-DD" type="date" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="leaseEndDate">Lease End Date</label>
              <Input name="leaseEndDate" id="leaseEndDate" value={form.leaseEndDate} onChange={handleFormChange} placeholder="YYYY-MM-DD" type="date" required />
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium mb-1" htmlFor="notes">Notes</label>
              <Input name="notes" id="notes" value={form.notes} onChange={handleFormChange} placeholder="Notes" />
            </div>
          </div>
          <div className="flex gap-2 mt-4 justify-end">
            <Button variant="outline" type="button" onClick={handleCancel}>Cancel</Button>
            <Button type="submit">{editIndex !== null ? "Update" : "Add"} Tenant</Button>
          </div>
        </form>
      )}

      {tenants.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {tenants.map((tenant, idx) => (
            <Card key={tenant.id} className="relative group hover:bg-gray-50">
              <CardContent className="p-4 flex items-center">
                <div className="p-3 bg-highlander-100 rounded-lg mr-3">
                  <User className="h-6 w-6 text-highlander-700" />
                </div>
                <div className="flex-1">
                  <h3 className="font-medium">{tenant.name}</h3>
                  <div className="flex flex-col mt-2 text-xs text-gray-500">
                    <span>Lease: {tenant.leaseStartDate} to {tenant.leaseEndDate}</span>
                  </div>
                  {tenant.notes && <div className="mt-1 text-xs text-gray-400">{tenant.notes}</div>}
                </div>
                <div className="absolute top-2 right-2 flex gap-2 opacity-0 group-hover:opacity-100 transition">
                  <Button size="icon" variant="outline" onClick={() => handleEdit(idx)}><Edit className="h-4 w-4" /></Button>
                  <Button size="icon" variant="destructive" onClick={() => handleDelete(idx)}><Trash2 className="h-4 w-4" /></Button>
                  {deleteErrorIndex === idx && (
                    <Button size="icon" variant="destructive" onClick={() => setTenants(prev => prev.filter((_, i) => i !== idx))}>
                      Remove from List
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <User className="h-10 w-10 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-medium mb-2">No tenants added yet</h3>
            <p className="text-gray-500 mb-4">
              Add tenants to track lease information and payments
            </p>
            <Button onClick={handleAdd}>
              <Plus className="mr-2 h-4 w-4" /> Add Tenant
            </Button>
          </CardContent>
        </Card>
      )}
    </PageLayout>
  );
};

export default Tenants;

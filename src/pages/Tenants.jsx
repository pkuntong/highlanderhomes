import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Plus, User } from "lucide-react";
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
import TenantCard from "@/components/tenants/TenantCard";
import TenantForm from "@/components/tenants/TenantForm";

const emptyTenant = {
  name: '',
  email: '',
  phone: '',
  propertyId: '',
  leaseStartDate: '',
  leaseEndDate: '',
  monthlyRent: '',
  securityDeposit: '',
  notes: '',
};

const Tenants = () => {
  const [tenants, setTenants] = useState([]);
  const [properties, setProperties] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editIndex, setEditIndex] = useState(null);
  const [form, setForm] = useState(emptyTenant);
  const [deleteErrorIndex, setDeleteErrorIndex] = useState(null);

  // Function to remove duplicate tenants based on email address
  const cleanupDuplicateTenants = async () => {
    console.log('Running duplicate tenant cleanup...');
    try {
      const querySnapshot = await getDocs(collection(db, "tenants"));

      const emailMap = {};
      const duplicates = [];

      querySnapshot.forEach(docSnap => {
        const data = docSnap.data();
        const id = docSnap.id;
        const email = data.email;

        if (email) {
          if (emailMap[email]) {
            const existing = emailMap[email];
            const existingTimestamp = existing.data.lastUpdated || existing.data.createdAt || '1900-01-01';
            const currentTimestamp = data.lastUpdated || data.createdAt || '1900-01-01';

            if (currentTimestamp > existingTimestamp) {
              duplicates.push(existing.id);
              emailMap[email] = { id, data };
            } else {
              duplicates.push(id);
            }
          } else {
            emailMap[email] = { id, data };
          }
        }
      });

      if (duplicates.length > 0) {
        console.log(`Found ${duplicates.length} duplicate tenants to clean up:`, duplicates);

        for (const dupId of duplicates) {
          console.log(`Deleting duplicate tenant ${dupId}`);
          await deleteDoc(doc(db, "tenants", dupId));
        }

        return true;
      } else {
        console.log('No duplicate tenants found.');
        return false;
      }
    } catch (error) {
      console.error('Error cleaning up duplicate tenants:', error);
      return false;
    }
  };

  // Fetch tenants and properties from Firestore on mount
  useEffect(() => {
    async function fetchTenants() {
      setLoading(true);
      console.log('Fetching latest tenants data from Firestore...');

      try {
        // Fetch tenants
        const tenantsSnapshot = await getDocs(collection(db, "tenants"));
        const tenantsData = tenantsSnapshot.docs.map(docSnap => {
          const data = docSnap.data();
          return { id: docSnap.id, ...data };
        });

        console.log('Fetched', tenantsData.length, 'tenants:', tenantsData);
        setTenants(tenantsData);

        // Fetch properties for assignment dropdown
        const propertiesSnapshot = await getDocs(collection(db, "properties"));
        const propertiesData = propertiesSnapshot.docs.map(docSnap => ({
          id: docSnap.id,
          ...docSnap.data()
        }));

        console.log('Fetched', propertiesData.length, 'properties');
        setProperties(propertiesData);

        console.log('Tenants and properties state updated');
      } catch (error) {
        console.error('Error fetching data:', error);
      } finally {
        setLoading(false);
      }
    }

    fetchTenants();
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

    setEditIndex({
      index: index,
      tenantId: tenant.id
    });

    setForm({
      ...tenant,
      id: tenant.id
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

    const updateTimestamp = new Date().toISOString();

    if (editIndex !== null) {
      const tenantId = editIndex.tenantId || form.id;

      console.log('=========== TENANT UPDATE ==========');
      console.log('Tenant ID from editIndex:', editIndex.tenantId);
      console.log('Tenant ID from form:', form.id);
      console.log('Using Tenant ID:', tenantId);
      console.log('Form data:', form);

      if (!tenantId) {
        console.error('CRITICAL ERROR: Missing tenant ID for update!');
        alert('Cannot update tenant: Missing ID. Please try refreshing the page and try again.');
        return;
      }

      const tenantRef = doc(db, "tenants", tenantId);

      const updatedForm = {
        ...form,
        lastUpdated: updateTimestamp,
      };

      try {
        const requiredFields = ["name", "email", "phone", "leaseStartDate", "leaseEndDate"];
        const missingFields = requiredFields.filter(field => !updatedForm[field]);
        if (missingFields.length > 0) {
          throw new Error(`Missing required fields: ${missingFields.join(", ")}`);
        }

        const docSnapshot = await getDoc(tenantRef);
        const exists = docSnapshot.exists();
        console.log(`[${updateTimestamp}] Document exists check:`, exists);

        if (exists) {
          console.log(`[${updateTimestamp}] Tenant document exists, updating directly with ID: ${tenantId}`);
          await updateDoc(tenantRef, updatedForm);
        } else {
          console.log(`[${updateTimestamp}] Tenant document doesn't exist, creating with ID: ${tenantId}`);
          await setDoc(tenantRef, {
            ...updatedForm,
            id: tenantId,
            createdAt: updateTimestamp
          });
        }
        console.log(`[${updateTimestamp}] Tenant document operation completed successfully`);

        const verifySnapshot = await getDoc(tenantRef);
        if (verifySnapshot.exists()) {
          console.log(`[${updateTimestamp}] Verification - Tenant saved with data:`, verifySnapshot.data());
        } else {
          console.error(`[${updateTimestamp}] Error: Tenant still not found after save attempt!`);
        }

        console.log(`[${updateTimestamp}] Running duplicate cleanup...`);
        const cleanupResult = await cleanupDuplicateTenants();
        if (cleanupResult) {
          console.log(`[${updateTimestamp}] Cleanup removed duplicate tenants`);
        }

        console.log(`[${updateTimestamp}] Refreshing tenants list from Firestore...`);
        await Tenants.fetchTenants();

        alert(`Tenant updated successfully!`);

        setIsEditing(false);
        setForm(emptyTenant);
        setEditIndex(null);
      } catch (error) {
        console.error(`[${updateTimestamp}] Error updating tenant:`, error);
        alert(`Failed to update tenant: ${error.message}. Please try again.`);
      }
    } else {
      // Add new tenant
      try {
        const docRef = await addDoc(collection(db, "tenants"), {
          ...form,
          createdAt: updateTimestamp
        });
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
            Refresh & Clean
          </Button>
        </div>
      </div>

      {isEditing && (
        <TenantForm
          form={form}
          onFormChange={handleFormChange}
          onSubmit={handleFormSubmit}
          onCancel={handleCancel}
          isEditing={editIndex !== null}
          properties={properties}
        />
      )}

      {tenants.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {tenants.map((tenant, idx) => {
            const assignedProperty = tenant.propertyId
              ? properties.find(p => p.id === tenant.propertyId)
              : null;

            return (
              <TenantCard
                key={tenant.id}
                tenant={tenant}
                property={assignedProperty}
                onEdit={handleEdit}
                onDelete={handleDelete}
                index={idx}
              />
            );
          })}
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

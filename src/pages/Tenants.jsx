import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Plus, User, Edit, Trash2 } from "lucide-react";
import { tenants as mockTenants } from "@/data/mockData";

const LOCAL_STORAGE_KEY = "highlanderhomes_tenants";

const emptyTenant = {
  id: '',
  name: '',
  email: '',
  phone: '',
  leaseStartDate: '',
  leaseEndDate: '',
  notes: '',
};

const Tenants = () => {
  const [tenants, setTenants] = useState(() => {
    const stored = localStorage.getItem(LOCAL_STORAGE_KEY);
    return stored ? JSON.parse(stored) : mockTenants;
  });
  const [isEditing, setIsEditing] = useState(false);
  const [editIndex, setEditIndex] = useState(null);
  const [form, setForm] = useState(emptyTenant);

  // Save to localStorage on change
  useEffect(() => {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(tenants));
  }, [tenants]);

  const handleEdit = (index) => {
    setEditIndex(index);
    setForm(tenants[index]);
    setIsEditing(true);
  };

  const handleDelete = (index) => {
    if (window.confirm("Are you sure you want to delete this tenant?")) {
      setTenants((prev) => prev.filter((_, i) => i !== index));
    }
  };

  const handleAdd = () => {
    setEditIndex(null);
    setForm({ ...emptyTenant, id: Date.now().toString() });
    setIsEditing(true);
  };

  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleFormSubmit = (e) => {
    e.preventDefault();
    if (editIndex !== null) {
      // Update
      setTenants((prev) => prev.map((t, i) => (i === editIndex ? form : t)));
    } else {
      // Add
      setTenants((prev) => [...prev, form]);
    }
    setIsEditing(false);
    setForm(emptyTenant);
    setEditIndex(null);
  };

  const handleCancel = () => {
    setIsEditing(false);
    setForm(emptyTenant);
    setEditIndex(null);
  };

  return (
    <PageLayout title="Tenants">
      <div className="mb-6 flex justify-between items-center">
        <h2 className="text-lg font-semibold">Tenant Management</h2>
        <Button onClick={handleAdd}>
          <Plus className="mr-2 h-4 w-4" /> Add Tenant
        </Button>
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

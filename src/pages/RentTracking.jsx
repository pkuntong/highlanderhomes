import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { DollarSign, Calendar, CheckCircle, AlertCircle, Clock, Edit, Trash2 } from "lucide-react";
import { db } from "@/firebase";
import {
  collection,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  query,
  orderBy,
  where
} from "firebase/firestore";

const RentTracking = () => {
  const [tenants, setTenants] = useState([]);
  const [rentRecords, setRentRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isAddingPayment, setIsAddingPayment] = useState(false);
  const [isEditingPayment, setIsEditingPayment] = useState(false);
  const [editingRecordId, setEditingRecordId] = useState(null);
  const [selectedTenant, setSelectedTenant] = useState("");
  const [paymentForm, setPaymentForm] = useState({
    tenantId: "",
    tenantName: "",
    amount: "",
    dueDate: "",
    paidDate: "",
    status: "pending", // pending, paid, partial, late
    notes: ""
  });

  // Fetch tenants and rent records
  useEffect(() => {
    async function fetchData() {
      setLoading(true);
      try {
        // Fetch tenants
        const tenantsSnapshot = await getDocs(collection(db, "tenants"));
        const tenantsData = tenantsSnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
        setTenants(tenantsData);

        // Fetch rent records
        const rentQuery = query(
          collection(db, "rentRecords"),
          orderBy("dueDate", "desc")
        );
        const rentSnapshot = await getDocs(rentQuery);
        const rentData = rentSnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
        setRentRecords(rentData);
      } catch (error) {
        console.error("Error fetching data:", error);
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, []);

  const handleAddPayment = () => {
    setIsAddingPayment(true);
    setPaymentForm({
      tenantId: "",
      tenantName: "",
      amount: "",
      dueDate: "",
      paidDate: "",
      status: "pending",
      notes: ""
    });
  };

  const handleTenantSelect = (tenantId) => {
    const tenant = tenants.find(t => t.id === tenantId);
    setPaymentForm(prev => ({
      ...prev,
      tenantId: tenantId,
      tenantName: tenant ? tenant.name : ""
    }));
    setSelectedTenant(tenantId);
  };

  const handleFormChange = (field, value) => {
    setPaymentForm(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (isEditingPayment && editingRecordId) {
        // Update existing record
        const updateData = {
          ...paymentForm,
          updatedAt: new Date().toISOString()
        };
        await updateDoc(doc(db, "rentRecords", editingRecordId), updateData);
      } else {
        // Add new record
        const recordData = {
          ...paymentForm,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        };
        await addDoc(collection(db, "rentRecords"), recordData);
      }
      
      // Refresh rent records
      const rentQuery = query(
        collection(db, "rentRecords"),
        orderBy("dueDate", "desc")
      );
      const rentSnapshot = await getDocs(rentQuery);
      const rentData = rentSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setRentRecords(rentData);

      setIsAddingPayment(false);
      setIsEditingPayment(false);
      setEditingRecordId(null);
      setSelectedTenant("");
    } catch (error) {
      console.error("Error saving rent record:", error);
      alert("Failed to save rent record. Please try again.");
    }
  };

  const handleEditRecord = (record) => {
    setPaymentForm({
      tenantId: record.tenantId,
      tenantName: record.tenantName,
      amount: record.amount,
      dueDate: record.dueDate,
      paidDate: record.paidDate || "",
      status: record.status,
      notes: record.notes || ""
    });
    setSelectedTenant(record.tenantId);
    setEditingRecordId(record.id);
    setIsEditingPayment(true);
    setIsAddingPayment(true); // Reuse the same form
  };

  const handleDeleteRecord = async (recordId) => {
    if (window.confirm("Are you sure you want to delete this payment record?")) {
      try {
        await deleteDoc(doc(db, "rentRecords", recordId));
        
        // Remove from local state
        setRentRecords(prev => prev.filter(record => record.id !== recordId));
      } catch (error) {
        console.error("Error deleting rent record:", error);
        alert("Failed to delete rent record. Please try again.");
      }
    }
  };

  const handleCancelEdit = () => {
    setIsAddingPayment(false);
    setIsEditingPayment(false);
    setEditingRecordId(null);
    setSelectedTenant("");
    setPaymentForm({
      tenantId: "",
      tenantName: "",
      amount: "",
      dueDate: "",
      paidDate: "",
      status: "pending",
      notes: ""
    });
  };

  const updatePaymentStatus = async (recordId, newStatus, paidAmount = null) => {
    try {
      const updateData = {
        status: newStatus,
        updatedAt: new Date().toISOString()
      };

      if (newStatus === "paid" && !rentRecords.find(r => r.id === recordId).paidDate) {
        updateData.paidDate = new Date().toISOString().split('T')[0];
      }

      if (paidAmount !== null) {
        updateData.paidAmount = paidAmount;
      }

      await updateDoc(doc(db, "rentRecords", recordId), updateData);
      
      // Update local state
      setRentRecords(prev => prev.map(record => 
        record.id === recordId 
          ? { ...record, ...updateData }
          : record
      ));
    } catch (error) {
      console.error("Error updating payment status:", error);
      alert("Failed to update payment status. Please try again.");
    }
  };

  const getStatusBadge = (status) => {
    const statusConfig = {
      pending: { color: "bg-yellow-100 text-yellow-800", icon: Clock, text: "Pending" },
      paid: { color: "bg-green-100 text-green-800", icon: CheckCircle, text: "Paid" },
      partial: { color: "bg-blue-100 text-blue-800", icon: DollarSign, text: "Partial" },
      late: { color: "bg-red-100 text-red-800", icon: AlertCircle, text: "Late" }
    };

    const config = statusConfig[status] || statusConfig.pending;
    const Icon = config.icon;

    return (
      <Badge className={config.color}>
        <Icon className="w-3 h-3 mr-1" />
        {config.text}
      </Badge>
    );
  };

  const getCurrentMonthRecords = () => {
    const currentMonth = new Date().toISOString().slice(0, 7); // YYYY-MM
    return rentRecords.filter(record => 
      record.dueDate && record.dueDate.startsWith(currentMonth)
    );
  };

  const getTotalCollected = () => {
    return rentRecords
      .filter(record => record.status === "paid")
      .reduce((sum, record) => sum + (parseFloat(record.amount) || 0), 0);
  };

  const getTotalPending = () => {
    return rentRecords
      .filter(record => record.status === "pending" || record.status === "late")
      .reduce((sum, record) => sum + (parseFloat(record.amount) || 0), 0);
  };

  if (loading) return <div>Loading rent tracking...</div>;

  return (
    <PageLayout title="Rent Tracking">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">This Month</CardTitle>
            <Calendar className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{getCurrentMonthRecords().length}</div>
            <p className="text-xs text-muted-foreground">rent records</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Collected</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${getTotalCollected().toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">all time</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending</CardTitle>
            <AlertCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${getTotalPending().toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">outstanding</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Collection Rate</CardTitle>
            <CheckCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {rentRecords.length > 0 
                ? Math.round((rentRecords.filter(r => r.status === "paid").length / rentRecords.length) * 100)
                : 0}%
            </div>
            <p className="text-xs text-muted-foreground">success rate</p>
          </CardContent>
        </Card>
      </div>

      {/* Add Payment Button */}
      <div className="mb-6 flex justify-between items-center">
        <h2 className="text-lg font-semibold">Rent Payments</h2>
        <Button onClick={handleAddPayment}>
          <DollarSign className="mr-2 h-4 w-4" /> Add Payment Record
        </Button>
      </div>

      {/* Add Payment Form */}
      {isAddingPayment && (
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>{isEditingPayment ? "Edit Rent Payment Record" : "Add Rent Payment Record"}</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1">Tenant</label>
                <Select value={selectedTenant} onValueChange={handleTenantSelect}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select tenant" />
                  </SelectTrigger>
                  <SelectContent>
                    {tenants.map(tenant => (
                      <SelectItem key={tenant.id} value={tenant.id}>
                        {tenant.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">Amount</label>
                <Input
                  type="number"
                  step="0.01"
                  value={paymentForm.amount}
                  onChange={(e) => handleFormChange("amount", e.target.value)}
                  placeholder="Rent amount"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">Due Date</label>
                <Input
                  type="date"
                  value={paymentForm.dueDate}
                  onChange={(e) => handleFormChange("dueDate", e.target.value)}
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-1">Payment Status</label>
                <Select value={paymentForm.status} onValueChange={(value) => handleFormChange("status", value)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="pending">Pending</SelectItem>
                    <SelectItem value="paid">Paid</SelectItem>
                    <SelectItem value="partial">Partial Payment</SelectItem>
                    <SelectItem value="late">Late</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {paymentForm.status === "paid" && (
                <div>
                  <label className="block text-sm font-medium mb-1">Paid Date</label>
                  <Input
                    type="date"
                    value={paymentForm.paidDate}
                    onChange={(e) => handleFormChange("paidDate", e.target.value)}
                  />
                </div>
              )}

              <div className="md:col-span-2">
                <label className="block text-sm font-medium mb-1">Notes</label>
                <Input
                  value={paymentForm.notes}
                  onChange={(e) => handleFormChange("notes", e.target.value)}
                  placeholder="Additional notes..."
                />
              </div>

              <div className="md:col-span-2 flex gap-2 justify-end">
                <Button type="button" variant="outline" onClick={handleCancelEdit}>
                  Cancel
                </Button>
                <Button type="submit">{isEditingPayment ? "Update Record" : "Add Record"}</Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {/* Rent Records Table */}
      <Card>
        <CardHeader>
          <CardTitle>Payment Records</CardTitle>
        </CardHeader>
        <CardContent>
          {rentRecords.length > 0 ? (
            <div className="space-y-3">
              {rentRecords.map((record) => (
                <div key={record.id} className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50">
                  <div className="flex items-center space-x-4">
                    <div>
                      <h4 className="font-medium">{record.tenantName}</h4>
                      <p className="text-sm text-gray-500">
                        Due: {record.dueDate} {record.paidDate && `• Paid: ${record.paidDate}`}
                      </p>
                      {record.notes && <p className="text-xs text-gray-400 mt-1">{record.notes}</p>}
                    </div>
                  </div>
                  
                  <div className="flex items-center space-x-4">
                    <div className="text-right">
                      <div className="font-medium">${parseFloat(record.amount || 0).toFixed(2)}</div>
                      {getStatusBadge(record.status)}
                    </div>
                    
                    <div className="flex gap-1">
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => handleEditRecord(record)}
                      >
                        <Edit className="h-4 w-4" />
                      </Button>
                      
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={() => handleDeleteRecord(record.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                      
                      {record.status !== "paid" && (
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => updatePaymentStatus(record.id, "paid")}
                        >
                          Mark Paid
                        </Button>
                      )}
                      
                      {record.status !== "partial" && record.status !== "paid" && (
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => updatePaymentStatus(record.id, "partial")}
                        >
                          Partial
                        </Button>
                      )}
                      
                      {record.status !== "late" && record.status !== "paid" && (
                        <Button
                          size="sm"
                          variant="destructive"
                          onClick={() => updatePaymentStatus(record.id, "late")}
                        >
                          Late
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8">
              <DollarSign className="h-12 w-12 mx-auto text-gray-400 mb-4" />
              <h3 className="text-lg font-medium mb-2">No payment records yet</h3>
              <p className="text-gray-500 mb-4">
                Start tracking rent payments for your tenants
              </p>
              <Button onClick={handleAddPayment}>
                <DollarSign className="mr-2 h-4 w-4" /> Add First Payment
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </PageLayout>
  );
};

export default RentTracking;
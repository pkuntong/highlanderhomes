import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Plus,
  Edit,
  Trash2,
  Phone,
  User,
  Calendar,
  DollarSign,
  AlertCircle,
  CheckCircle,
  Clock,
  Wrench,
  FileText,
  Camera
} from "lucide-react";
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
import MaintenanceStats from "@/components/maintenance/MaintenanceStats";

const emptyMaintenanceRequest = {
  title: '',
  description: '',
  property: '',
  tenant: '',
  priority: 'medium',
  category: 'plumbing',
  status: 'pending',
  assignedContractor: '',
  scheduledDate: '',
  scheduledTime: '',
  estimatedCost: '',
  actualCost: '',
  paymentStatus: 'pending',
  notes: '',
  photos: [],
  createdDate: new Date().toISOString().split('T')[0],
  completedDate: ''
};

const emptyContractor = {
  name: '',
  company: '',
  phone: '',
  email: '',
  specialty: 'plumbing',
  hourlyRate: '',
  notes: ''
};

const MaintenanceRequests = () => {
  const [maintenanceRequests, setMaintenanceRequests] = useState([]);
  const [contractors, setContractors] = useState([]);
  const [properties, setProperties] = useState([]);
  const [tenants, setTenants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editIndex, setEditIndex] = useState(null);
  const [form, setForm] = useState(emptyMaintenanceRequest);
  const [isContractorDialog, setIsContractorDialog] = useState(false);
  const [contractorForm, setContractorForm] = useState(emptyContractor);
  const [statusFilter, setStatusFilter] = useState('all');
  const [priorityFilter, setPriorityFilter] = useState('all');

  useEffect(() => {
    fetchAllData();
  }, []);

  const fetchAllData = async () => {
    setLoading(true);
    try {
      const [requestsSnap, contractorsSnap, propertiesSnap, tenantsSnap] = await Promise.all([
        getDocs(query(collection(db, "maintenanceRequests"), orderBy("createdDate", "desc"))),
        getDocs(collection(db, "contractors")),
        getDocs(collection(db, "properties")),
        getDocs(collection(db, "tenants"))
      ]);

      setMaintenanceRequests(requestsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setContractors(contractorsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setProperties(propertiesSnap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setTenants(tenantsSnap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredRequests = maintenanceRequests.filter(request => {
    if (statusFilter !== 'all' && request.status !== statusFilter) return false;
    if (priorityFilter !== 'all' && request.priority !== priorityFilter) return false;
    return true;
  });

  const handleAdd = () => {
    setEditIndex(null);
    setForm(emptyMaintenanceRequest);
    setIsEditing(true);
  };

  const handleEdit = (index) => {
    const request = filteredRequests[index];
    setEditIndex({ index, requestId: request.id });
    setForm({ ...request });
    setIsEditing(true);
  };

  const handleDelete = async (index) => {
    const request = filteredRequests[index];
    if (window.confirm("Are you sure you want to delete this maintenance request?")) {
      try {
        await deleteDoc(doc(db, "maintenanceRequests", request.id));
        await fetchAllData();
      } catch (error) {
        console.error("Error deleting request:", error);
        alert("Failed to delete request");
      }
    }
  };

  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setForm(prev => ({ ...prev, [name]: value }));
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editIndex !== null) {
        const requestId = editIndex.requestId;
        await updateDoc(doc(db, "maintenanceRequests", requestId), {
          ...form,
          lastUpdated: new Date().toISOString()
        });
      } else {
        await addDoc(collection(db, "maintenanceRequests"), {
          ...form,
          createdDate: new Date().toISOString()
        });
      }
      await fetchAllData();
      setIsEditing(false);
      setForm(emptyMaintenanceRequest);
      setEditIndex(null);
    } catch (error) {
      console.error("Error saving request:", error);
      alert("Failed to save request");
    }
  };

  const handleContractorSubmit = async (e) => {
    e.preventDefault();
    try {
      await addDoc(collection(db, "contractors"), contractorForm);
      await fetchAllData();
      setIsContractorDialog(false);
      setContractorForm(emptyContractor);
    } catch (error) {
      console.error("Error adding contractor:", error);
      alert("Failed to add contractor");
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800';
      case 'in-progress': return 'bg-blue-100 text-blue-800';
      case 'scheduled': return 'bg-purple-100 text-purple-800';
      case 'pending': return 'bg-yellow-100 text-yellow-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getPriorityColor = (priority) => {
    switch (priority) {
      case 'high': return 'bg-red-100 text-red-800';
      case 'medium': return 'bg-orange-100 text-orange-800';
      case 'low': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'completed': return <CheckCircle className="h-4 w-4" />;
      case 'in-progress': return <Wrench className="h-4 w-4" />;
      case 'scheduled': return <Calendar className="h-4 w-4" />;
      case 'pending': return <Clock className="h-4 w-4" />;
      default: return <AlertCircle className="h-4 w-4" />;
    }
  };

  if (loading) return <div>Loading maintenance requests...</div>;

  return (
    <PageLayout title="Maintenance Requests">
      <MaintenanceStats requests={maintenanceRequests} />

      <div className="mb-6 flex flex-col md:flex-row gap-4 md:justify-between md:items-center">
        <div className="flex flex-col md:flex-row gap-4 md:items-center">
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-full md:w-40">
              <SelectValue placeholder="Filter by status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Status</SelectItem>
              <SelectItem value="pending">Pending</SelectItem>
              <SelectItem value="scheduled">Scheduled</SelectItem>
              <SelectItem value="in-progress">In Progress</SelectItem>
              <SelectItem value="completed">Completed</SelectItem>
            </SelectContent>
          </Select>

          <Select value={priorityFilter} onValueChange={setPriorityFilter}>
            <SelectTrigger className="w-full md:w-40">
              <SelectValue placeholder="Filter by priority" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Priority</SelectItem>
              <SelectItem value="high">High</SelectItem>
              <SelectItem value="medium">Medium</SelectItem>
              <SelectItem value="low">Low</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="flex gap-2">
          <Dialog open={isContractorDialog} onOpenChange={setIsContractorDialog}>
            <DialogTrigger asChild>
              <Button variant="outline">
                <User className="mr-2 h-4 w-4" /> Add Contractor
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Add New Contractor</DialogTitle>
                <DialogDescription>
                  Add a new contractor to your network for maintenance requests.
                </DialogDescription>
              </DialogHeader>
              <form onSubmit={handleContractorSubmit}>
                <div className="grid gap-4 py-4">
                  <div className="grid grid-cols-4 items-center gap-4">
                    <label htmlFor="name" className="text-right">Name</label>
                    <Input
                      id="name"
                      name="name"
                      value={contractorForm.name}
                      onChange={(e) => setContractorForm(prev => ({ ...prev, [e.target.name]: e.target.value }))}
                      className="col-span-3"
                      required
                    />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                    <label htmlFor="company" className="text-right">Company</label>
                    <Input
                      id="company"
                      name="company"
                      value={contractorForm.company}
                      onChange={(e) => setContractorForm(prev => ({ ...prev, [e.target.name]: e.target.value }))}
                      className="col-span-3"
                    />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                    <label htmlFor="phone" className="text-right">Phone</label>
                    <Input
                      id="phone"
                      name="phone"
                      value={contractorForm.phone}
                      onChange={(e) => setContractorForm(prev => ({ ...prev, [e.target.name]: e.target.value }))}
                      className="col-span-3"
                      required
                    />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                    <label htmlFor="email" className="text-right">Email</label>
                    <Input
                      id="email"
                      name="email"
                      type="email"
                      value={contractorForm.email}
                      onChange={(e) => setContractorForm(prev => ({ ...prev, [e.target.name]: e.target.value }))}
                      className="col-span-3"
                    />
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                    <label htmlFor="specialty" className="text-right">Specialty</label>
                    <Select value={contractorForm.specialty} onValueChange={(value) => setContractorForm(prev => ({ ...prev, specialty: value }))}>
                      <SelectTrigger className="col-span-3">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="plumbing">Plumbing</SelectItem>
                        <SelectItem value="electrical">Electrical</SelectItem>
                        <SelectItem value="hvac">HVAC</SelectItem>
                        <SelectItem value="general">General Maintenance</SelectItem>
                        <SelectItem value="landscaping">Landscaping</SelectItem>
                        <SelectItem value="flooring">Flooring</SelectItem>
                        <SelectItem value="painting">Painting</SelectItem>
                        <SelectItem value="roofing">Roofing</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="grid grid-cols-4 items-center gap-4">
                    <label htmlFor="hourlyRate" className="text-right">Hourly Rate</label>
                    <Input
                      id="hourlyRate"
                      name="hourlyRate"
                      type="number"
                      value={contractorForm.hourlyRate}
                      onChange={(e) => setContractorForm(prev => ({ ...prev, [e.target.name]: e.target.value }))}
                      className="col-span-3"
                      placeholder="$"
                    />
                  </div>
                </div>
                <DialogFooter>
                  <Button type="submit">Add Contractor</Button>
                </DialogFooter>
              </form>
            </DialogContent>
          </Dialog>

          <Button onClick={handleAdd}>
            <Plus className="mr-2 h-4 w-4" /> New Request
          </Button>
        </div>
      </div>

      {isEditing && (
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>{editIndex !== null ? "Edit" : "New"} Maintenance Request</CardTitle>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleFormSubmit}>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-1">Title</label>
                  <Input name="title" value={form.title} onChange={handleFormChange} placeholder="Brief description" required />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Property</label>
                  <Select value={form.property} onValueChange={(value) => setForm(prev => ({ ...prev, property: value }))}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select property" />
                    </SelectTrigger>
                    <SelectContent>
                      {properties.map(property => (
                        <SelectItem key={property.id} value={property.id}>
                          {property.address}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Tenant</label>
                  <Select value={form.tenant} onValueChange={(value) => setForm(prev => ({ ...prev, tenant: value }))}>
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
                  <label className="block text-sm font-medium mb-1">Category</label>
                  <Select value={form.category} onValueChange={(value) => setForm(prev => ({ ...prev, category: value }))}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="plumbing">Plumbing</SelectItem>
                      <SelectItem value="electrical">Electrical</SelectItem>
                      <SelectItem value="hvac">HVAC</SelectItem>
                      <SelectItem value="general">General Maintenance</SelectItem>
                      <SelectItem value="landscaping">Landscaping</SelectItem>
                      <SelectItem value="flooring">Flooring</SelectItem>
                      <SelectItem value="painting">Painting</SelectItem>
                      <SelectItem value="roofing">Roofing</SelectItem>
                      <SelectItem value="appliances">Appliances</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Priority</label>
                  <Select value={form.priority} onValueChange={(value) => setForm(prev => ({ ...prev, priority: value }))}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="low">Low</SelectItem>
                      <SelectItem value="medium">Medium</SelectItem>
                      <SelectItem value="high">High</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Status</label>
                  <Select value={form.status} onValueChange={(value) => setForm(prev => ({ ...prev, status: value }))}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="pending">Pending</SelectItem>
                      <SelectItem value="scheduled">Scheduled</SelectItem>
                      <SelectItem value="in-progress">In Progress</SelectItem>
                      <SelectItem value="completed">Completed</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Assigned Contractor</label>
                  <Select value={form.assignedContractor} onValueChange={(value) => setForm(prev => ({ ...prev, assignedContractor: value }))}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select contractor" />
                    </SelectTrigger>
                    <SelectContent>
                      {contractors.map(contractor => (
                        <SelectItem key={contractor.id} value={contractor.id}>
                          {contractor.name} ({contractor.specialty})
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Scheduled Date</label>
                  <Input name="scheduledDate" type="date" value={form.scheduledDate} onChange={handleFormChange} />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Scheduled Time</label>
                  <Input name="scheduledTime" type="time" value={form.scheduledTime} onChange={handleFormChange} />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Estimated Cost</label>
                  <Input name="estimatedCost" type="number" value={form.estimatedCost} onChange={handleFormChange} placeholder="$" />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Actual Cost</label>
                  <Input name="actualCost" type="number" value={form.actualCost} onChange={handleFormChange} placeholder="$" />
                </div>

                <div>
                  <label className="block text-sm font-medium mb-1">Payment Status</label>
                  <Select value={form.paymentStatus} onValueChange={(value) => setForm(prev => ({ ...prev, paymentStatus: value }))}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="pending">Pending</SelectItem>
                      <SelectItem value="paid">Paid</SelectItem>
                      <SelectItem value="overdue">Overdue</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="md:col-span-2">
                  <label className="block text-sm font-medium mb-1">Description</label>
                  <Textarea name="description" value={form.description} onChange={handleFormChange} placeholder="Detailed description of the issue" rows={3} />
                </div>

                <div className="md:col-span-2">
                  <label className="block text-sm font-medium mb-1">Notes</label>
                  <Textarea name="notes" value={form.notes} onChange={handleFormChange} placeholder="Additional notes, updates, or communications" rows={3} />
                </div>
              </div>

              <div className="flex gap-2 mt-6 justify-end">
                <Button variant="outline" type="button" onClick={() => setIsEditing(false)}>Cancel</Button>
                <Button type="submit">{editIndex !== null ? "Update" : "Create"} Request</Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-1 gap-4">
        {filteredRequests.length > 0 ? (
          filteredRequests.map((request, idx) => {
            const property = properties.find(p => p.id === request.property);
            const tenant = tenants.find(t => t.id === request.tenant);
            const contractor = contractors.find(c => c.id === request.assignedContractor);

            return (
              <Card key={request.id} className="relative group hover:bg-gray-50">
                <CardContent className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-2">
                        {getStatusIcon(request.status)}
                        <h3 className="font-medium text-lg">{request.title}</h3>
                        <Badge className={`${getPriorityColor(request.priority)} text-xs`}>
                          {request.priority}
                        </Badge>
                        <Badge className={`${getStatusColor(request.status)} text-xs`}>
                          {request.status}
                        </Badge>
                      </div>
                      
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                        <div>
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-medium">Property:</span>
                            <span>{property?.address || 'Not selected'}</span>
                          </div>
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-medium">Tenant:</span>
                            <span>{tenant?.name || 'Not selected'}</span>
                          </div>
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-medium">Category:</span>
                            <span className="capitalize">{request.category}</span>
                          </div>
                        </div>
                        
                        <div>
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-medium">Contractor:</span>
                            <span>{contractor?.name || 'Not assigned'}</span>
                            {contractor && (
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => window.open(`tel:${contractor.phone}`)}
                                className="h-6 px-2"
                              >
                                <Phone className="h-3 w-3" />
                              </Button>
                            )}
                          </div>
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-medium">Scheduled:</span>
                            <span>
                              {request.scheduledDate 
                                ? `${request.scheduledDate} ${request.scheduledTime || ''}`
                                : 'Not scheduled'
                              }
                            </span>
                          </div>
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-medium">Cost:</span>
                            <span>
                              {request.actualCost 
                                ? `$${request.actualCost}` 
                                : request.estimatedCost 
                                  ? `~$${request.estimatedCost}` 
                                  : 'Not estimated'
                              }
                            </span>
                            <Badge className={`text-xs ${
                              request.paymentStatus === 'paid' ? 'bg-green-100 text-green-800' :
                              request.paymentStatus === 'overdue' ? 'bg-red-100 text-red-800' :
                              'bg-yellow-100 text-yellow-800'
                            }`}>
                              {request.paymentStatus}
                            </Badge>
                          </div>
                        </div>
                      </div>

                      {request.description && (
                        <div className="mt-3 p-3 bg-gray-50 rounded">
                          <span className="font-medium text-sm">Description:</span>
                          <p className="text-sm mt-1">{request.description}</p>
                        </div>
                      )}

                      {request.notes && (
                        <div className="mt-2 p-3 bg-blue-50 rounded">
                          <span className="font-medium text-sm">Notes:</span>
                          <p className="text-sm mt-1">{request.notes}</p>
                        </div>
                      )}

                      <div className="flex items-center justify-between mt-3 text-xs text-gray-500">
                        <span>Created: {new Date(request.createdDate).toLocaleDateString()}</span>
                        {request.completedDate && (
                          <span>Completed: {new Date(request.completedDate).toLocaleDateString()}</span>
                        )}
                      </div>
                    </div>

                    <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition">
                      <Button size="icon" variant="outline" onClick={() => handleEdit(idx)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button size="icon" variant="destructive" onClick={() => handleDelete(idx)}>
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })
        ) : (
          <Card>
            <CardContent className="p-12 text-center">
              <Wrench className="h-10 w-10 mx-auto text-gray-400 mb-4" />
              <h3 className="text-lg font-medium mb-2">No maintenance requests</h3>
              <p className="text-gray-500 mb-4">
                Create your first maintenance request to start tracking repairs and issues
              </p>
              <Button onClick={handleAdd}>
                <Plus className="mr-2 h-4 w-4" /> New Request
              </Button>
            </CardContent>
          </Card>
        )}
      </div>
    </PageLayout>
  );
};

export default MaintenanceRequests;
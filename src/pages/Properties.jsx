import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Building, Plus, Edit, Trash2 } from "lucide-react";
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

const emptyProperty = {
  address: "",
  city: "",
  state: "",
  zipCode: "",
  yearBuilt: '',
  squareFootage: '',
  bedrooms: '',
  fullBathrooms: '',
  halfBathrooms: '',
  leaseType: "Annual",
  monthlyRent: '',
  status: "vacant",
  paymentStatus: 'pending',
  description: "",
  imageUrl: "/placeholder.svg",
  imageBase64: '',
};

const Properties = () => {
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [properties, setProperties] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editIndex, setEditIndex] = useState(null);
  const [form, setForm] = useState(emptyProperty);
  const [deleteErrorIndex, setDeleteErrorIndex] = useState(null);

  // Function to remove duplicate properties with the same address
  const cleanupDuplicateProperties = async () => {
    console.log('Running duplicate property cleanup...');
    try {
      // Get all properties from Firestore
      const querySnapshot = await getDocs(collection(db, "properties"));
      
      // Group properties by address to find duplicates
      const addressMap = {};
      const duplicates = [];
      
      querySnapshot.forEach(docSnap => {
        const data = docSnap.data();
        const id = docSnap.id;
        const address = data.address;
        
        if (address) {
          // If we've seen this address before, we have a duplicate
          if (addressMap[address]) {
            // Keep the one with the more recent lastUpdated timestamp
            const existing = addressMap[address];
            const existingTimestamp = existing.data.lastUpdated || '1900-01-01';
            const currentTimestamp = data.lastUpdated || '1900-01-01';
            
            if (currentTimestamp > existingTimestamp) {
              // This one is newer, so the existing one is the duplicate
              duplicates.push(existing.id);
              addressMap[address] = { id, data };
            } else {
              // Existing one is newer, so this is the duplicate
              duplicates.push(id);
            }
          } else {
            // First time seeing this address
            addressMap[address] = { id, data };
          }
        }
      });
      
      // Delete duplicates
      if (duplicates.length > 0) {
        console.log(`Found ${duplicates.length} duplicate properties to clean up:`);
        console.log(duplicates);
        
        for (const dupId of duplicates) {
          console.log(`Deleting duplicate property ${dupId}`);
          await deleteDoc(doc(db, "properties", dupId));
        }
        
        return true; // Return true if we cleaned up something
      } else {
        console.log('No duplicate properties found.');
        return false;
      }
    } catch (error) {
      console.error('Error cleaning up duplicate properties:', error);
      return false;
    }
  };
  
  // Fetch properties from Firestore on mount
  useEffect(() => {
    async function fetchProperties() {
      setLoading(true);
      console.log('Fetching latest properties data from Firestore...');
      try {
        // Force a fresh query from Firestore
        const querySnapshot = await getDocs(collection(db, "properties"));
        
        // Process the results
        const props = querySnapshot.docs.map(docSnap => {
          const data = docSnap.data();
          return { id: docSnap.id, ...data };
        });
        
        console.log('Fetched', props.length, 'properties:', props);
        
        // Update state with fresh data
        setProperties(props);
        console.log('Properties state updated');
      } catch (error) {
        console.error('Error fetching properties:', error);
      } finally {
        setLoading(false);
      }
    }
    
    fetchProperties();
    
    // Expose fetchProperties for later use
    Properties.fetchProperties = fetchProperties;
  }, []);

  const filteredProperties = properties.filter((property) => {
    if (statusFilter !== "all" && property.status !== statusFilter) {
      return false;
    }
    const searchLower = searchTerm.toLowerCase();
    return (
      property.address.toLowerCase().includes(searchLower) ||
      property.city.toLowerCase().includes(searchLower) ||
      property.state.toLowerCase().includes(searchLower) ||
      property.zipCode.toLowerCase().includes(searchLower)
    );
  });

  const handleEdit = (index) => {
    // Use the filtered list to get the property
    const property = filteredProperties[index];
    
    if (!property || !property.id) {
      alert('Error: Cannot edit this property - missing ID');
      return;
    }
    
    console.log('EDITING PROPERTY:', property);
    console.log('WITH ID:', property.id);
    
    // Store BOTH the property ID and the index
    setEditIndex({
      index: index,
      propertyId: property.id  // Store the actual ID explicitly
    });
    
    // Make a clean copy and ensure ID is included
    setForm({
      ...property,
      id: property.id  // Make absolutely sure ID is included
    });
    
    setIsEditing(true);
  };

  const handleDelete = async (index) => {
    const property = properties[index];
    if (window.confirm("Are you sure you want to delete this property?")) {
      try {
        if (property.id) {
          await deleteDoc(doc(db, "properties", property.id));
        }
        setProperties(prev => prev.filter((_, i) => i !== index));
        setDeleteErrorIndex(null);
        await Properties.fetchProperties();
      } catch (error) {
        console.error("Error deleting property:", error);
        alert(`Failed to delete property: ${error.message}. You can now force remove this property from the list.`);
        setDeleteErrorIndex(index);
      }
    }
  };

  const handleAdd = () => {
    setEditIndex(null);
    setForm(emptyProperty);
    setIsEditing(true);
  };

  const handleFormChange = (e) => {
    const { name, value, type } = e.target;
    if (["yearBuilt", "squareFootage", "bedrooms", "fullBathrooms", "halfBathrooms", "monthlyRent"].includes(name)) {
      setForm((prev) => ({ ...prev, [name]: value === '' ? '' : Number(value) }));
    } else {
      setForm((prev) => ({ ...prev, [name]: value }));
    }
  };

  const handleImageUpload = (e) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setForm((prev) => ({ ...prev, imageBase64: reader.result, imageUrl: '' }));
      };
      reader.readAsDataURL(file);
    }
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    
    // Create a timestamp to track this specific update
    const updateTimestamp = new Date().toISOString();
    
    if (editIndex !== null) {
      // Since we changed editIndex to store both index and ID, we need to extract the propertyId
      const propertyId = editIndex.propertyId || form.id;
      
      console.log('=========== PROPERTY UPDATE ==========');
      console.log('Property ID from editIndex:', editIndex.propertyId);
      console.log('Property ID from form:', form.id);
      console.log('Using Property ID:', propertyId);
      console.log('Form data:', form);
      
      // Extra verification of the ID
      if (!propertyId) {
        console.error('CRITICAL ERROR: Missing property ID for update!');
        alert('Cannot update property: Missing ID. Please try refreshing the page and try again.');
        return;
      }
      
      // Create reference to the EXACT document
      const propertyRef = doc(db, "properties", propertyId);
      
      // Add a timestamp to the form data for tracking this update
      const updatedForm = {
        ...form,
        lastUpdated: updateTimestamp,
      };
      
      try {
        console.log(`[${updateTimestamp}] Attempting to update property with ID:`, propertyId);
        console.log(`[${updateTimestamp}] Property data for update:`, updatedForm);
        
        // First, attempt to get the current document
        const docSnapshot = await getDoc(propertyRef);
        const exists = docSnapshot.exists();
        console.log(`[${updateTimestamp}] Document exists check:`, exists);
        
        // DIRECT APPROACH: First delete if exists, then set exactly what we want
        // This prevents any possibility of duplication
        try {
          if (docSnapshot.exists()) {
            console.log(`[${updateTimestamp}] Document exists, updating directly with ID: ${propertyId}`);
            
            // Use direct update without merge option - this is most reliable
            await updateDoc(propertyRef, updatedForm);
          } else {
            console.log(`[${updateTimestamp}] Document doesn't exist, creating with ID: ${propertyId}`);
            
            // Create the document with EXPLICIT ID
            await setDoc(propertyRef, {
              ...updatedForm,
              id: propertyId,  // Ensure ID is consistent
            });
          }
          console.log(`[${updateTimestamp}] Document operation completed successfully`);
        } catch (opError) {
          console.error(`[${updateTimestamp}] Error during document operation:`, opError);
          throw opError; // Rethrow to be caught by outer catch
        }
        
        // Verify the update by fetching fresh data
        const verifySnapshot = await getDoc(propertyRef);
        if (verifySnapshot.exists()) {
          const savedData = verifySnapshot.data();
          console.log(`[${updateTimestamp}] Verification - Property saved with data:`, savedData);
          
          // Check if our timestamp made it into the saved data
          if (savedData.lastUpdated === updateTimestamp) {
            console.log(`[${updateTimestamp}] Success: Timestamp verification confirmed update`);
          } else {
            console.warn(`[${updateTimestamp}] Warning: Saved data doesn't contain our timestamp`);
          }
        } else {
          console.error(`[${updateTimestamp}] Error: Property still not found after save attempt!`);
        }
        
        // Refresh the properties list from Firestore
        console.log(`[${updateTimestamp}] Refreshing properties list from Firestore...`);
        await Properties.fetchProperties();
        
        // Also update the local state directly to ensure UI reflects changes
        setProperties(prevProps => {
          // Make a deep copy of the previous properties array
          const updatedProps = [...prevProps];
          
          // Find the property by ID (more reliable than index)
          const propIndex = updatedProps.findIndex(p => p.id === propertyId);
          
          if (propIndex >= 0) {
            // Replace with our updated data plus the ID
            updatedProps[propIndex] = { ...updatedForm, id: propertyId };
            console.log(`[${updateTimestamp}] Updated property at index ${propIndex} in local state`);
          } else {
            // If not found, add as a new item
            updatedProps.push({ ...updatedForm, id: propertyId });
            console.log(`[${updateTimestamp}] Added property to local state as it wasn't found`);
          }
          
          return updatedProps;
        });
        
        // Run the duplicate cleanup to fix any duplicate properties
        console.log(`[${updateTimestamp}] Running duplicate cleanup...`);
        const cleanupResult = await cleanupDuplicateProperties();
        if (cleanupResult) {
          console.log(`[${updateTimestamp}] Cleanup removed duplicate properties`);
        }
        
        // Show success message
        alert(`Property updated successfully!`);
        
        // Reset the form state
        setIsEditing(false);
        setForm(emptyProperty);
        setEditIndex(null);
      } catch (error) {
        console.error(`[${updateTimestamp}] Error updating property:`, error);
        alert(`Failed to update property: ${error.message}. Please try again.`);
      }
    } else {
      // Add
      try {
        await addDoc(collection(db, "properties"), form);
        await Properties.fetchProperties();
        setIsEditing(false);
        setForm(emptyProperty);
        setEditIndex(null);
      } catch (error) {
        console.error("Error adding property:", error);
        alert(`Failed to add property: ${error.message}. Please try again.`);
      }
    }
  };

  const handleCancel = () => {
    setIsEditing(false);
    setForm(emptyProperty);
    setEditIndex(null);
  };

  if (loading) return <div>Loading properties...</div>;

  return (
    <PageLayout title="Properties">
      <div className="mb-6 flex flex-col md:flex-row gap-4 md:justify-between md:items-center">
        <div className="flex flex-col md:flex-row gap-4 md:items-center">
          <div className="relative">
            <Input
              type="text"
              placeholder="Search properties..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full md:w-80"
            />
          </div>

          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-full md:w-40">
              <SelectValue placeholder="Filter by status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Properties</SelectItem>
              <SelectItem value="occupied">Occupied</SelectItem>
              <SelectItem value="vacant">Vacant</SelectItem>
              <SelectItem value="maintenance">Maintenance</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="flex gap-2 md:self-end">
          <Button variant="outline" onClick={async () => {
            await cleanupDuplicateProperties();
            await Properties.fetchProperties();
            alert('Properties refreshed and duplicates removed');
          }}>
            Refresh & Clean Properties
          </Button>
          <Button onClick={handleAdd}>
            <Plus className="mr-2 h-4 w-4" /> Add Property
          </Button>
        </div>
      </div>

      {isEditing && (
        <form onSubmit={handleFormSubmit} className="mb-6 p-4 border rounded bg-gray-50">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="address">Address</label>
              <Input name="address" id="address" value={form.address} onChange={handleFormChange} placeholder="Address" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="city">City</label>
              <Input name="city" id="city" value={form.city} onChange={handleFormChange} placeholder="City" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="state">State</label>
              <Input name="state" id="state" value={form.state} onChange={handleFormChange} placeholder="State" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="zipCode">Zip Code</label>
              <Input name="zipCode" id="zipCode" value={form.zipCode} onChange={handleFormChange} placeholder="Zip Code" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="yearBuilt">Year Built</label>
              <Input name="yearBuilt" id="yearBuilt" type="number" value={form.yearBuilt} onChange={handleFormChange} placeholder="Year Built" min={1800} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="squareFootage">Square Footage</label>
              <Input name="squareFootage" id="squareFootage" type="number" value={form.squareFootage} onChange={handleFormChange} placeholder="Square Footage" min={0} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="bedrooms">Bedrooms</label>
              <Input name="bedrooms" id="bedrooms" type="number" value={form.bedrooms} onChange={handleFormChange} placeholder="Bedrooms" min={0} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="fullBathrooms">Full Bathrooms</label>
              <Input name="fullBathrooms" id="fullBathrooms" type="number" value={form.fullBathrooms} onChange={handleFormChange} placeholder="Full Bathrooms" min={0} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="halfBathrooms">Half Bathrooms</label>
              <Input name="halfBathrooms" id="halfBathrooms" type="number" value={form.halfBathrooms} onChange={handleFormChange} placeholder="Half Bathrooms" min={0} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="leaseType">Lease Type</label>
              <Input name="leaseType" id="leaseType" value={form.leaseType} onChange={handleFormChange} placeholder="Lease Type" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="monthlyRent">Monthly Rent</label>
              <Input name="monthlyRent" id="monthlyRent" type="number" value={form.monthlyRent} onChange={handleFormChange} placeholder="Monthly Rent" min={0} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="status">Status</label>
              <select name="status" id="status" value={form.status} onChange={handleFormChange} className="border rounded px-2 py-1 w-full">
                <option value="occupied">Occupied</option>
                <option value="vacant">Vacant</option>
                <option value="maintenance">Maintenance</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="paymentStatus">Payment Status</label>
              <select name="paymentStatus" id="paymentStatus" value={form.paymentStatus} onChange={handleFormChange} className="border rounded px-2 py-1 w-full">
                <option value="paid">Paid</option>
                <option value="pending">Pending</option>
                <option value="overdue">Overdue</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="description">Description</label>
              <Input name="description" id="description" value={form.description} onChange={handleFormChange} placeholder="Description" />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="imageUpload">Home Image</label>
              <Input name="imageUpload" id="imageUpload" type="file" accept="image/*" onChange={handleImageUpload} />
              {form.imageBase64 && (
                <img src={form.imageBase64} alt="Preview" className="mt-2 h-24 w-24 object-cover rounded" />
              )}
            </div>
          </div>
          <div className="flex gap-2 mt-4 justify-end">
            <Button variant="outline" type="button" onClick={handleCancel}>Cancel</Button>
            <Button type="submit">{editIndex !== null ? "Update" : "Add"} Property</Button>
          </div>
        </form>
      )}

      {filteredProperties.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filteredProperties.map((property, idx) => (
            <Card key={property.id} className="relative group overflow-hidden">
              <div className="h-40 bg-gray-200">
                <img 
                  src={property.imageBase64 || property.imageUrl} 
                  alt={property.address} 
                  className="h-full w-full object-cover"
                />
              </div>
              <CardContent className="pt-4">
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-medium text-lg">{property.address}</h3>
                  <span className="text-xs px-2 py-1 rounded bg-gray-100">{property.status}</span>
                </div>
                <p className="text-sm text-gray-600">
                  {property.city}, {property.state} {property.zipCode}
                </p>
                <div className="mt-3 flex items-center justify-between text-sm">
                  <div>
                    <span className="font-medium">{property.bedrooms}</span> beds
                  </div>
                  <div>
                    <span className="font-medium">{property.fullBathrooms}</span> full baths
                  </div>
                  <div>
                    <span className="font-medium">{property.halfBathrooms}</span> half baths
                  </div>
                  <div>
                    <span className="font-medium">{property.squareFootage?.toLocaleString?.() || ''}</span> sqft
                  </div>
                </div>
                <div className="mt-2 text-sm text-gray-500">{property.description}</div>
                <div className="mt-2 font-medium text-highlander-700">${property.monthlyRent?.toLocaleString?.() || ''}/month</div>
                <div className="mt-1 text-xs text-gray-500">Payment Status: {property.paymentStatus || 'pending'}</div>
              </CardContent>
              <div className="absolute top-2 right-2 flex gap-2 opacity-0 group-hover:opacity-100 transition">
                <Button size="icon" variant="outline" onClick={() => handleEdit(idx)}><Edit className="h-4 w-4" /></Button>
                <Button size="icon" variant="destructive" onClick={() => handleDelete(idx)}><Trash2 className="h-4 w-4" /></Button>
                {deleteErrorIndex === idx && (
                  <Button size="icon" variant="destructive" onClick={() => setProperties(prev => prev.filter((_, i) => i !== idx))}>
                    Remove from List
                  </Button>
                )}
              </div>
            </Card>
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center py-12 text-center">
          <div className="rounded-full bg-highlander-100 p-3 text-highlander-700 mb-4">
            <Building size={24} />
          </div>
          <h3 className="text-lg font-medium mb-1">No properties found</h3>
          <p className="text-gray-500 mb-4">
            {searchTerm
              ? "Try adjusting your search or filters"
              : "Add your first property to get started"}
          </p>
          <Button onClick={handleAdd}>
            <Plus className="mr-2 h-4 w-4" /> Add Property
          </Button>
        </div>
      )}
    </PageLayout>
  );
};

export default Properties;

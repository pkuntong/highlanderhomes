
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Plus, User } from "lucide-react";

const Tenants = () => {
  // Mock tenants data
  const tenants = [
    { id: 1, name: "Sarah Johnson", property: "123 Highland Ave", leaseEnd: "2025-12-31", rentAmount: "$1,500" },
    { id: 2, name: "Michael Chen", property: "101 Bluegrass Ln", leaseEnd: "2025-09-15", rentAmount: "$1,200" },
    { id: 3, name: "Emily Rodriguez", property: "456 Bourbon St", leaseEnd: "2026-02-28", rentAmount: "$1,800" },
    { id: 4, name: "James Wilson", property: "789 Mountain View", leaseEnd: "2025-11-30", rentAmount: "$1,350" },
  ];

  return (
    <PageLayout title="Tenants">
      <div className="mb-6 flex justify-between items-center">
        <h2 className="text-lg font-semibold">Tenant Management</h2>
        <Button>
          <Plus className="mr-2 h-4 w-4" /> Add Tenant
        </Button>
      </div>

      {tenants.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {tenants.map((tenant) => (
            <Card key={tenant.id} className="hover:bg-gray-50">
              <CardContent className="p-4 flex items-center">
                <div className="p-3 bg-highlander-100 rounded-lg mr-3">
                  <User className="h-6 w-6 text-highlander-700" />
                </div>
                <div className="flex-1">
                  <h3 className="font-medium">{tenant.name}</h3>
                  <p className="text-sm text-gray-500">{tenant.property}</p>
                  <div className="flex justify-between mt-2">
                    <span className="text-xs text-gray-500">Lease ends: {new Date(tenant.leaseEnd).toLocaleDateString()}</span>
                    <span className="text-xs font-medium">{tenant.rentAmount}/month</span>
                  </div>
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
            <Button>
              <Plus className="mr-2 h-4 w-4" /> Add Tenant
            </Button>
          </CardContent>
        </Card>
      )}
    </PageLayout>
  );
};

export default Tenants;

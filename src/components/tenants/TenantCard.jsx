import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { User, Edit, Trash2, Mail, Phone, MapPin, Calendar } from "lucide-react";

export default function TenantCard({ tenant, property, onEdit, onDelete, index }) {
  const isLeaseActive = () => {
    const now = new Date();
    const start = new Date(tenant.leaseStartDate);
    const end = new Date(tenant.leaseEndDate);
    return now >= start && now <= end;
  };

  const getDaysUntilLeaseEnd = () => {
    const now = new Date();
    const end = new Date(tenant.leaseEndDate);
    const diffTime = end - now;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  };

  const daysRemaining = getDaysUntilLeaseEnd();
  const active = isLeaseActive();

  return (
    <Card className="relative group hover:bg-gray-50 dark:hover:bg-gray-800">
      <CardContent className="p-4">
        <div className="flex items-start gap-3">
          <div className="p-3 bg-highlander-100 dark:bg-highlander-900 rounded-lg">
            <User className="h-6 w-6 text-highlander-700 dark:text-highlander-300" />
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between gap-2">
              <div>
                <h3 className="font-semibold text-lg">{tenant.name}</h3>
                {property && (
                  <div className="flex items-center gap-1 text-sm text-gray-600 dark:text-gray-400 mt-1">
                    <MapPin className="h-3 w-3" />
                    <span className="truncate">{property.address}, {property.city}</span>
                  </div>
                )}
              </div>

              <Badge variant={active ? "success" : "secondary"}>
                {active ? "Active" : "Inactive"}
              </Badge>
            </div>

            <div className="mt-3 space-y-2">
              <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                <Mail className="h-4 w-4" />
                <a href={`mailto:${tenant.email}`} className="hover:text-highlander-600 dark:hover:text-highlander-400">
                  {tenant.email}
                </a>
              </div>

              <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                <Phone className="h-4 w-4" />
                <a href={`tel:${tenant.phone}`} className="hover:text-highlander-600 dark:hover:text-highlander-400">
                  {tenant.phone}
                </a>
              </div>

              <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                <Calendar className="h-4 w-4" />
                <span>
                  {new Date(tenant.leaseStartDate).toLocaleDateString()} - {new Date(tenant.leaseEndDate).toLocaleDateString()}
                </span>
              </div>

              {active && daysRemaining <= 60 && (
                <div className="mt-2">
                  <Badge variant={daysRemaining <= 30 ? "destructive" : "warning"}>
                    {daysRemaining} days remaining
                  </Badge>
                </div>
              )}

              {tenant.notes && (
                <div className="mt-2 p-2 bg-gray-100 dark:bg-gray-700 rounded text-xs">
                  {tenant.notes}
                </div>
              )}
            </div>
          </div>

          <div className="absolute top-2 right-2 flex gap-2 opacity-0 group-hover:opacity-100 transition">
            <Button size="icon" variant="outline" onClick={() => onEdit(index)}>
              <Edit className="h-4 w-4" />
            </Button>
            <Button size="icon" variant="destructive" onClick={() => onDelete(index)}>
              <Trash2 className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

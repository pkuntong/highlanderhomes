import { useState } from "react";
import PageLayout from "@/components/layout/PageLayout";
import StatCard from "@/components/dashboard/StatCard";
import PropertyCard from "@/components/dashboard/PropertyCard";
import UpcomingReminders from "@/components/dashboard/UpcomingReminders";
import MaintenanceStatus from "@/components/dashboard/MaintenanceStatus";
import { Building, Users, ArrowUp, ArrowDown, DollarSign, Wrench } from "lucide-react";

const PROPERTIES_KEY = "highlanderhomes_properties";
const REMINDERS_KEY = "highlanderhomes_reminders";
const MAINTENANCE_KEY = "highlanderhomes_maintenance";

const Dashboard = () => {
  // Load data from localStorage
  const [properties] = useState(() => {
    const stored = localStorage.getItem(PROPERTIES_KEY);
    return stored ? JSON.parse(stored) : [];
  });

  const [reminders] = useState(() => {
    const stored = localStorage.getItem(REMINDERS_KEY);
    return stored ? JSON.parse(stored) : [];
  });

  const [maintenanceLogs] = useState(() => {
    const stored = localStorage.getItem(MAINTENANCE_KEY);
    return stored ? JSON.parse(stored) : [];
  });

  // Get only active reminders
  const activeReminders = reminders
    .filter(reminder => reminder.status === "pending")
    .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
    .slice(0, 5);

  // Get recent maintenance logs
  const recentMaintenanceLogs = [...maintenanceLogs]
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
    .slice(0, 5);

  // Calculate statistics
  const occupiedProperties = properties.filter(
    (property) => property.status === "occupied"
  ).length;

  const occupancyRate = properties.length > 0 
    ? Math.round((occupiedProperties / properties.length) * 100)
    : 0;

  const totalRent = properties.reduce(
    (sum, property) => sum + (property.monthlyRent || 0),
    0
  );

  const activeMaintenanceCount = maintenanceLogs.filter(
    (log) => log.status !== "completed"
  ).length;

  // Calculate trends (placeholder - in a real app, this would compare with historical data)
  const occupancyTrend = 5; // Example trend
  const revenueTrend = -2; // Example trend

  return (
    <PageLayout title="Dashboard">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        <StatCard
          title="Total Properties"
          value={properties.length}
          icon={<Building size={24} />}
        />
        <StatCard
          title="Occupancy Rate"
          value={`${occupancyRate}%`}
          icon={<Users size={24} />}
          trend={{ value: occupancyTrend, label: "vs last month" }}
          trendUp={occupancyTrend > 0}
        />
        <StatCard
          title="Monthly Revenue"
          value={`$${totalRent.toLocaleString()}`}
          icon={<DollarSign size={24} />}
          trend={{ value: revenueTrend, label: "vs last month" }}
          trendUp={revenueTrend > 0}
        />
        <StatCard
          title="Active Maintenance"
          value={activeMaintenanceCount}
          icon={<Wrench size={24} />}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        <div className="lg:col-span-2">
          <h2 className="text-lg font-semibold mb-4">Your Properties</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {properties.slice(0, 4).map((property) => (
              <PropertyCard key={property.id} property={property} />
            ))}
          </div>
        </div>
        <div>
          <UpcomingReminders reminders={activeReminders} />
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-3">
          <MaintenanceStatus maintenanceLogs={recentMaintenanceLogs} />
        </div>
      </div>
    </PageLayout>
  );
};

export default Dashboard;

import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import StatCard from "@/components/dashboard/StatCard";
import PropertyCard from "@/components/dashboard/PropertyCard";
import PropertyStats from "@/components/dashboard/PropertyStats";
import UpcomingReminders from "@/components/dashboard/UpcomingReminders";
import MaintenanceStatus from "@/components/dashboard/MaintenanceStatus";
import MarketAnalytics from "@/components/dashboard/MarketAnalytics";
import { DashboardSkeleton } from "@/components/ui/loading";
import { Building, Users, ArrowUp, ArrowDown, DollarSign, Wrench, TrendingUp, Home } from "lucide-react";
import { db } from "@/firebase";
import { collection, getDocs } from "firebase/firestore";

const PROPERTIES_KEY = "highlanderhomes_properties";
const REMINDERS_KEY = "highlanderhomes_reminders";
const MAINTENANCE_KEY = "highlanderhomes_maintenance";

const Dashboard = () => {
  const [properties, setProperties] = useState([]);
  const [reminders, setReminders] = useState([]);
  const [maintenanceLogs, setMaintenanceLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchData() {
      setLoading(true);
      const [propertiesSnap, remindersSnap, maintenanceSnap] = await Promise.all([
        getDocs(collection(db, "properties")),
        getDocs(collection(db, "reminders")),
        getDocs(collection(db, "maintenanceLogs")),
      ]);
      setProperties(propertiesSnap.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() })));
      setReminders(remindersSnap.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() })));
      setMaintenanceLogs(maintenanceSnap.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() })));
      setLoading(false);
    }
    fetchData();
  }, []);

  // Get only active reminders (pending and future/today dates only)
  const today = new Date();
  today.setHours(0, 0, 0, 0); // Reset to start of day for accurate comparison

  const activeReminders = reminders
    .filter(reminder => {
      const reminderDate = new Date(reminder.date);
      reminderDate.setHours(0, 0, 0, 0);
      return reminder.status === "pending" && reminderDate >= today;
    })
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

  const totalFootage = properties.reduce(
    (sum, property) => sum + (property.footage || 0),
    0
  );

  const activeMaintenanceCount = maintenanceLogs.filter(
    (log) => log.status !== "completed"
  ).length;

  // Calculate trends (placeholder - in a real app, this would compare with historical data)
  const occupancyTrend = 5; // Example trend
  const revenueTrend = -2; // Example trend

  if (loading) {
    return (
      <PageLayout title="Dashboard">
        <DashboardSkeleton />
      </PageLayout>
    );
  }

  return (
    <PageLayout title="Dashboard">
      {/* Welcome Section */}
      <div className="mb-8 animate-slide-up">
        <div className="text-center lg:text-left">
          <h1 className="text-4xl lg:text-5xl font-bold text-gradient mb-4">
            Welcome back
          </h1>
          <p className="text-lg text-foreground-muted max-w-2xl">
            Here's an overview of your property portfolio performance
          </p>
        </div>
      </div>

      {/* New Property Statistics Component */}
      <div className="mb-8 animate-slide-up">
        <PropertyStats properties={properties} />
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-5 gap-6 mb-12">
        <div className="animate-slide-up" style={{ animationDelay: '0.1s' }}>
          <StatCard
            title="Total Properties"
            value={properties.length}
            icon={<Home size={24} />}
          />
        </div>
        <div className="animate-slide-up" style={{ animationDelay: '0.2s' }}>
          <StatCard
            title="Occupancy Rate"
            value={`${occupancyRate}%`}
            icon={<Users size={24} />}
            trend={{ value: occupancyTrend, label: "vs last month" }}
            trendUp={occupancyTrend > 0}
          />
        </div>
        <div className="animate-slide-up" style={{ animationDelay: '0.3s' }}>
          <StatCard
            title="Monthly Revenue"
            value={`$${totalRent.toLocaleString()}`}
            icon={<DollarSign size={24} />}
            trend={{ value: revenueTrend, label: "vs last month" }}
            trendUp={revenueTrend > 0}
          />
        </div>
        <div className="animate-slide-up" style={{ animationDelay: '0.4s' }}>
          <StatCard
            title="Total Footage"
            value={`${totalFootage.toLocaleString()} sq ft`}
            icon={<Building size={24} />}
          />
        </div>
        <div className="animate-slide-up" style={{ animationDelay: '0.5s' }}>
          <StatCard
            title="Active Maintenance"
            value={activeMaintenanceCount}
            icon={<Wrench size={24} />}
          />
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-12">
        {/* Properties Section */}
        <div className="lg:col-span-2 animate-slide-up" style={{ animationDelay: '0.6s' }}>
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-premium">Portfolio Overview</h2>
            <div className="flex items-center text-sm text-foreground-muted">
              <TrendingUp size={16} className="mr-2" />
              <span>Latest properties</span>
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {properties.slice(0, 4).map((property, index) => (
              <div
                key={property.id}
                className="animate-slide-up"
                style={{ animationDelay: `${0.7 + index * 0.1}s` }}
              >
                <PropertyCard property={property} />
              </div>
            ))}
          </div>
        </div>

        {/* Sidebar Content */}
        <div className="lg:col-span-1 space-y-6">
          <div className="animate-slide-up" style={{ animationDelay: '0.8s' }}>
            <UpcomingReminders reminders={activeReminders} />
          </div>

          {/* Market Analytics for first property */}
          {properties.length > 0 && (
            <div className="animate-slide-up" style={{ animationDelay: '0.9s' }}>
              <MarketAnalytics property={properties[0]} />
            </div>
          )}
        </div>
      </div>

      {/* Maintenance Section */}
      <div className="animate-slide-up" style={{ animationDelay: '0.9s' }}>
        <MaintenanceStatus maintenanceLogs={recentMaintenanceLogs} />
      </div>

      {/* Premium Footer */}
      <footer className="mt-16 text-center">
        <div className="glass p-8 rounded-2xl inline-block animate-slide-up" style={{ animationDelay: '1s' }}>
          <div className="space-y-2 text-sm text-foreground-muted">
            <div className="flex items-center justify-center space-x-4">
              <span>📞 240-449-4338</span>
              <span>•</span>
              <a 
                href="mailto:highlanderhomes22@gmail.com" 
                className="text-primary hover:text-primary-600 transition-colors"
              >
                ✉️ highlanderhomes22@gmail.com
              </a>
            </div>
            <div className="text-xs">
              © 2025 Highlander Homes LLC. All rights reserved.
            </div>
          </div>
        </div>
      </footer>
    </PageLayout>
  );
};

export default Dashboard;

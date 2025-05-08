import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";
import { db } from "@/firebase";
import { collection, getDocs } from "firebase/firestore";
import { Button } from "@/components/ui/button";

const Analytics = () => {
  const [properties, setProperties] = useState([]);
  const [reminders, setReminders] = useState([]);
  const [loading, setLoading] = useState(true);

  // Fetch properties and reminders from Firestore on mount
  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    setLoading(true);
    const [propertiesSnap, remindersSnap] = await Promise.all([
      getDocs(collection(db, "properties")),
      getDocs(collection(db, "reminders")),
    ]);
    setProperties(propertiesSnap.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() })));
    setReminders(remindersSnap.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() })));
    setLoading(false);
  }

  // Calculate monthly revenue
  const monthlyRevenue = properties.reduce((sum, property) => {
    if (property.status === "occupied") {
      return sum + (property.monthlyRent || 0);
    }
    return sum;
  }, 0);

  // Calculate potential revenue
  const potentialRevenue = properties.reduce(
    (sum, property) => sum + (property.monthlyRent || 0),
    0
  );

  // Calculate occupancy rate
  const occupiedProperties = properties.filter(
    (property) => property.status === "occupied"
  ).length;
  const occupancyRate = properties.length > 0 ? (occupiedProperties / properties.length) * 100 : 0;

  // Calculate properties by status
  const propertiesByStatus = [
    { name: "Occupied", value: occupiedProperties },
    { name: "Vacant", value: properties.filter((p) => p.status === "vacant").length },
    { name: "Maintenance", value: properties.filter((p) => p.status === "maintenance").length },
  ];

  // Calculate upcoming reminders
  const upcomingReminders = reminders.filter(
    (reminder) => reminder.status === "pending"
  ).length;

  // Monthly rent data (dummy, could be improved)
  const monthlyRentData = [
    { month: "Jan", revenue: monthlyRevenue },
    { month: "Feb", revenue: monthlyRevenue },
    { month: "Mar", revenue: monthlyRevenue },
    { month: "Apr", revenue: monthlyRevenue },
    { month: "May", revenue: monthlyRevenue },
    { month: "Jun", revenue: monthlyRevenue },
    { month: "Jul", revenue: monthlyRevenue },
    { month: "Aug", revenue: monthlyRevenue },
    { month: "Sep", revenue: monthlyRevenue },
    { month: "Oct", revenue: monthlyRevenue },
    { month: "Nov", revenue: monthlyRevenue },
    { month: "Dec", revenue: monthlyRevenue },
  ];

  // Colors for pie chart
  const COLORS = ["#0088FE", "#FFBB28", "#FF8042"];

  if (loading) return <div>Loading analytics...</div>;

  return (
    <PageLayout title="Analytics">
      <div className="mb-4 flex justify-end">
        <Button onClick={fetchData} variant="outline">Refresh</Button>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">
              Total Properties
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{properties.length}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">
              Occupancy Rate
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{occupancyRate.toFixed(0)}%</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">
              Monthly Revenue
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${monthlyRevenue.toLocaleString()}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">
              Upcoming Reminders
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{upcomingReminders}</div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Properties by Status</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={propertiesByStatus}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label
                >
                  {propertiesByStatus.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Monthly Revenue</CardTitle>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={monthlyRentData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="revenue" fill="#0088FE" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>
    </PageLayout>
  );
};

export default Analytics;

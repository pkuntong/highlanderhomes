
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { properties, reminders } from "@/data/mockData";
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

const Analytics = () => {
  // Calculate monthly revenue
  const monthlyRevenue = properties.reduce((sum, property) => {
    if (property.status === "occupied") {
      return sum + property.monthlyRent;
    }
    return sum;
  }, 0);

  // Calculate potential revenue
  const potentialRevenue = properties.reduce(
    (sum, property) => sum + property.monthlyRent,
    0
  );

  // Calculate occupancy rate
  const occupiedProperties = properties.filter(
    (property) => property.status === "occupied"
  ).length;
  const occupancyRate = (occupiedProperties / properties.length) * 100;

  // Calculate properties by status
  const propertiesByStatus = [
    { name: "Occupied", value: occupiedProperties },
    { name: "Vacant", value: properties.length - occupiedProperties },
  ];

  // Calculate upcoming reminders
  const upcomingReminders = reminders.filter(
    (reminder) => reminder.status === "pending"
  ).length;

  // Monthly rent data
  const monthlyRentData = [
    { month: "Jan", revenue: 42000 },
    { month: "Feb", revenue: 45000 },
    { month: "Mar", revenue: 48000 },
    { month: "Apr", revenue: 48000 },
    { month: "May", revenue: 52000 },
    { month: "Jun", revenue: 52000 },
    { month: "Jul", revenue: 52000 },
    { month: "Aug", revenue: 55000 },
    { month: "Sep", revenue: 55000 },
    { month: "Oct", revenue: 55000 },
    { month: "Nov", revenue: 58000 },
    { month: "Dec", revenue: 58000 },
  ];

  // Colors for pie chart
  const COLORS = ["#0088FE", "#FFBB28"];

  return (
    <PageLayout title="Analytics">
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

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <Card>
          <CardHeader>
            <CardTitle>Monthly Revenue</CardTitle>
          </CardHeader>
          <CardContent className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={monthlyRentData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip formatter={(value) => [`$${value}`, "Revenue"]} />
                <Bar dataKey="revenue" fill="#3B82F6" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Occupancy Status</CardTitle>
          </CardHeader>
          <CardContent className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={propertiesByStatus}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {propertiesByStatus.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Legend />
                <Tooltip formatter={(value) => [value, "Properties"]} />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>
    </PageLayout>
  );
};

export default Analytics;

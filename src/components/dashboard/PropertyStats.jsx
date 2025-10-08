import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Building, DollarSign, Users, TrendingUp, AlertCircle } from "lucide-react";

export default function PropertyStats({ properties }) {
  // Calculate statistics
  const totalProperties = properties.length;
  const occupiedProperties = properties.filter(p => p.status === 'occupied').length;
  const vacantProperties = properties.filter(p => p.status === 'vacant').length;
  const maintenanceProperties = properties.filter(p => p.status === 'maintenance').length;

  const totalRevenue = properties.reduce((sum, p) => {
    if (p.status === 'occupied' && p.monthlyRent) {
      return sum + Number(p.monthlyRent);
    }
    return sum;
  }, 0);

  const potentialRevenue = properties.reduce((sum, p) => {
    return sum + (Number(p.monthlyRent) || 0);
  }, 0);

  const occupancyRate = totalProperties > 0
    ? ((occupiedProperties / totalProperties) * 100).toFixed(1)
    : 0;

  // Payment status calculations
  const paidProperties = properties.filter(p => p.paymentStatus === 'paid').length;
  const pendingProperties = properties.filter(p => p.paymentStatus === 'pending').length;
  const overdueProperties = properties.filter(p => p.paymentStatus === 'overdue').length;

  const collectionRate = totalProperties > 0
    ? ((paidProperties / totalProperties) * 100).toFixed(1)
    : 0;

  return (
    <div className="space-y-4">
      {/* Primary Stats Row */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Properties</CardTitle>
            <Building className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{totalProperties}</div>
            <p className="text-xs text-muted-foreground mt-1">
              {occupiedProperties} occupied · {vacantProperties} vacant
            </p>
            {maintenanceProperties > 0 && (
              <p className="text-xs text-orange-600 mt-1">
                {maintenanceProperties} in maintenance
              </p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Monthly Revenue</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              ${totalRevenue.toLocaleString()}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Current from occupied units
            </p>
            {potentialRevenue > totalRevenue && (
              <p className="text-xs text-gray-500 mt-1">
                Potential: ${potentialRevenue.toLocaleString()}
              </p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Occupancy Rate</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{occupancyRate}%</div>
            <p className="text-xs text-muted-foreground mt-1">
              {occupiedProperties} of {totalProperties} units filled
            </p>
            <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
              <div
                className="bg-green-600 h-2 rounded-full"
                style={{ width: `${occupancyRate}%` }}
              ></div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Collection Rate</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{collectionRate}%</div>
            <p className="text-xs text-muted-foreground mt-1">
              {paidProperties} paid · {pendingProperties} pending
            </p>
            {overdueProperties > 0 && (
              <p className="text-xs text-red-600 mt-1 flex items-center">
                <AlertCircle className="h-3 w-3 mr-1" />
                {overdueProperties} overdue
              </p>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Revenue Breakdown */}
      {totalProperties > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Revenue Breakdown</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Collected This Month:</span>
                <span className="font-semibold text-green-600">
                  ${(totalRevenue * (paidProperties / Math.max(totalProperties, 1))).toLocaleString()}
                </span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Pending Collection:</span>
                <span className="font-semibold text-yellow-600">
                  ${(totalRevenue * (pendingProperties / Math.max(totalProperties, 1))).toLocaleString()}
                </span>
              </div>
              {overdueProperties > 0 && (
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Overdue Payments:</span>
                  <span className="font-semibold text-red-600">
                    ${(totalRevenue * (overdueProperties / Math.max(totalProperties, 1))).toLocaleString()}
                  </span>
                </div>
              )}
              <div className="flex items-center justify-between text-sm pt-2 border-t">
                <span className="font-medium">Lost Revenue (Vacancy):</span>
                <span className="font-semibold text-gray-500">
                  -${(potentialRevenue - totalRevenue).toLocaleString()}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

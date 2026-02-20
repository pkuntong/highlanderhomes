import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { AlertTriangle, Building2, DollarSign, FileText, Home, UserCircle2, Wrench } from "lucide-react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useAuth } from "@/contexts/AuthContext";
import { fetchDashboardSnapshot } from "@/services/dataService";
import { formatCurrency, formatDate } from "@/lib/format";
import AppStoreBadge from "@/components/common/AppStoreBadge";

function StatCard({ title, value, hint, icon: Icon }) {
  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm text-muted-foreground flex items-center justify-between">
          <span>{title}</span>
          <Icon className="h-4 w-4" />
        </CardTitle>
      </CardHeader>
      <CardContent>
        <p className="text-2xl font-semibold">{value}</p>
        {hint ? <p className="text-xs text-muted-foreground mt-1">{hint}</p> : null}
      </CardContent>
    </Card>
  );
}

export default function Dashboard() {
  const iosAppUrl =
    import.meta.env.VITE_IOS_APP_URL || "https://apps.apple.com/us/app/highlander-homes/id6758958500";

  const { currentUser } = useAuth();
  const userId = currentUser?._id;

  const dashboardQuery = useQuery({
    queryKey: ["dashboardSnapshot", userId],
    queryFn: () => fetchDashboardSnapshot(userId),
    enabled: Boolean(userId),
  });

  const data = dashboardQuery.data;
  const properties = data?.properties || [];
  const tenants = data?.tenants || [];
  const maintenanceRequests = data?.maintenanceRequests || [];
  const rentPayments = data?.rentPayments || [];
  const expenses = data?.expenses || [];
  const documents = data?.documents || [];
  const insurancePolicies = data?.insurancePolicies || [];
  const rentalLicenses = data?.rentalLicenses || [];

  const propertyMap = useMemo(
    () =>
      Object.fromEntries(
        properties.map((property) => [
          property._id,
          property.name || `${property.address}, ${property.city}`,
        ])
      ),
    [properties]
  );

  const metrics = useMemo(() => {
    const occupied = tenants.filter((tenant) => tenant.isActive).length;
    const occupancy = properties.length > 0 ? Math.round((occupied / properties.length) * 100) : 0;

    const monthlyRevenue = properties.reduce(
      (total, property) => total + Number(property.monthlyRent || 0),
      0
    );

    const monthlyExpenses = expenses
      .filter((expense) => {
        const expenseDate = new Date(expense.date);
        const now = new Date();
        return (
          expenseDate.getMonth() === now.getMonth() &&
          expenseDate.getFullYear() === now.getFullYear()
        );
      })
      .reduce((total, expense) => total + Number(expense.amount || 0), 0);

    const pendingMaintenance = maintenanceRequests.filter(
      (request) => !["completed", "cancelled"].includes(request.status)
    ).length;

    const now = Date.now();
    const policyAlerts = insurancePolicies.filter((policy) => policy.termEnd <= now + 90 * 24 * 60 * 60 * 1000).length;
    const licenseAlerts = rentalLicenses.filter((license) => license.dateTo <= now + 90 * 24 * 60 * 60 * 1000).length;

    return {
      occupancy,
      monthlyRevenue,
      monthlyExpenses,
      netCashflow: monthlyRevenue - monthlyExpenses,
      pendingMaintenance,
      collectedPayments: rentPayments.filter((payment) => payment.status === "completed").length,
      documents: documents.length,
      complianceAlerts: policyAlerts + licenseAlerts,
    };
  }, [documents.length, expenses, insurancePolicies, maintenanceRequests, properties, rentalLicenses, rentPayments, tenants]);

  const recentMaintenance = useMemo(() => {
    return [...maintenanceRequests]
      .sort((a, b) => Number(b.updatedAt || 0) - Number(a.updatedAt || 0))
      .slice(0, 6);
  }, [maintenanceRequests]);

  const upcomingLeaseExpirations = useMemo(() => {
    const now = Date.now();
    const ninetyDaysFromNow = now + 90 * 24 * 60 * 60 * 1000;
    return tenants
      .filter((tenant) => tenant.isActive && tenant.leaseEndDate >= now && tenant.leaseEndDate <= ninetyDaysFromNow)
      .sort((a, b) => a.leaseEndDate - b.leaseEndDate)
      .slice(0, 5);
  }, [tenants]);

  const documentsByProperty = useMemo(() => {
    const countMap = new Map();
    for (const document of documents) {
      const key = document.propertyId || "__portfolio";
      countMap.set(key, (countMap.get(key) || 0) + 1);
    }
    return countMap;
  }, [documents]);

  const expiringInsurance = useMemo(() => {
    const now = Date.now();
    const ninetyDays = now + 90 * 24 * 60 * 60 * 1000;
    return insurancePolicies
      .filter((policy) => policy.termEnd <= ninetyDays)
      .sort((a, b) => a.termEnd - b.termEnd)
      .slice(0, 6);
  }, [insurancePolicies]);

  const expiringLicenses = useMemo(() => {
    const now = Date.now();
    const ninetyDays = now + 90 * 24 * 60 * 60 * 1000;
    return rentalLicenses
      .filter((license) => license.dateTo <= ninetyDays)
      .sort((a, b) => a.dateTo - b.dateTo)
      .slice(0, 6);
  }, [rentalLicenses]);

  const nowMs = Date.now();

  return (
    <PageLayout
      title="Dashboard"
      onRefresh={() => dashboardQuery.refetch()}
      isRefreshing={dashboardQuery.isFetching}
    >
      <div className="space-y-6">
        <section>
          <h2 className="text-2xl font-semibold">Portfolio Snapshot</h2>
          <p className="text-sm text-muted-foreground">
            Live data from Convex for {currentUser?.email}
          </p>
        </section>

        <Card>
          <CardContent className="py-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="font-medium">Best experience on iPhone/iPad</p>
              <p className="text-sm text-muted-foreground">
                Download the iOS app for full mobile workflows and offline-friendly operation.
              </p>
            </div>
            <AppStoreBadge href={iosAppUrl} className="w-fit" />
          </CardContent>
        </Card>

        {dashboardQuery.isLoading ? (
          <Card>
            <CardContent className="py-10 text-center text-muted-foreground">
              Loading dashboard data...
            </CardContent>
          </Card>
        ) : null}

        {dashboardQuery.error ? (
          <Card>
            <CardContent className="py-6 text-red-600 text-sm">
              {dashboardQuery.error.message}
            </CardContent>
          </Card>
        ) : null}

        {!dashboardQuery.isLoading && !dashboardQuery.error ? (
          <>
            <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4 2xl:grid-cols-8">
              <StatCard
                title="Properties"
                value={properties.length}
                hint="Total units tracked"
                icon={Home}
              />
              <StatCard
                title="Occupancy"
                value={`${metrics.occupancy}%`}
                hint="Active tenants / properties"
                icon={Building2}
              />
              <StatCard
                title="Revenue"
                value={formatCurrency(metrics.monthlyRevenue)}
                hint="Expected monthly rent"
                icon={DollarSign}
              />
              <StatCard
                title="Expenses"
                value={formatCurrency(metrics.monthlyExpenses)}
                hint="This month"
                icon={DollarSign}
              />
              <StatCard
                title="Net"
                value={formatCurrency(metrics.netCashflow)}
                hint="Revenue - expenses"
                icon={DollarSign}
              />
              <StatCard
                title="Pending Work"
                value={metrics.pendingMaintenance}
                hint="Open maintenance requests"
                icon={Wrench}
              />
              <StatCard
                title="Documents"
                value={metrics.documents}
                hint="Secure files in vault"
                icon={FileText}
              />
              <StatCard
                title="Renewal Alerts"
                value={metrics.complianceAlerts}
                hint="Lease/insurance/license"
                icon={AlertTriangle}
              />
            </section>

            <section className="grid gap-6 lg:grid-cols-2">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0">
                  <CardTitle>Recent Maintenance</CardTitle>
                  <Button asChild variant="outline" size="sm">
                    <Link to="/maintenance">Open Maintenance</Link>
                  </Button>
                </CardHeader>
                <CardContent className="space-y-3">
                  {recentMaintenance.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No maintenance requests yet.</p>
                  ) : (
                    recentMaintenance.map((request) => (
                      <div key={request._id} className="rounded-md border p-3">
                        <div className="flex items-start justify-between gap-3">
                          <div>
                            <p className="font-medium">{request.title}</p>
                            <p className="text-xs text-muted-foreground">
                              {propertyMap[request.propertyId] || "Unknown property"}
                            </p>
                          </div>
                          <Badge variant="outline">{request.status}</Badge>
                        </div>
                        <p className="mt-2 text-xs text-muted-foreground">
                          Updated {formatDate(request.updatedAt)}
                        </p>
                      </div>
                    ))
                  )}
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0">
                  <CardTitle>Upcoming Lease Expirations</CardTitle>
                  <Button asChild variant="outline" size="sm">
                    <Link to="/properties">Open Properties</Link>
                  </Button>
                </CardHeader>
                <CardContent className="space-y-3">
                  {upcomingLeaseExpirations.length === 0 ? (
                    <div className="rounded-md border p-3 text-sm text-muted-foreground">
                      No active leases expiring in the next 90 days.
                    </div>
                  ) : (
                    upcomingLeaseExpirations.map((tenant) => (
                      <div key={tenant._id} className="rounded-md border p-3">
                        <div className="flex items-start justify-between gap-3">
                          <div>
                            <p className="font-medium flex items-center gap-2">
                              <UserCircle2 className="h-4 w-4" />
                              {tenant.firstName} {tenant.lastName}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              Ends {formatDate(tenant.leaseEndDate)}
                            </p>
                          </div>
                          <Badge variant="secondary">{formatCurrency(tenant.monthlyRent)}</Badge>
                        </div>
                      </div>
                    ))
                  )}
                </CardContent>
              </Card>
            </section>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0">
                <CardTitle>Documents by Property</CardTitle>
                <Button asChild variant="outline" size="sm">
                  <Link to="/documents">Open Vault</Link>
                </Button>
              </CardHeader>
              <CardContent className="space-y-3">
                {properties.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No properties available.</p>
                ) : (
                  properties.map((property) => (
                    <div
                      key={property._id}
                      className="flex items-center justify-between rounded-md border p-3"
                    >
                      <div>
                        <p className="font-medium">{propertyMap[property._id]}</p>
                        <p className="text-xs text-muted-foreground">
                          {property.address}, {property.city}
                        </p>
                      </div>
                      <Button asChild variant="ghost" size="sm">
                        <Link to={`/documents?propertyId=${property._id}`}>
                          {documentsByProperty.get(property._id) || 0} files
                        </Link>
                      </Button>
                    </div>
                  ))
                )}
                <div className="flex items-center justify-between rounded-md border p-3">
                  <div>
                    <p className="font-medium">Portfolio-level</p>
                    <p className="text-xs text-muted-foreground">Files not tied to a single property</p>
                  </div>
                  <Button asChild variant="ghost" size="sm">
                    <Link to="/documents?propertyId=portfolio">
                      {documentsByProperty.get("__portfolio") || 0} files
                    </Link>
                  </Button>
                </div>
              </CardContent>
            </Card>

            <section className="grid gap-6 lg:grid-cols-2">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0">
                  <CardTitle>Insurance Renewals (90d)</CardTitle>
                  <Button asChild variant="outline" size="sm">
                    <Link to="/documents?category=insurance">Open Documents</Link>
                  </Button>
                </CardHeader>
                <CardContent className="space-y-3">
                  {expiringInsurance.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No insurance policy renewals in next 90 days.</p>
                  ) : (
                    expiringInsurance.map((policy) => {
                      const days = Math.ceil((policy.termEnd - nowMs) / (24 * 60 * 60 * 1000));
                      return (
                        <div key={policy._id} className="rounded-md border p-3">
                          <div className="flex items-center justify-between gap-3">
                            <div>
                              <p className="font-medium">{policy.insuranceName}</p>
                              <p className="text-xs text-muted-foreground">{policy.propertyLabel}</p>
                            </div>
                            <Badge variant={days <= 14 ? "destructive" : "outline"}>
                              {days < 0 ? `${Math.abs(days)}d overdue` : `${days}d left`}
                            </Badge>
                          </div>
                          <p className="mt-1 text-xs text-muted-foreground">
                            Ends {formatDate(policy.termEnd)}
                          </p>
                        </div>
                      );
                    })
                  )}
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0">
                  <CardTitle>Rental License Renewals (90d)</CardTitle>
                  <Button asChild variant="outline" size="sm">
                    <Link to="/documents?category=lease">Open Documents</Link>
                  </Button>
                </CardHeader>
                <CardContent className="space-y-3">
                  {expiringLicenses.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No rental license renewals in next 90 days.</p>
                  ) : (
                    expiringLicenses.map((license) => {
                      const days = Math.ceil((license.dateTo - nowMs) / (24 * 60 * 60 * 1000));
                      return (
                        <div key={license._id} className="rounded-md border p-3">
                          <div className="flex items-center justify-between gap-3">
                            <div>
                              <p className="font-medium">{license.category}</p>
                              <p className="text-xs text-muted-foreground">{license.propertyLabel}</p>
                            </div>
                            <Badge variant={days <= 14 ? "destructive" : "outline"}>
                              {days < 0 ? `${Math.abs(days)}d overdue` : `${days}d left`}
                            </Badge>
                          </div>
                          <p className="mt-1 text-xs text-muted-foreground">
                            Expires {formatDate(license.dateTo)}
                          </p>
                        </div>
                      );
                    })
                  )}
                </CardContent>
              </Card>
            </section>

            {properties.length === 0 ? (
              <Card>
                <CardContent className="py-10 text-center">
                  <AlertTriangle className="h-6 w-6 mx-auto mb-2 text-amber-500" />
                  <p className="text-sm text-muted-foreground">
                    No properties found for this account yet. Seed data or add properties in Convex.
                  </p>
                </CardContent>
              </Card>
            ) : null}
          </>
        ) : null}
      </div>
    </PageLayout>
  );
}

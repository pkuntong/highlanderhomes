import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Wrench, Clock, CheckCircle, AlertTriangle } from "lucide-react";

export default function MaintenanceStats({ requests }) {
  const totalRequests = requests.length;
  const pendingRequests = requests.filter(r => r.status === 'pending').length;
  const inProgressRequests = requests.filter(r => r.status === 'in-progress').length;
  const completedRequests = requests.filter(r => r.status === 'completed').length;

  const urgentRequests = requests.filter(r => r.priority === 'high' && r.status !== 'completed').length;

  const avgResolutionTime = () => {
    const completed = requests.filter(r => r.status === 'completed' && r.completedAt && r.createdAt);
    if (completed.length === 0) return 0;

    const totalDays = completed.reduce((sum, r) => {
      const start = new Date(r.createdAt);
      const end = new Date(r.completedAt);
      const days = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
      return sum + days;
    }, 0);

    return Math.round(totalDays / completed.length);
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Total Requests</CardTitle>
          <Wrench className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{totalRequests}</div>
          <div className="flex gap-2 mt-2">
            <Badge variant="secondary" className="text-xs">
              {pendingRequests} pending
            </Badge>
            <Badge variant="warning" className="text-xs">
              {inProgressRequests} active
            </Badge>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Urgent Items</CardTitle>
          <AlertTriangle className="h-4 w-4 text-red-500" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-red-600">{urgentRequests}</div>
          <p className="text-xs text-muted-foreground mt-2">
            Requires immediate attention
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Completed</CardTitle>
          <CheckCircle className="h-4 w-4 text-green-500" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-green-600">{completedRequests}</div>
          <p className="text-xs text-muted-foreground mt-2">
            {totalRequests > 0 ? Math.round((completedRequests / totalRequests) * 100) : 0}% completion rate
          </p>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Avg Resolution</CardTitle>
          <Clock className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold">{avgResolutionTime()}</div>
          <p className="text-xs text-muted-foreground mt-2">
            Days to complete
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

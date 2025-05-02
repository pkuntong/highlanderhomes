
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { MaintenanceLog } from "@/types";

interface MaintenanceStatusProps {
  maintenanceLogs: MaintenanceLog[];
}

const MaintenanceStatus = ({ maintenanceLogs }: MaintenanceStatusProps) => {
  const getStatusColor = (status: string) => {
    switch (status) {
      case "completed":
        return "bg-green-100 text-green-800";
      case "in-progress":
        return "bg-blue-100 text-blue-800";
      case "pending":
        return "bg-yellow-100 text-yellow-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle>Maintenance Status</CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        <div className="space-y-1">
          {maintenanceLogs.length > 0 ? (
            maintenanceLogs.map((log) => (
              <div
                key={log.id}
                className="flex items-center p-3 border-b last:border-0 hover:bg-gray-50"
              >
                <div className="flex-1">
                  <p className="text-sm font-medium">{log.title}</p>
                  <p className="text-xs text-gray-500">Cost: ${log.cost}</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`text-xs px-2 py-1 rounded-full font-medium ${getStatusColor(log.status)}`}>
                    {log.status.charAt(0).toUpperCase() + log.status.slice(1)}
                  </span>
                  <span className="text-xs font-medium">{formatDate(log.date)}</span>
                </div>
              </div>
            ))
          ) : (
            <p className="text-center py-4 text-gray-500">No maintenance logs</p>
          )}
        </div>
      </CardContent>
    </Card>
  );
};

export default MaintenanceStatus;

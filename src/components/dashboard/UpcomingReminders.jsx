import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Calendar, Bell, Key } from "lucide-react";

const UpcomingReminders = ({ reminders }) => {
  const getReminderIcon = (category) => {
    switch (category) {
      case "lease":
        return <Key className="h-4 w-4" />;
      case "rent":
        return <Bell className="h-4 w-4" />;
      default:
        return <Calendar className="h-4 w-4" />;
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle>Upcoming Reminders</CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        <div className="space-y-1">
          {reminders.length > 0 ? (
            reminders.map((reminder) => (
              <div
                key={reminder.id}
                className="flex items-center p-3 border-b last:border-0 hover:bg-gray-50"
              >
                <div className="flex items-center justify-center w-8 h-8 rounded-full bg-highlander-100 text-highlander-700 mr-3">
                  {getReminderIcon(reminder.category)}
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium">{reminder.title}</p>
                  <p className="text-xs text-gray-500">{reminder.description}</p>
                </div>
                <div className="text-xs font-medium">{formatDate(reminder.date)}</div>
              </div>
            ))
          ) : (
            <p className="text-center py-4 text-gray-500">No upcoming reminders</p>
          )}
        </div>
      </CardContent>
    </Card>
  );
};

export default UpcomingReminders;

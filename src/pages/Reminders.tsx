
import { useState } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Bell, Plus, Calendar as CalendarIcon, Key, Wrench } from "lucide-react";
import { reminders } from "@/data/mockData";

const Reminders = () => {
  const [filter, setFilter] = useState<string>("all");
  
  const filterReminders = () => {
    if (filter === "all") return reminders;
    return reminders.filter(reminder => reminder.category === filter);
  };
  
  const getReminderIcon = (category: string) => {
    switch (category) {
      case "lease":
        return <Key className="h-5 w-5" />;
      case "rent":
        return <Bell className="h-5 w-5" />;
      case "maintenance":
        return <Wrench className="h-5 w-5" />;
      default:
        return <CalendarIcon className="h-5 w-5" />;
    }
  };
  
  const filteredReminders = filterReminders();

  return (
    <PageLayout title="Reminders">
      <div className="mb-6 flex flex-col md:flex-row gap-4 md:justify-between md:items-center">
        <div className="flex gap-2">
          <Button 
            variant={filter === "all" ? "default" : "outline"} 
            onClick={() => setFilter("all")}
          >
            All
          </Button>
          <Button 
            variant={filter === "rent" ? "default" : "outline"} 
            onClick={() => setFilter("rent")}
          >
            Rent
          </Button>
          <Button 
            variant={filter === "lease" ? "default" : "outline"} 
            onClick={() => setFilter("lease")}
          >
            Lease
          </Button>
          <Button 
            variant={filter === "maintenance" ? "default" : "outline"} 
            onClick={() => setFilter("maintenance")}
          >
            Maintenance
          </Button>
        </div>
        <Button>
          <Plus className="mr-2 h-4 w-4" /> New Reminder
        </Button>
      </div>

      <div className="grid gap-4">
        {filteredReminders.length > 0 ? (
          filteredReminders.map((reminder) => (
            <Card key={reminder.id}>
              <CardContent className="p-4 flex items-center">
                <div className="flex items-center justify-center w-10 h-10 rounded-full bg-highlander-100 text-highlander-700 mr-4">
                  {getReminderIcon(reminder.category)}
                </div>
                <div className="flex-1">
                  <h3 className="font-medium">{reminder.title}</h3>
                  <p className="text-sm text-gray-500">{reminder.description}</p>
                </div>
                <div className="text-right">
                  <div className="font-medium">
                    {new Date(reminder.date).toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric'
                    })}
                  </div>
                  <div className={`text-xs ${
                    reminder.status === "pending" ? "text-highlander-700" : "text-gray-500"
                  }`}>
                    {reminder.status.charAt(0).toUpperCase() + reminder.status.slice(1)}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        ) : (
          <Card>
            <CardContent className="p-12 text-center">
              <Bell className="h-10 w-10 mx-auto text-gray-400 mb-4" />
              <h3 className="text-lg font-medium mb-2">No reminders found</h3>
              <p className="text-gray-500 mb-4">
                Create reminders to stay on top of important dates
              </p>
              <Button>
                <Plus className="mr-2 h-4 w-4" /> New Reminder
              </Button>
            </CardContent>
          </Card>
        )}
      </div>
    </PageLayout>
  );
};

export default Reminders;

import { useState } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Calendar as CalendarComponent } from "@/components/ui/calendar";
import { Card, CardContent } from "@/components/ui/card";
import { Bell, Calendar as CalendarIcon, Key, Wrench } from "lucide-react";

const LOCAL_STORAGE_KEY = "highlanderhomes_reminders";

const Calendar = () => {
  const [date, setDate] = useState(new Date());
  const [reminders] = useState(() => {
    const stored = localStorage.getItem(LOCAL_STORAGE_KEY);
    return stored ? JSON.parse(stored) : [];
  });

  // Group reminders by date
  const remindersByDate = reminders.reduce((acc, reminder) => {
    const dateKey = reminder.date;
    if (!acc[dateKey]) {
      acc[dateKey] = [];
    }
    acc[dateKey].push(reminder);
    return acc;
  }, {});

  const selectedDateReminders = date
    ? remindersByDate[
        date.toISOString().split('T')[0]
      ] || []
    : [];

  const getReminderIcon = (category) => {
    switch (category) {
      case "lease":
        return <Key className="h-4 w-4" />;
      case "rent":
        return <Bell className="h-4 w-4" />;
      case "maintenance":
        return <Wrench className="h-4 w-4" />;
      default:
        return <CalendarIcon className="h-4 w-4" />;
    }
  };

  return (
    <PageLayout title="Calendar">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-1">
          <CardContent className="p-4">
            <CalendarComponent
              mode="single"
              selected={date}
              onSelect={setDate}
              className="p-3 pointer-events-auto"
              modifiers={{
                highlighted: Object.keys(remindersByDate).map((dateStr) => new Date(dateStr)),
              }}
              modifiersStyles={{
                highlighted: {
                  backgroundColor: 'rgba(59, 130, 246, 0.1)',
                  fontWeight: 'bold',
                }
              }}
            />
          </CardContent>
        </Card>

        <div className="lg:col-span-2">
          <h2 className="text-lg font-semibold mb-4">
            {date
              ? `Reminders for ${date.toLocaleDateString("en-US", {
                  month: "long",
                  day: "numeric",
                  year: "numeric",
                })}`
              : "Select a date to view reminders"}
          </h2>

          {selectedDateReminders.length > 0 ? (
            <div className="space-y-4">
              {selectedDateReminders.map((reminder) => (
                <Card key={reminder.id}>
                  <CardContent className="p-4">
                    <div className="flex gap-3">
                      <div className="flex items-center justify-center w-10 h-10 rounded-full bg-highlander-100 text-highlander-700">
                        {getReminderIcon(reminder.category)}
                      </div>
                      <div>
                        <h3 className="font-medium">{reminder.title}</h3>
                        <p className="text-sm text-gray-500">
                          {reminder.description}
                        </p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : (
            <Card>
              <CardContent className="p-6 text-center">
                <CalendarIcon className="mx-auto h-8 w-8 text-gray-400 mb-2" />
                <p className="text-gray-500">No reminders for this date</p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </PageLayout>
  );
};

export default Calendar;

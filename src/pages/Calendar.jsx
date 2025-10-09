import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Calendar as CalendarComponent } from "@/components/ui/calendar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Bell, Calendar as CalendarIcon, Key, Wrench, Plus, X } from "lucide-react";
import { db } from "@/firebase";
import { collection, getDocs, addDoc } from "firebase/firestore";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

const Calendar = () => {
  const [date, setDate] = useState(new Date());
  const [reminders, setReminders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isAddingReminder, setIsAddingReminder] = useState(false);
  const [reminderForm, setReminderForm] = useState({
    title: "",
    description: "",
    category: "general",
    date: ""
  });

  // Fetch reminders from Firestore on mount
  useEffect(() => {
    fetchReminders();
  }, []);

  async function fetchReminders() {
    setLoading(true);
    const querySnapshot = await getDocs(collection(db, "reminders"));
    const remindersData = querySnapshot.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() }));
    setReminders(remindersData);
    setLoading(false);
  }

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

  const handleAddReminder = async (e) => {
    e.preventDefault();
    try {
      await addDoc(collection(db, "reminders"), {
        ...reminderForm,
        status: "pending",
        createdAt: new Date().toISOString()
      });
      setReminderForm({ title: "", description: "", category: "general", date: "" });
      setIsAddingReminder(false);
      fetchReminders();
    } catch (error) {
      console.error("Error adding reminder:", error);
      alert("Failed to add reminder");
    }
  };

  const handleDateSelect = (selectedDate) => {
    setDate(selectedDate);
    if (selectedDate) {
      setReminderForm(prev => ({
        ...prev,
        date: selectedDate.toISOString().split('T')[0]
      }));
    }
  };

  if (loading) return <div>Loading reminders...</div>;

  return (
    <PageLayout title="Calendar">
      <div className="mb-4 flex justify-between items-center">
        <Button
          onClick={() => {
            setIsAddingReminder(true);
            if (date) {
              setReminderForm(prev => ({
                ...prev,
                date: date.toISOString().split('T')[0]
              }));
            }
          }}
          className="flex items-center gap-2"
        >
          <Plus className="h-4 w-4" />
          Add Reminder
        </Button>
        <Button onClick={fetchReminders} variant="outline">Refresh</Button>
      </div>
      {/* Add Reminder Form */}
      {isAddingReminder && (
        <Card className="mb-6">
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>Add New Reminder</CardTitle>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setIsAddingReminder(false)}
            >
              <X className="h-4 w-4" />
            </Button>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleAddReminder} className="space-y-4">
              <div>
                <label className="text-sm font-medium">Title</label>
                <Input
                  value={reminderForm.title}
                  onChange={(e) => setReminderForm({ ...reminderForm, title: e.target.value })}
                  placeholder="Enter reminder title"
                  required
                />
              </div>
              <div>
                <label className="text-sm font-medium">Description</label>
                <Textarea
                  value={reminderForm.description}
                  onChange={(e) => setReminderForm({ ...reminderForm, description: e.target.value })}
                  placeholder="Enter description (optional)"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Category</label>
                <Select
                  value={reminderForm.category}
                  onValueChange={(value) => setReminderForm({ ...reminderForm, category: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="general">General</SelectItem>
                    <SelectItem value="lease">Lease</SelectItem>
                    <SelectItem value="rent">Rent</SelectItem>
                    <SelectItem value="maintenance">Maintenance</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div>
                <label className="text-sm font-medium">Date</label>
                <Input
                  type="date"
                  value={reminderForm.date}
                  onChange={(e) => setReminderForm({ ...reminderForm, date: e.target.value })}
                  required
                />
              </div>
              <div className="flex gap-2">
                <Button type="submit">Add Reminder</Button>
                <Button type="button" variant="outline" onClick={() => setIsAddingReminder(false)}>
                  Cancel
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-1">
          <CardContent className="p-4">
            <CalendarComponent
              mode="single"
              selected={date}
              onSelect={handleDateSelect}
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

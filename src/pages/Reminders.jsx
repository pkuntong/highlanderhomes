import { useState, useEffect } from "react";
import PageLayout from "@/components/layout/PageLayout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Bell, Plus, Calendar as CalendarIcon, Key, Wrench, Edit, Trash2 } from "lucide-react";
import { reminders as mockReminders } from "@/data/mockData";

const LOCAL_STORAGE_KEY = "highlanderhomes_reminders";

const emptyReminder = {
  id: '',
  propertyId: '',
  tenantId: '',
  title: '',
  description: '',
  date: '',
  category: 'other',
  status: 'pending',
};

const Reminders = () => {
  const [reminders, setReminders] = useState(() => {
    const stored = localStorage.getItem(LOCAL_STORAGE_KEY);
    return stored ? JSON.parse(stored) : mockReminders;
  });
  const [filter, setFilter] = useState("all");
  const [isEditing, setIsEditing] = useState(false);
  const [editIndex, setEditIndex] = useState(null);
  const [form, setForm] = useState(emptyReminder);

  useEffect(() => {
    localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(reminders));
  }, [reminders]);

  const filterReminders = () => {
    if (filter === "all") return reminders;
    return reminders.filter(reminder => reminder.category === filter);
  };

  const getReminderIcon = (category) => {
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

  const handleEdit = (index) => {
    setEditIndex(index);
    setForm(reminders[index]);
    setIsEditing(true);
  };

  const handleDelete = (index) => {
    if (window.confirm("Are you sure you want to delete this reminder?")) {
      setReminders((prev) => prev.filter((_, i) => i !== index));
    }
  };

  const handleAdd = () => {
    setEditIndex(null);
    setForm({ ...emptyReminder, id: Date.now().toString() });
    setIsEditing(true);
  };

  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleFormSubmit = (e) => {
    e.preventDefault();
    if (editIndex !== null) {
      setReminders((prev) => prev.map((r, i) => (i === editIndex ? form : r)));
    } else {
      setReminders((prev) => [...prev, form]);
    }
    setIsEditing(false);
    setForm(emptyReminder);
    setEditIndex(null);
  };

  const handleCancel = () => {
    setIsEditing(false);
    setForm(emptyReminder);
    setEditIndex(null);
  };

  const filteredReminders = filterReminders();

  return (
    <PageLayout title="Reminders">
      <div className="mb-6 flex justify-between items-center">
        <h2 className="text-lg font-semibold">Reminders</h2>
        <Button onClick={handleAdd}>
          <Plus className="mr-2 h-4 w-4" /> New Reminder
        </Button>
      </div>

      {isEditing && (
        <form onSubmit={handleFormSubmit} className="mb-6 p-4 border rounded bg-gray-50">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="title">Title</label>
              <Input name="title" id="title" value={form.title} onChange={handleFormChange} placeholder="Reminder Title" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="date">Date</label>
              <Input name="date" id="date" value={form.date} onChange={handleFormChange} placeholder="YYYY-MM-DD" type="date" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1" htmlFor="category">Category</label>
              <select name="category" id="category" value={form.category} onChange={handleFormChange} className="border rounded px-2 py-1 w-full">
                <option value="lease">Lease</option>
                <option value="rent">Rent</option>
                <option value="insurance">Insurance</option>
                <option value="license">License</option>
                <option value="maintenance">Maintenance</option>
                <option value="other">Other</option>
              </select>
            </div>
            <div className="md:col-span-2">
              <label className="block text-sm font-medium mb-1" htmlFor="description">Description</label>
              <Input name="description" id="description" value={form.description} onChange={handleFormChange} placeholder="Description" />
            </div>
          </div>
          <div className="flex gap-2 mt-4 justify-end">
            <Button variant="outline" type="button" onClick={handleCancel}>Cancel</Button>
            <Button type="submit">{editIndex !== null ? "Update" : "Add"} Reminder</Button>
          </div>
        </form>
      )}

      {filteredReminders.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredReminders.map((reminder, idx) => (
            <Card key={reminder.id} className="relative group hover:bg-gray-50">
              <CardContent className="p-4 flex items-center">
                <div className="p-3 bg-highlander-100 rounded-lg mr-3">
                  {getReminderIcon(reminder.category)}
                </div>
                <div className="flex-1">
                  <h3 className="font-medium">{reminder.title}</h3>
                  <div className="flex flex-col mt-2 text-xs text-gray-500">
                    <span>{reminder.date}</span>
                    <span>Category: {reminder.category}</span>
                    <span>Status: {reminder.status}</span>
                  </div>
                  {reminder.description && <div className="mt-1 text-xs text-gray-400">{reminder.description}</div>}
                </div>
                <div className="absolute top-2 right-2 flex gap-2 opacity-0 group-hover:opacity-100 transition">
                  <Button size="icon" variant="outline" onClick={() => handleEdit(idx)}><Edit className="h-4 w-4" /></Button>
                  <Button size="icon" variant="destructive" onClick={() => handleDelete(idx)}><Trash2 className="h-4 w-4" /></Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="p-12 text-center">
            <Bell className="h-10 w-10 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-medium mb-2">No reminders yet</h3>
            <p className="text-gray-500 mb-4">
              Add reminders to keep track of important dates and tasks
            </p>
            <Button onClick={handleAdd}>
              <Plus className="mr-2 h-4 w-4" /> New Reminder
            </Button>
          </CardContent>
        </Card>
      )}
    </PageLayout>
  );
};

export default Reminders;

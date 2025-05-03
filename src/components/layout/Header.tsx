import { useState } from "react";
import { Bell, LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useAuth } from "@/contexts/AuthContext";
import { useNavigate } from "react-router-dom";
import { Reminder } from "@/types";

interface HeaderProps {
  title: string;
}

const LOCAL_STORAGE_KEY = "highlanderhomes_reminders";

const Header = ({ title }: HeaderProps) => {
  const { logout } = useAuth();
  const navigate = useNavigate();
  
  const [reminders] = useState<Reminder[]>(() => {
    const stored = localStorage.getItem(LOCAL_STORAGE_KEY);
    return stored ? JSON.parse(stored) : [];
  });

  // Get upcoming reminders (next 7 days)
  const upcomingReminders = reminders
    .filter(reminder => {
      const reminderDate = new Date(reminder.date);
      const today = new Date();
      const nextWeek = new Date();
      nextWeek.setDate(today.getDate() + 7);
      return reminderDate >= today && reminderDate <= nextWeek && reminder.status === "pending";
    })
    .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

  const handleLogout = () => {
    logout();
    navigate("/");
  };

  const handleReminderClick = (reminder: Reminder) => {
    navigate("/reminders");
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  return (
    <header className="py-4 border-b border-gray-200">
      <div className="flex justify-between items-center px-6">
        <h1 className="text-2xl font-semibold text-gray-800">{title}</h1>
        
        <div className="flex items-center gap-4">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" className="relative">
                <Bell className="h-5 w-5" />
                {upcomingReminders.length > 0 && (
                  <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs w-5 h-5 flex items-center justify-center rounded-full">
                    {upcomingReminders.length}
                  </span>
                )}
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent className="w-80" align="end">
              <DropdownMenuLabel>Upcoming Reminders</DropdownMenuLabel>
              <DropdownMenuSeparator />
              {upcomingReminders.length > 0 ? (
                upcomingReminders.map((reminder) => (
                  <DropdownMenuItem 
                    key={reminder.id} 
                    className="py-2 cursor-pointer hover:bg-gray-100"
                    onClick={() => handleReminderClick(reminder)}
                  >
                    <div className="flex flex-col">
                      <span className="font-medium">{reminder.title}</span>
                      <span className="text-sm text-gray-500">{reminder.description}</span>
                      <span className="text-xs text-gray-400 mt-1">
                        Due: {formatDate(reminder.date)}
                      </span>
                    </div>
                  </DropdownMenuItem>
                ))
              ) : (
                <DropdownMenuItem className="py-2 text-gray-500">
                  No upcoming reminders
                </DropdownMenuItem>
              )}
            </DropdownMenuContent>
          </DropdownMenu>
          
          <Button 
            variant="outline" 
            size="sm" 
            className="flex items-center gap-2"
            onClick={handleLogout}
          >
            <LogOut className="h-4 w-4" />
            Logout
          </Button>
        </div>
      </div>
    </header>
  );
};

export default Header;

import { useState, useEffect } from "react";
import { Bell, LogOut, Settings } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { ThemeToggle } from "@/components/ui/theme-toggle";

const Header = ({ title }) => {
  const navigate = useNavigate();
  const { logout } = useAuth();
  const [reminders, setReminders] = useState([]);

  useEffect(() => {
    const stored = localStorage.getItem("highlanderhomes_reminders");
    if (stored) {
      const parsed = JSON.parse(stored);
      const pendingReminders = parsed.filter(r => r.status === "Pending");
      setReminders(pendingReminders);
    }
  }, []);

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <header className="sticky top-0 z-30 border-b bg-background">
      <div className="flex h-16 items-center px-4 md:px-6">
        <h1 className="text-lg font-semibold truncate ml-14 sm:ml-8 lg:ml-0">{title}</h1>
        <div className="ml-auto flex items-center space-x-2 md:space-x-4">
          {/* Theme Toggle Button */}
          <ThemeToggle />

          <Button
            variant="ghost"
            size="icon"
            className="relative"
            onClick={() => navigate("/reminders")}
          >
                <Bell className="h-5 w-5" />
            {reminders.length > 0 && (
              <span className="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] text-white pointer-events-none">
                {reminders.length}
                  </span>
                )}
              </Button>
          <Button
            variant="ghost"
            size="icon"
            onClick={() => navigate("/profile")}
          >
            <Settings className="h-5 w-5" />
          </Button>
          <Button 
            variant="ghost"
            size="icon"
            onClick={handleLogout}
          >
            <LogOut className="h-5 w-5" />
          </Button>
        </div>
      </div>
    </header>
  );
};

export default Header;

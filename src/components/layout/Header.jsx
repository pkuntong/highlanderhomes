import { useState, useEffect } from "react";
import { Bell, LogOut, Settings } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";

const Header = ({ title }) => {
  const navigate = useNavigate();
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
    localStorage.removeItem("highlanderhomes_auth");
    navigate("/login");
  };

  return (
    <header className="border-b bg-background">
      <div className="flex h-16 items-center px-4">
        <h1 className="text-lg font-semibold">{title}</h1>
        <div className="ml-auto flex items-center space-x-4">
          <Button
            variant="ghost"
            size="icon"
            className="relative"
            onClick={() => navigate("/reminders")}
          >
            <Bell className="h-5 w-5" />
            {reminders.length > 0 && (
              <span className="absolute -top-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] text-white">
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

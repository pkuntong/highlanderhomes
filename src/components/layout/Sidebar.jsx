import { Link, useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";
import { 
  Building, 
  FileText, 
  Calendar, 
  Bell, 
  ChartBar, 
  User,
  LayoutDashboard,
  Users,
  Menu,
  X
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { useState } from "react";

const sidebarItems = [
  { 
    name: "Dashboard", 
    path: "/", 
    icon: <LayoutDashboard className="mr-2 h-5 w-5" /> 
  },
  { 
    name: "Properties", 
    path: "/properties", 
    icon: <Building className="mr-2 h-5 w-5" /> 
  },
  { 
    name: "Tenants", 
    path: "/tenants", 
    icon: <Users className="mr-2 h-5 w-5" /> 
  },
  { 
    name: "Documents", 
    path: "/documents", 
    icon: <FileText className="mr-2 h-5 w-5" /> 
  },
  { 
    name: "Calendar", 
    path: "/calendar", 
    icon: <Calendar className="mr-2 h-5 w-5" /> 
  },
  { 
    name: "Reminders", 
    path: "/reminders", 
    icon: <Bell className="mr-2 h-5 w-5" /> 
  },
  { 
    name: "Analytics", 
    path: "/analytics", 
    icon: <ChartBar className="mr-2 h-5 w-5" /> 
  },
  { 
    name: "Profile", 
    path: "/profile", 
    icon: <User className="mr-2 h-5 w-5" /> 
  }
];

const Sidebar = () => {
  const location = useLocation();
  const [isOpen, setIsOpen] = useState(false);
  
  return (
    <>
      {/* Mobile menu button */}
      <Button
        variant="ghost"
        size="icon"
        className="lg:hidden fixed top-4 left-4 z-50"
        onClick={() => setIsOpen(!isOpen)}
      >
        {isOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
      </Button>

      {/* Sidebar */}
      <div className={cn(
        "fixed inset-y-0 left-0 z-40 w-64 transform bg-sidebar border-r border-gray-200 transition-transform duration-200 ease-in-out lg:translate-x-0",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        <div className="h-full flex flex-col p-4">
          <div className="mb-8 px-2">
            <h1 className="text-2xl font-bold text-highlander-700">Highlander Homes</h1>
          </div>
          
          <div className="space-y-1">
            {sidebarItems.map((item) => (
              <Link 
                key={item.path} 
                to={item.path}
                onClick={() => setIsOpen(false)}
              >
                <Button
                  variant="ghost"
                  className={cn(
                    "w-full justify-start text-left font-normal",
                    location.pathname === item.path
                      ? "bg-highlander-100 text-highlander-700"
                      : "text-muted-foreground hover:bg-highlander-50 hover:text-highlander-700"
                  )}
                >
                  {item.icon}
                  {item.name}
                </Button>
              </Link>
            ))}
          </div>
        </div>
      </div>

      {/* Overlay for mobile */}
      {isOpen && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 z-30 lg:hidden"
          onClick={() => setIsOpen(false)}
        />
      )}
    </>
  );
};

export default Sidebar;

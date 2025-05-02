
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
  Users
} from "lucide-react";
import { Button } from "@/components/ui/button";

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
  
  return (
    <div className="w-64 h-screen border-r border-gray-200 p-4 flex flex-col bg-sidebar">
      <div className="mb-8 px-2">
        <h1 className="text-2xl font-bold text-highlander-700">Highlander Homes</h1>
      </div>
      
      <div className="space-y-1">
        {sidebarItems.map((item) => (
          <Link key={item.path} to={item.path}>
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
  );
};

export default Sidebar;

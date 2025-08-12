import React from "react";
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
  X,
  Wrench,
  DollarSign,
  Sparkles
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { useState, useEffect } from "react";

const sidebarItems = [
  { 
    name: "Dashboard", 
    path: "/dashboard", 
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
    name: "Rent Tracking", 
    path: "/rent-tracking", 
    icon: <DollarSign className="mr-2 h-5 w-5" /> 
  },
  { 
    name: "Maintenance", 
    path: "/maintenance", 
    icon: <Wrench className="mr-2 h-5 w-5" /> 
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
  const [hoveredItem, setHoveredItem] = useState(null);
  
  return (
    <>
      {/* Premium Mobile menu button */}
      <Button
        variant="glass"
        size="icon"
        className="lg:hidden fixed top-4 left-4 z-50 h-12 w-12 touch-manipulation glass border-border-subtle hover:scale-110 transition-all duration-300"
        onClick={() => setIsOpen(!isOpen)}
      >
        {isOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
      </Button>

      {/* Premium Sidebar */}
      <div className={cn(
        "fixed inset-y-0 left-0 z-40 w-72 transform transition-all duration-500 ease-out lg:translate-x-0",
        "bg-gradient-to-b from-sidebar/95 via-sidebar/90 to-sidebar/95 backdrop-blur-premium",
        "border-r border-sidebar-border shadow-premium",
        isOpen ? "translate-x-0" : "-translate-x-full"
      )}>
        {/* Premium background effects */}
        <div className="absolute inset-0 bg-gradient-to-br from-primary/5 via-transparent to-accent-rose/5 pointer-events-none" />
        <div className="absolute top-0 left-0 w-full h-32 bg-gradient-to-b from-primary/10 to-transparent pointer-events-none" />
        
        <div className="relative h-full flex flex-col p-6">
          {/* Premium Logo Section */}
          <div className="mb-12 px-2">
            <div className="flex items-center gap-3 mt-12 lg:mt-4">
              <Link 
                to="/" 
                onClick={() => setIsOpen(false)} 
                className="flex items-center gap-3 group"
              >
                <div className="relative">
                  <img 
                    src="/HH Logo.png" 
                    alt="Highlander Homes Logo" 
                    className="h-12 w-auto transition-transform duration-300 group-hover:scale-110" 
                  />
                  <div className="absolute inset-0 bg-gradient-to-br from-primary/20 to-accent-rose/20 rounded-lg blur-lg opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                </div>
                <div>
                  <h1 className="text-xl font-bold text-gradient">
                    Highlander Homes
                  </h1>
                  <p className="text-xs text-foreground-muted font-medium">
                    Premium Property Management
                  </p>
                </div>
              </Link>
            </div>
          </div>
          
          {/* Premium Navigation */}
          <nav className="flex-1 space-y-2">
            {sidebarItems.map((item, index) => {
              const isActive = location.pathname === item.path;
              const isHovered = hoveredItem === item.path;
              
              return (
                <div 
                  key={item.path}
                  className="animate-slide-up"
                  style={{ animationDelay: `${index * 0.05}s` }}
                >
                  <Link 
                    to={item.path}
                    onClick={() => setIsOpen(false)}
                    onMouseEnter={() => setHoveredItem(item.path)}
                    onMouseLeave={() => setHoveredItem(null)}
                  >
                    <div className={cn(
                      "relative group w-full flex items-center justify-start p-4 rounded-xl transition-all duration-300 font-medium touch-manipulation",
                      "hover:scale-105 hover:shadow-md active:scale-95",
                      isActive
                        ? "bg-gradient-to-r from-primary to-primary-600 text-primary-foreground shadow-glow"
                        : "text-sidebar-foreground hover:bg-sidebar-accent/50 hover:text-sidebar-accent-foreground"
                    )}>
                      {/* Active indicator */}
                      {isActive && (
                        <div className="absolute inset-0 bg-gradient-to-r from-primary via-accent-rose to-primary rounded-xl opacity-20 animate-gradient-x" />
                      )}
                      
                      {/* Icon with animation */}
                      <div className={cn(
                        "flex items-center justify-center w-6 h-6 mr-4 transition-all duration-300",
                        isActive && "text-primary-foreground",
                        isHovered && !isActive && "scale-110 text-primary"
                      )}>
                        {React.cloneElement(item.icon, { 
                          className: "h-5 w-5",
                          strokeWidth: isActive ? 2.5 : 2
                        })}
                      </div>
                      
                      {/* Text */}
                      <span className={cn(
                        "text-sm tracking-wide transition-all duration-300",
                        isActive && "font-semibold"
                      )}>
                        {item.name}
                      </span>
                      
                      {/* Premium accent for active item */}
                      {isActive && (
                        <div className="ml-auto">
                          <Sparkles className="h-4 w-4 text-primary-foreground animate-pulse" />
                        </div>
                      )}
                      
                      {/* Hover effect */}
                      {isHovered && !isActive && (
                        <div className="absolute right-3 w-2 h-2 bg-primary rounded-full animate-bounce" />
                      )}
                    </div>
                  </Link>
                </div>
              );
            })}
          </nav>
          
          {/* Premium Footer */}
          <div className="mt-8 p-4 glass rounded-2xl">
            <div className="text-center space-y-2">
              <p className="text-xs text-foreground-muted font-medium">
                Premium Experience
              </p>
              <div className="flex justify-center">
                <div className="flex space-x-1">
                  {[...Array(5)].map((_, i) => (
                    <div
                      key={i}
                      className="w-1.5 h-1.5 bg-primary rounded-full animate-pulse"
                      style={{ animationDelay: `${i * 0.2}s` }}
                    />
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Premium Overlay for mobile */}
      {isOpen && (
        <div 
          className="fixed inset-0 bg-black/50 backdrop-blur-sm z-30 lg:hidden transition-all duration-500"
          onClick={() => setIsOpen(false)}
        />
      )}
    </>
  );
};

export default Sidebar;

import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import {
  Building2,
  DollarSign,
  LayoutDashboard,
  Menu,
  User,
  Wrench,
  X,
  Handshake,
  FileText,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const navItems = [
  { path: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { path: "/properties", label: "Properties", icon: Building2 },
  { path: "/maintenance", label: "Maintenance", icon: Wrench },
  { path: "/finance", label: "Finance", icon: DollarSign },
  { path: "/documents", label: "Documents", icon: FileText },
  { path: "/contractors", label: "Contractors", icon: Handshake },
  { path: "/profile", label: "Profile", icon: User },
];

const IOS_APP_URL =
  import.meta.env.VITE_IOS_APP_URL || "https://apps.apple.com/us/app/highlander-homes/id6758958500";

export default function Sidebar() {
  const [open, setOpen] = useState(false);
  const location = useLocation();

  return (
    <>
      <Button
        type="button"
        size="icon"
        variant="outline"
        className="fixed left-4 top-4 z-50 lg:hidden"
        onClick={() => setOpen((prev) => !prev)}
      >
        {open ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
      </Button>

      <aside
        className={cn(
          "fixed left-0 top-0 z-40 h-screen w-72 border-r bg-background transition-transform lg:translate-x-0",
          open ? "translate-x-0" : "-translate-x-full"
        )}
      >
        <div className="h-full flex flex-col">
          <div className="border-b px-5 py-5">
            <Link to="/dashboard" className="flex items-center gap-3" onClick={() => setOpen(false)}>
              <img src="/HH Logo.png" alt="Highlander Homes" className="h-10 w-10 object-contain" />
              <div>
                <p className="font-semibold leading-tight">Highlander Homes</p>
                <p className="text-xs text-muted-foreground">Web Console</p>
              </div>
            </Link>
          </div>

          <nav className="flex-1 overflow-y-auto p-3 space-y-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              const active = location.pathname === item.path;
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  onClick={() => setOpen(false)}
                  className={cn(
                    "flex items-center gap-3 rounded-lg px-3 py-2 text-sm",
                    active
                      ? "bg-primary text-primary-foreground"
                      : "text-muted-foreground hover:bg-muted hover:text-foreground"
                  )}
                >
                  <Icon className="h-4 w-4" />
                  <span>{item.label}</span>
                </Link>
              );
            })}
          </nav>

          <div className="border-t p-4 text-xs text-muted-foreground space-y-3">
            <div>
              <p>Need help?</p>
              <a
                href="mailto:highlanderhomes22@gmail.com"
                className="text-primary underline underline-offset-4"
              >
                highlanderhomes22@gmail.com
              </a>
            </div>
            <a
              href={IOS_APP_URL}
              target="_blank"
              rel="noreferrer"
              className="inline-flex items-center gap-2 rounded-md bg-black px-3 py-1.5 text-white hover:bg-black/90"
            >
              <span aria-hidden></span>
              App Store
            </a>
          </div>
        </div>
      </aside>

      {open ? (
        <button
          type="button"
          className="fixed inset-0 z-30 bg-black/40 lg:hidden"
          onClick={() => setOpen(false)}
          aria-label="Close sidebar"
        />
      ) : null}
    </>
  );
}

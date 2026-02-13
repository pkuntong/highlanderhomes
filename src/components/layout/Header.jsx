import { LogOut, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ThemeToggle } from "@/components/ui/theme-toggle";
import { useAuth } from "@/contexts/AuthContext";

export default function Header({ title, onRefresh, isRefreshing = false }) {
  const { currentUser, logout } = useAuth();

  return (
    <header className="sticky top-0 z-30 border-b bg-background/95 backdrop-blur">
      <div className="flex h-14 items-center gap-3 px-4 lg:h-16 lg:px-6">
        <h1 className="ml-12 text-lg font-semibold lg:ml-0">{title}</h1>
        <div className="ml-auto flex items-center gap-2">
          {onRefresh ? (
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={onRefresh}
              disabled={isRefreshing}
              className="gap-2"
            >
              <RefreshCw className={`h-4 w-4 ${isRefreshing ? "animate-spin" : ""}`} />
              Refresh
            </Button>
          ) : null}

          <ThemeToggle />

          <div className="hidden text-right text-xs lg:block">
            <p className="font-medium text-foreground">{currentUser?.name || "Owner"}</p>
            <p className="text-muted-foreground">{currentUser?.email || ""}</p>
          </div>

          <Button type="button" variant="ghost" size="icon" onClick={logout}>
            <LogOut className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </header>
  );
}

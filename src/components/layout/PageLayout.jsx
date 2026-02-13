import Sidebar from "./Sidebar";
import Header from "./Header";
import { NetworkStatusIndicator } from "@/components/ui/network-status";
 
const PageLayout = ({ children, title, onRefresh, isRefreshing }) => {
  return (
    <div className="min-h-screen bg-slate-100 text-foreground dark:bg-slate-950">
      <Sidebar />
      <NetworkStatusIndicator />

      <div className="lg:pl-72 relative z-10">
        <Header title={title} onRefresh={onRefresh} isRefreshing={isRefreshing} />
        <main className="min-h-screen p-4 lg:p-6">
          <div className="mx-auto max-w-7xl">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
};

export default PageLayout;

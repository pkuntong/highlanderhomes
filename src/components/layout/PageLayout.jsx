import { ReactNode } from "react";
import Sidebar from "./Sidebar";
import Header from "./Header";
import { NetworkStatusIndicator } from "@/components/ui/network-status";
import { PageTransition } from "@/components/ui/mobile-animations";

const PageLayout = ({ children, title }) => {
  return (
    <div className="min-h-screen bg-premium">
      {/* Premium background pattern */}
      <div className="fixed inset-0 bg-gradient-to-br from-primary/5 via-transparent to-accent-rose/5 pointer-events-none" />
      <div className="fixed inset-0 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-primary/10 via-transparent to-transparent pointer-events-none" />
      
      <Sidebar />
      <NetworkStatusIndicator />
      
      <div className="lg:pl-72 relative z-10">
        <Header title={title} />
        <main className="padding-responsive min-h-screen">
          <div className="max-w-7xl mx-auto space-premium">
            <PageTransition>
              <div className="animate-fade-in">
                {children}
              </div>
            </PageTransition>
          </div>
          
          {/* Floating decoration elements */}
          <div className="fixed top-20 right-10 w-32 h-32 bg-gradient-to-br from-primary/10 to-accent-rose/10 rounded-full blur-3xl animate-float pointer-events-none hidden lg:block" />
          <div className="fixed bottom-20 left-20 w-40 h-40 bg-gradient-to-br from-accent-emerald/10 to-accent-gold/10 rounded-full blur-3xl animate-float pointer-events-none hidden lg:block" style={{ animationDelay: '2s' }} />
        </main>
      </div>
    </div>
  );
};

export default PageLayout;

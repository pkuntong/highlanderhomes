import { ReactNode } from "react";
import Sidebar from "./Sidebar";
import Header from "./Header";

const PageLayout = ({ children, title }) => {
  return (
    <div className="min-h-screen bg-background">
      <Sidebar />
      <div className="lg:pl-64">
        <Header title={title} />
        <main className="p-4 md:p-6">
          <div className="max-w-7xl mx-auto">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
};

export default PageLayout;

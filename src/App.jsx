
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import Index from "./pages/Index";
import Properties from "./pages/Properties";
import Profile from "./pages/Profile";
import MaintenanceRequests from "./pages/MaintenanceRequests";
import Finance from "./pages/Finance";
import Contractors from "./pages/Contractors";
import Documents from "./pages/Documents";
import NotFound from "./pages/NotFound";
import Login from "./pages/Login";
import Terms from "./pages/Terms";
import Privacy from "./pages/Privacy";
import Support from "./pages/Support";
import { AuthProvider } from "./contexts/AuthContext";
import ProtectedRoute from "./components/ProtectedRoute";
import { SpeedInsights } from "@vercel/speed-insights/react";
import React from "react";
import { ThemeProvider } from './contexts/ThemeContext';

const queryClient = new QueryClient();

const App = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <AuthProvider>
        <TooltipProvider>
          <Toaster />
          <Sonner />
        <BrowserRouter>
          <SpeedInsights />
        <Routes>
            {/* Public routes */}
            <Route path="/" element={<Index />} />
            <Route path="/login" element={<Login />} />
            <Route path="/terms" element={<Terms />} />
            <Route path="/privacy" element={<Privacy />} />
            <Route path="/support" element={<Support />} />
            
            {/* Protected routes */}
            <Route element={<ProtectedRoute />}>
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/properties" element={<Properties />} />
              <Route path="/maintenance" element={<MaintenanceRequests />} />
              <Route path="/finance" element={<Finance />} />
              <Route path="/documents" element={<Documents />} />
              <Route path="/contractors" element={<Contractors />} />
              <Route path="/profile" element={<Profile />} />
            </Route>

            {/* Catch all route */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
    </AuthProvider>
      </ThemeProvider>
  </QueryClientProvider>
  );
};

export default App;

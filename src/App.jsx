
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import Index from "./pages/Index";
import Properties from "./pages/Properties";
import Calendar from "./pages/Calendar";
import Documents from "./pages/Documents";
import Reminders from "./pages/Reminders";
import Analytics from "./pages/Analytics";
import Profile from "./pages/Profile";
import Tenants from "./pages/Tenants";
import NotFound from "./pages/NotFound";
import Login from "./pages/Login";
import { AuthProvider } from "./contexts/AuthContext";
import ProtectedRoute from "./components/ProtectedRoute";
import { SpeedInsights } from "@vercel/speed-insights/react";
// We'll initialize the admin setup utility after React mounts
// This prevents issues with Firebase initialization timing
import React, { useEffect } from 'react';

// Admin setup will be initialized dynamically during app startup

const queryClient = new QueryClient();

const App = () => {
  // Initialize setupAdmin utility after component mounts
  useEffect(() => {
    // Delay loading to ensure Firebase is initialized
    setTimeout(() => {
      try {
        // Dynamically import the setupAdmin utility
        import('./utils/setupAdmin')
          .then(() => console.log('Admin utility loaded successfully'))
          .catch(err => console.error('Error loading admin utility:', err));
      } catch (error) {
        console.error('Error importing setupAdmin:', error);
      }
    }, 2000); // 2-second delay for Firebase to initialize completely
  }, []);

  return (
    <QueryClientProvider client={queryClient}>
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
            
            {/* Protected routes */}
            <Route element={<ProtectedRoute />}>
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/properties" element={<Properties />} />
              <Route path="/documents" element={<Documents />} />
              <Route path="/calendar" element={<Calendar />} />
              <Route path="/reminders" element={<Reminders />} />
              <Route path="/analytics" element={<Analytics />} />
              <Route path="/profile" element={<Profile />} />
              <Route path="/tenants" element={<Tenants />} />
            </Route>

            {/* Catch all route */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
    </AuthProvider>
  </QueryClientProvider>
  );
};

export default App;
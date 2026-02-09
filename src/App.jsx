
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
import RentTracking from "./pages/RentTracking";
import MaintenanceRequests from "./pages/MaintenanceRequests";
import Pricing from "./pages/Pricing";
import Migration from "./pages/Migration";
import NotFound from "./pages/NotFound";
import Login from "./pages/Login";
import Terms from "./pages/Terms";
import Privacy from "./pages/Privacy";
import { AuthProvider } from "./contexts/AuthContext";
import ProtectedRoute from "./components/ProtectedRoute";
import { SpeedInsights } from "@vercel/speed-insights/react";
// We'll initialize the admin setup utility after React mounts
// This prevents issues with Firebase initialization timing
import React, { useEffect } from 'react';
import { ThemeProvider } from './contexts/ThemeContext';
import { SwipeNavigation } from './components/ui/swipe-navigation';

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

    // Register PWA service worker
    if ('serviceWorker' in navigator) {
      window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js')
          .then((registration) => {
            console.log('SW registered: ', registration);
          })
          .catch((registrationError) => {
            console.log('SW registration failed: ', registrationError);
          });
      });
    }
  }, []);

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
            
            {/* Protected routes */}
            <Route element={<ProtectedRoute />}>
              <Route path="/dashboard" element={<SwipeNavigation><Dashboard /></SwipeNavigation>} />
              <Route path="/properties" element={<SwipeNavigation><Properties /></SwipeNavigation>} />
              <Route path="/documents" element={<SwipeNavigation><Documents /></SwipeNavigation>} />
              <Route path="/calendar" element={<SwipeNavigation><Calendar /></SwipeNavigation>} />
              <Route path="/reminders" element={<SwipeNavigation><Reminders /></SwipeNavigation>} />
              <Route path="/analytics" element={<SwipeNavigation><Analytics /></SwipeNavigation>} />
              <Route path="/profile" element={<SwipeNavigation><Profile /></SwipeNavigation>} />
              <Route path="/tenants" element={<SwipeNavigation><Tenants /></SwipeNavigation>} />
              <Route path="/rent-tracking" element={<SwipeNavigation><RentTracking /></SwipeNavigation>} />
              <Route path="/maintenance" element={<SwipeNavigation><MaintenanceRequests /></SwipeNavigation>} />
              <Route path="/pricing" element={<SwipeNavigation><Pricing /></SwipeNavigation>} />
              <Route path="/migration" element={<Migration />} />
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

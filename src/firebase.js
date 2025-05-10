// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { getStorage } from "firebase/storage";

// Determine which Firebase configuration to use, with the following priority:
// 1. Use window.FIREBASE_CONFIG if available (from public/firebase-config.js)
// 2. Use environment variables if available
// 3. Fall back to hardcoded values as last resort

let firebaseConfig;

// Check if we have the global config from our public script
if (typeof window !== 'undefined' && window.FIREBASE_CONFIG) {
  console.log('Using global Firebase configuration from window.FIREBASE_CONFIG');
  firebaseConfig = window.FIREBASE_CONFIG;
} else {
  // Fall back to environment variables or hardcoded config
  console.log('Using fallback Firebase configuration');
  firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY || "AIzaSyAmSdCC1eiwrs7k-xGU2ebQroQJnuIL78o",
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || "highlanderhomes-4b1f3.firebaseapp.com",
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "highlanderhomes-4b1f3",
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "highlanderhomes-4b1f3.firebasestorage.app",
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "665607510591",
    appId: import.meta.env.VITE_FIREBASE_APP_ID || "1:665607510591:web:57d705c120dbbd3cfab68a",
    measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID || "G-PGGNT9XXN5"
  };
}

// Initialize Firebase with direct configuration
let app;
let db = null;
let auth = null;
let storage = null;

try {
  console.log('Initializing Firebase...');
  app = initializeApp(firebaseConfig);
  console.log('Firebase initialized successfully');
  
  // Initialize services
  db = getFirestore(app);
  auth = getAuth(app);
  storage = getStorage(app);
} catch (error) {
  console.error('Error initializing Firebase:', error);
}

// Export the services (either initialized or null if initialization failed)
export { db, auth, storage };
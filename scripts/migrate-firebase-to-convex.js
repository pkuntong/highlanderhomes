/**
 * Migration Script: Firebase to Convex
 * 
 * This script fetches data from your Firebase Firestore and imports it into Convex.
 * 
 * Usage:
 *   1. Make sure both Firebase and Convex are configured
 *   2. Run: node scripts/migrate-firebase-to-convex.js
 *   
 * Prerequisites:
 *   - Firebase Admin SDK or client SDK configured
 *   - Convex dev server running (npx convex dev)
 */

import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import { ConvexHttpClient } from 'convex/browser';
import { api } from '../convex/_generated/api.js';

// Firebase configuration (from your .env or firebase.js)
const firebaseConfig = {
  apiKey: process.env.VITE_FIREBASE_API_KEY || "AIzaSyAmSdCC1eiwrs7k-xGU2ebQroQJnuIL78o",
  authDomain: process.env.VITE_FIREBASE_AUTH_DOMAIN || "highlanderhomes-4b1f3.firebaseapp.com",
  projectId: process.env.VITE_FIREBASE_PROJECT_ID || "highlanderhomes-4b1f3",
  storageBucket: process.env.VITE_FIREBASE_STORAGE_BUCKET || "highlanderhomes-4b1f3.firebasestorage.app",
  messagingSenderId: process.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "665607510591",
  appId: process.env.VITE_FIREBASE_APP_ID || "1:665607510591:web:57d705c120dbbd3cfab68a",
};

// Convex configuration
const CONVEX_URL = process.env.VITE_CONVEX_URL || "https://successful-goldfinch-551.convex.cloud";

// Initialize Firebase
const firebaseApp = initializeApp(firebaseConfig);
const db = getFirestore(firebaseApp);

// Initialize Convex client
const convex = new ConvexHttpClient(CONVEX_URL);

// Migration user email (will be created if doesn't exist)
const MIGRATION_USER_EMAIL = "admin@highlanderhomes.com";
const MIGRATION_USER_NAME = "Admin User";

async function migrateData() {
  console.log("🚀 Starting Firebase to Convex migration...\n");

  try {
    // Step 1: Create or get migration user
    console.log("📝 Creating/getting migration user...");
    const userId = await convex.mutation(api.migrations.createMigrationUser, {
      email: MIGRATION_USER_EMAIL,
      name: MIGRATION_USER_NAME,
    });
    console.log(`✅ User ID: ${userId}\n`);

    // Step 2: Fetch properties from Firebase
    console.log("📦 Fetching properties from Firebase...");
    const propertiesSnapshot = await getDocs(collection(db, "properties"));
    const firebaseProperties = [];
    
    propertiesSnapshot.forEach((doc) => {
      const data = doc.data();
      firebaseProperties.push({
        firebaseId: doc.id,
        address: data.address || "",
        city: data.city || "",
        state: data.state || "",
        zipCode: data.zipCode || "",
        propertyType: data.propertyType || "Single Family",
        units: data.units || 1,
        monthlyRent: data.monthlyRent || 0,
        bedrooms: data.bedrooms || 0,
        fullBathrooms: data.fullBathrooms || 0,
        halfBathrooms: data.halfBathrooms || 0,
        squareFootage: data.squareFootage || 0,
        yearBuilt: data.yearBuilt || 0,
        status: data.status || "vacant",
        paymentStatus: data.paymentStatus || "pending",
        description: data.description || "",
        imageUrl: data.imageUrl || data.imageBase64 || "",
        leaseType: data.leaseType || "Annual",
      });
    });
    console.log(`  Found ${firebaseProperties.length} properties\n`);

    // Step 3: Import properties to Convex
    if (firebaseProperties.length > 0) {
      console.log("📥 Importing properties to Convex...");
      const propertyResults = await convex.mutation(api.migrations.importProperties, {
        properties: firebaseProperties,
        userId: userId,
      });
      
      const successCount = propertyResults.filter(r => r.success).length;
      const failCount = propertyResults.filter(r => !r.success).length;
      console.log(`  ✅ Imported: ${successCount}`);
      if (failCount > 0) {
        console.log(`  ❌ Failed: ${failCount}`);
        propertyResults.filter(r => !r.success).forEach(r => {
          console.log(`    - ${r.firebaseId}: ${r.error}`);
        });
      }
      console.log("");
    }

    // Step 4: Fetch tenants from Firebase
    console.log("📦 Fetching tenants from Firebase...");
    const tenantsSnapshot = await getDocs(collection(db, "tenants"));
    const firebaseTenants = [];
    
    tenantsSnapshot.forEach((doc) => {
      const data = doc.data();
      firebaseTenants.push({
        firebaseId: doc.id,
        firstName: data.firstName || data.name?.split(' ')[0] || "",
        lastName: data.lastName || data.name?.split(' ').slice(1).join(' ') || "",
        email: data.email || "",
        phone: data.phone || "",
        unit: data.unit || "",
        // Note: propertyId needs to be mapped from Firebase ID to Convex ID
        // For now, we'll skip this field and handle it manually
        leaseStartDate: data.leaseStartDate ? new Date(data.leaseStartDate).getTime() : undefined,
        leaseEndDate: data.leaseEndDate ? new Date(data.leaseEndDate).getTime() : undefined,
        monthlyRent: data.monthlyRent || data.rentAmount || 0,
        securityDeposit: data.securityDeposit || 0,
        isActive: data.isActive !== false,
      });
    });
    console.log(`  Found ${firebaseTenants.length} tenants\n`);

    // Note: Tenants require propertyId which needs mapping
    if (firebaseTenants.length > 0) {
      console.log("⚠️  Tenants found but require manual property ID mapping.");
      console.log("   Run the property migration first, then map tenant propertyIds.\n");
    }

    // Step 5: Fetch maintenance requests from Firebase
    console.log("📦 Fetching maintenance requests from Firebase...");
    const maintenanceSnapshot = await getDocs(collection(db, "maintenanceRequests"));
    const firebaseRequests = [];
    
    maintenanceSnapshot.forEach((doc) => {
      const data = doc.data();
      firebaseRequests.push({
        firebaseId: doc.id,
        // propertyId needs mapping
        title: data.title || "",
        descriptionText: data.description || data.descriptionText || "",
        category: data.category || "other",
        priority: data.priority || "normal",
        status: data.status || "new",
        scheduledDate: data.scheduledDate ? new Date(data.scheduledDate).getTime() : undefined,
        completedDate: data.completedDate ? new Date(data.completedDate).getTime() : undefined,
        estimatedCost: data.estimatedCost,
        actualCost: data.actualCost,
        notes: data.notes || "",
      });
    });
    console.log(`  Found ${firebaseRequests.length} maintenance requests\n`);

    if (firebaseRequests.length > 0) {
      console.log("⚠️  Maintenance requests found but require manual property ID mapping.\n");
    }

    // Summary
    console.log("=" .repeat(50));
    console.log("📊 Migration Summary:");
    console.log(`   Properties: ${firebaseProperties.length} migrated`);
    console.log(`   Tenants: ${firebaseTenants.length} found (require property mapping)`);
    console.log(`   Maintenance: ${firebaseRequests.length} found (require property mapping)`);
    console.log("=" .repeat(50));
    console.log("\n✅ Migration complete!");
    console.log("\n📌 Next steps:");
    console.log("   1. Check your Convex dashboard to verify the data");
    console.log("   2. Map tenant propertyIds and re-run tenant import");
    console.log("   3. Map maintenance request propertyIds and re-run import");
    console.log("   4. Update your iOS app to use the new Convex backend");

  } catch (error) {
    console.error("❌ Migration failed:", error);
    process.exit(1);
  }
}

// Run migration
migrateData();

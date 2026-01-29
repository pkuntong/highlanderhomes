import { useState, useEffect } from "react";
import { db } from "@/firebase";
import { collection, getDocs } from "firebase/firestore";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

// Convex URL
const CONVEX_URL = import.meta.env.VITE_CONVEX_URL || "https://successful-goldfinch-551.convex.cloud";

// Migration user
const MIGRATION_USER_EMAIL = "admin@highlanderhomes.com";
const MIGRATION_USER_NAME = "Admin User";

// Helper to call Convex mutations via HTTP
async function callConvexMutation(functionPath, args) {
  const response = await fetch(`${CONVEX_URL}/api/mutation`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      path: functionPath,
      args: args,
      format: "json",
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Convex error: ${error}`);
  }

  const result = await response.json();
  return result.value;
}

const Migration = () => {
  const [status, setStatus] = useState("");
  const [logs, setLogs] = useState([]);
  const [isRunning, setIsRunning] = useState(false);
  const [stats, setStats] = useState({
    properties: { firebase: 0, migrated: 0, failed: 0 },
    tenants: { firebase: 0, migrated: 0, failed: 0 },
    maintenance: { firebase: 0, migrated: 0, failed: 0 },
  });

  const addLog = (message, type = "info") => {
    const timestamp = new Date().toLocaleTimeString();
    setLogs((prev) => [...prev, { message, type, timestamp }]);
  };

  const runMigration = async () => {
    setIsRunning(true);
    setLogs([]);
    setStatus("Starting migration...");

    try {
      // Step 1: Create migration user in Convex
      addLog("Creating/getting migration user in Convex...");
      const userId = await callConvexMutation("migrations:createMigrationUser", {
        email: MIGRATION_USER_EMAIL,
        name: MIGRATION_USER_NAME,
      });
      addLog(`User ID: ${userId}`, "success");

      // Step 2: Fetch properties from Firebase
      addLog("Fetching properties from Firebase...");
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
          monthlyRent: Number(data.monthlyRent) || 0,
          bedrooms: Number(data.bedrooms) || 0,
          fullBathrooms: Number(data.fullBathrooms) || 0,
          halfBathrooms: Number(data.halfBathrooms) || 0,
          squareFootage: Number(data.squareFootage) || 0,
          yearBuilt: Number(data.yearBuilt) || 0,
          status: data.status || "vacant",
          paymentStatus: data.paymentStatus || "pending",
          description: data.description || "",
          imageUrl: data.imageUrl || "",
          leaseType: data.leaseType || "Annual",
        });
      });

      addLog(`Found ${firebaseProperties.length} properties in Firebase`);
      setStats((prev) => ({
        ...prev,
        properties: { ...prev.properties, firebase: firebaseProperties.length },
      }));

      // Step 3: Import properties to Convex
      if (firebaseProperties.length > 0) {
        addLog("Importing properties to Convex...");
        
        // Import in batches of 10 to avoid timeouts
        const batchSize = 10;
        let migratedCount = 0;
        let failedCount = 0;

        for (let i = 0; i < firebaseProperties.length; i += batchSize) {
          const batch = firebaseProperties.slice(i, i + batchSize);
          
          try {
            const results = await callConvexMutation("migrations:importProperties", {
              properties: batch,
              userId: userId,
            });

            const batchSuccess = results.filter((r) => r.success).length;
            const batchFailed = results.filter((r) => !r.success).length;
            migratedCount += batchSuccess;
            failedCount += batchFailed;

            addLog(`Batch ${Math.floor(i / batchSize) + 1}: ${batchSuccess} migrated, ${batchFailed} failed`);
            
            // Log any failures
            results.filter((r) => !r.success).forEach((r) => {
              addLog(`  Failed: ${r.firebaseId} - ${r.error}`, "error");
            });
          } catch (error) {
            addLog(`Batch ${Math.floor(i / batchSize) + 1} failed: ${error.message}`, "error");
            failedCount += batch.length;
          }
        }

        setStats((prev) => ({
          ...prev,
          properties: { ...prev.properties, migrated: migratedCount, failed: failedCount },
        }));

        addLog(`Properties: ${migratedCount} migrated, ${failedCount} failed`, migratedCount > 0 ? "success" : "error");
      }

      // Step 4: Fetch tenants from Firebase
      addLog("Fetching tenants from Firebase...");
      try {
        const tenantsSnapshot = await getDocs(collection(db, "tenants"));
        const tenantCount = tenantsSnapshot.size;
        addLog(`Found ${tenantCount} tenants in Firebase`);
        setStats((prev) => ({
          ...prev,
          tenants: { ...prev.tenants, firebase: tenantCount },
        }));
        
        if (tenantCount > 0) {
          addLog("Note: Tenants require property ID mapping. Manual import needed.", "warning");
        }
      } catch (error) {
        addLog(`Could not fetch tenants: ${error.message}`, "warning");
      }

      // Step 5: Fetch maintenance requests from Firebase
      addLog("Fetching maintenance requests from Firebase...");
      try {
        const maintenanceSnapshot = await getDocs(collection(db, "maintenanceRequests"));
        const maintenanceCount = maintenanceSnapshot.size;
        addLog(`Found ${maintenanceCount} maintenance requests in Firebase`);
        setStats((prev) => ({
          ...prev,
          maintenance: { ...prev.maintenance, firebase: maintenanceCount },
        }));
        
        if (maintenanceCount > 0) {
          addLog("Note: Maintenance requests require property ID mapping. Manual import needed.", "warning");
        }
      } catch (error) {
        addLog(`Could not fetch maintenance requests: ${error.message}`, "warning");
      }

      setStatus("Migration complete!");
      addLog("Migration complete! Check the Convex dashboard to verify data.", "success");

    } catch (error) {
      setStatus("Migration failed!");
      addLog(`Error: ${error.message}`, "error");
      console.error("Migration error:", error);
    } finally {
      setIsRunning(false);
    }
  };

  const clearConvexData = async () => {
    if (!window.confirm("This will delete ALL data in Convex. Are you sure?")) {
      return;
    }

    setIsRunning(true);
    addLog("Clearing all Convex data...", "warning");

    try {
      const results = await callConvexMutation("migrations:clearAllData", {});
      addLog("Cleared data:", "success");
      Object.entries(results).forEach(([table, count]) => {
        addLog(`  ${table}: ${count} records deleted`);
      });
    } catch (error) {
      addLog(`Error clearing data: ${error.message}`, "error");
    } finally {
      setIsRunning(false);
    }
  };

  return (
    <div className="container mx-auto p-6 max-w-4xl">
      <h1 className="text-3xl font-bold mb-6">Firebase to Convex Migration</h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-lg">Properties</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.properties.migrated}</div>
            <div className="text-sm text-gray-500">
              Firebase: {stats.properties.firebase} | Failed: {stats.properties.failed}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-lg">Tenants</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.tenants.migrated}</div>
            <div className="text-sm text-gray-500">
              Firebase: {stats.tenants.firebase} | Failed: {stats.tenants.failed}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-lg">Maintenance</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.maintenance.migrated}</div>
            <div className="text-sm text-gray-500">
              Firebase: {stats.maintenance.firebase} | Failed: {stats.maintenance.failed}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="flex gap-4 mb-6">
        <Button onClick={runMigration} disabled={isRunning} size="lg">
          {isRunning ? "Running..." : "Start Migration"}
        </Button>
        <Button onClick={clearConvexData} disabled={isRunning} variant="destructive">
          Clear Convex Data
        </Button>
      </div>

      {status && (
        <div className={`p-4 rounded mb-4 ${status.includes("complete") ? "bg-green-100 text-green-800" : status.includes("failed") ? "bg-red-100 text-red-800" : "bg-blue-100 text-blue-800"}`}>
          {status}
        </div>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Migration Log</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-96 overflow-y-auto bg-gray-900 text-gray-100 p-4 rounded font-mono text-sm">
            {logs.length === 0 ? (
              <div className="text-gray-500">Click "Start Migration" to begin...</div>
            ) : (
              logs.map((log, index) => (
                <div
                  key={index}
                  className={`mb-1 ${
                    log.type === "error"
                      ? "text-red-400"
                      : log.type === "success"
                      ? "text-green-400"
                      : log.type === "warning"
                      ? "text-yellow-400"
                      : "text-gray-300"
                  }`}
                >
                  <span className="text-gray-500">[{log.timestamp}]</span> {log.message}
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      <div className="mt-6 p-4 bg-blue-50 rounded">
        <h3 className="font-semibold mb-2">Next Steps:</h3>
        <ol className="list-decimal list-inside space-y-1 text-sm">
          <li>Check the <a href="https://dashboard.convex.dev/d/successful-goldfinch-551" target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">Convex Dashboard</a> to verify migrated data</li>
          <li>The iOS app should now be able to fetch properties from Convex</li>
          <li>For tenants and maintenance, you may need to map property IDs manually</li>
        </ol>
      </div>
    </div>
  );
};

export default Migration;

import { createContext, useContext, useState, useEffect } from "react";

const AuthContext = createContext(undefined);

export function AuthProvider({ children }) {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  const login = (email, password) => {
    const storedPassword = localStorage.getItem("highlanderhomes_password") || "highlander2025";
    if (email === "highlanderhomes22@gmail.com" && password === storedPassword) {
      setIsAuthenticated(true);
      localStorage.setItem("isAuthenticated", "true");
      return true;
    } else {
      alert("Invalid email or password.");
      return false;
    }
  };

  const logout = () => {
    setIsAuthenticated(false);
    localStorage.removeItem("isAuthenticated");
  };

  // Check if user was previously authenticated
  useEffect(() => {
    try {
      const storedAuth = localStorage.getItem("isAuthenticated");
      if (storedAuth === "true") {
        setIsAuthenticated(true);
      }
    } catch (error) {
      // Handle potential errors from localStorage access if necessary
      console.error("Error reading auth state from localStorage", error);
    } finally {
      setLoading(false);
    }
  }, []);

  return (
    <AuthContext.Provider value={{ isAuthenticated, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
} 
import { createContext, useContext, useState, useEffect } from "react";
import { 
  createUserWithEmailAndPassword, 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged,
  sendPasswordResetEmail
} from "firebase/auth";
import { auth } from "@/firebase";

const AuthContext = createContext(undefined);

export function AuthProvider({ children }) {
  const [currentUser, setCurrentUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Sign up function for creating new users
  const signup = async (email, password) => {
    try {
      return await createUserWithEmailAndPassword(auth, email, password);
    } catch (error) {
      console.error("Error signing up:", error);
      throw error;
    }
  };

  // Login function using Firebase Authentication
  const login = async (email, password) => {
    try {
      // Now using Firebase Authentication primarily
      const result = await signInWithEmailAndPassword(auth, email, password);
      console.log("Firebase login successful");
      return true;
    } catch (error) {
      console.error("Error logging in:", error);
      throw error;
    }
  };

  // Logout function handling both auth methods
  const logout = async () => {
    try {
      // Always clear localStorage auth state for legacy method
      localStorage.removeItem("isAuthenticated");
      
      // Also sign out of Firebase if possible
      try {
        await signOut(auth);
      } catch (error) {
        // Ignore Firebase signOut errors since we might not be using it
        console.log("Firebase signOut not possible, but continuing");
      }
      
      // Always reset current user state regardless of auth method
      setCurrentUser(null);
    } catch (error) {
      console.error("Error logging out:", error);
      throw error;
    }
  };

  // Password reset function
  const resetPassword = async (email) => {
    try {
      return await sendPasswordResetEmail(auth, email);
    } catch (error) {
      console.error("Error resetting password:", error);
      throw error;
    }
  };
  
  // Listen for authentication state changes using Firebase
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setCurrentUser(user);
      setLoading(false);
    });
    
    // Cleanup subscription on unmount
    return unsubscribe;
  }, []);

  const value = {
    currentUser,
    isAuthenticated: !!currentUser,
    login,
    logout,
    signup,
    resetPassword,
    loading
  };
  
  return (
    <AuthContext.Provider value={value}>
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
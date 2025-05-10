// Admin setup utility
import { db, auth } from '@/firebase';
import { doc, setDoc } from 'firebase/firestore';

/**
 * Creates an admin user record for the currently logged in user
 * Run this once from the browser console after logging in with Firebase Authentication
 */
export const setupAdminUser = async () => {
  // Check if user is logged in
  const currentUser = auth.currentUser;
  if (!currentUser) {
    console.error('No user is logged in. Please log in first.');
    return false;
  }
  
  try {
    // Create admin user record
    await setDoc(doc(db, 'adminUsers', currentUser.uid), {
      email: currentUser.email,
      isAdmin: true,
      createdAt: new Date().toISOString()
    });
    
    console.log('Admin user created successfully!');
    console.log('User ID:', currentUser.uid);
    console.log('Email:', currentUser.email);
    return true;
  } catch (error) {
    console.error('Error creating admin user:', error);
    return false;
  }
};

// Export a global function that can be called from the console
window.setupAdminUser = setupAdminUser;

// Secure storage utilities for handling documents and sensitive data
// Using free base64 storage in Firestore (no Firebase Storage needed)
import { auth, db } from '@/firebase';
import { collection, addDoc, updateDoc, doc, getDoc, setDoc } from 'firebase/firestore';

// Note: File storage now handled via base64 encoding in Firestore documents
// No separate upload/delete functions needed - files are stored directly in document data

/**
 * Adds a document record to Firestore with security metadata
 * @param {Object} documentData - The document data (including fileUrl and filePath if file was uploaded)
 * @returns {Promise<string>} - The document ID
 */
export const addSecureDocument = async (documentData) => {
  if (!auth.currentUser) {
    throw new Error('Authentication required to create documents');
  }

  const userId = auth.currentUser.uid;

  // Add security metadata
  const secureDocumentData = {
    ...documentData,
    createdBy: userId,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };

  const docRef = await addDoc(collection(db, 'documents'), secureDocumentData);
  return docRef.id;
};

/**
 * Updates a document with security checks
 * @param {string} documentId - The document ID to update
 * @param {Object} documentData - The updated document data
 * @returns {Promise<void>}
 */
export const updateSecureDocument = async (documentId, documentData) => {
  if (!auth.currentUser) {
    throw new Error('Authentication required to update documents');
  }
  
  const userId = auth.currentUser.uid;
  
  // Add security metadata
  const secureDocumentData = {
    ...documentData,
    updatedBy: userId,
    updatedAt: new Date().toISOString(),
  };
  
  const documentRef = doc(db, 'documents', documentId);
  
  // Check if document exists first
  console.log(`Checking if document ${documentId} exists before updating`);
  const docSnapshot = await getDoc(documentRef);
  
  if (!docSnapshot.exists()) {
    // Document doesn't exist, create it instead
    console.log(`Document ${documentId} doesn't exist, creating instead of updating`);
    // Add creation metadata too
    const newDocumentData = {
      ...secureDocumentData,
      createdBy: userId,
      createdAt: new Date().toISOString(),
    };
    await setDoc(documentRef, newDocumentData);
  } else {
    // Document exists, update it
    console.log(`Document ${documentId} exists, updating`);
    await updateDoc(documentRef, secureDocumentData);
  }
};

// Secure storage utilities for handling documents and sensitive data
import { auth, storage, db } from '@/firebase';
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage';
import { collection, addDoc, updateDoc, doc, getDoc, setDoc } from 'firebase/firestore';

/**
 * Uploads a file to Firebase Storage with security checks
 * @param {File} file - The file to upload
 * @param {string} path - The storage path (e.g., 'documents')
 * @param {Object} metadata - Additional metadata for the file
 * @returns {Promise<Object>} - Object containing download URL and file reference
 */
export const uploadSecureFile = async (file, path, metadata = {}) => {
  if (!auth.currentUser) {
    throw new Error('Authentication required to upload files');
  }
  
  // Generate a unique file path with user ID to maintain isolation
  const userId = auth.currentUser.uid;
  const timestamp = new Date().getTime();
  const fileExtension = file.name.split('.').pop();
  const securePath = `${path}/${userId}/${timestamp}-${Math.random().toString(36).substring(2)}.${fileExtension}`;
  
  // Create file reference
  const storageRef = ref(storage, securePath);
  
  // Add security metadata
  const secureMetadata = {
    customMetadata: {
      ...metadata,
      uploadedBy: userId,
      uploadedAt: new Date().toISOString(),
      originalName: file.name
    }
  };
  
  // Upload the file
  await uploadBytes(storageRef, file, secureMetadata);
  
  // Get the download URL
  const downloadURL = await getDownloadURL(storageRef);
  
  return {
    url: downloadURL,
    path: securePath,
    name: file.name,
    type: file.type,
    size: file.size,
    metadata: secureMetadata.customMetadata
  };
};

/**
 * Deletes a file from Firebase Storage with security checks
 * @param {string} filePath - The full path to the file in storage
 * @returns {Promise<void>}
 */
export const deleteSecureFile = async (filePath) => {
  if (!auth.currentUser) {
    throw new Error('Authentication required to delete files');
  }
  
  // Security check: Verify this file belongs to the current user
  const userId = auth.currentUser.uid;
  if (!filePath.includes(`/${userId}/`)) {
    throw new Error('You do not have permission to delete this file');
  }
  
  const fileRef = ref(storage, filePath);
  await deleteObject(fileRef);
};

/**
 * Adds a document record to Firestore with security metadata
 * @param {Object} documentData - The document data
 * @param {string} fileUrl - URL to the uploaded file
 * @param {string} filePath - Path to the file in storage
 * @returns {Promise<string>} - The document ID
 */
export const addSecureDocument = async (documentData, fileUrl, filePath) => {
  if (!auth.currentUser) {
    throw new Error('Authentication required to create documents');
  }
  
  const userId = auth.currentUser.uid;
  
  // Add security metadata
  const secureDocumentData = {
    ...documentData,
    fileUrl,
    filePath,
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

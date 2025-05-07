// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyAmSdCC1eiwrs7k-xGU2ebQroQJnuIL78o",
  authDomain: "highlanderhomes-4b1f3.firebaseapp.com",
  projectId: "highlanderhomes-4b1f3",
  storageBucket: "highlanderhomes-4b1f3.firebasestorage.app",
  messagingSenderId: "665607510591",
  appId: "1:665607510591:web:57d705c120dbbd3cfab68a",
  measurementId: "G-PGGNT9XXN5"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
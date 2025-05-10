import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig(({ command, mode }) => {
  // Base configuration
  const config = {
    plugins: [react()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },
  };

  // For production builds, we'll define the Firebase config directly
  if (command === 'build') {
    config.define = {
      // Inject Firebase config directly into the build
      __FIREBASE_CONFIG__: JSON.stringify({
        apiKey: "AIzaSyAmSdCC1eiwrs7k-xGU2ebQroQJnuIL78o",
        authDomain: "highlanderhomes-4b1f3.firebaseapp.com",
        projectId: "highlanderhomes-4b1f3",
        storageBucket: "highlanderhomes-4b1f3.firebasestorage.app",
        messagingSenderId: "665607510591",
        appId: "1:665607510591:web:57d705c120dbbd3cfab68a",
        measurementId: "G-PGGNT9XXN5"
      }),
    };
  }

  return config;
});

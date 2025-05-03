import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  root: ".",
  publicDir: "public",
  base: "/",
  server: {
    port: 3000,
    host: true,
    open: true,
    strictPort: true,
  },
  build: {
    outDir: "dist",
    assetsDir: "assets",
    sourcemap: true,
    rollupOptions: {
      input: {
        main: path.resolve(__dirname, "index.html"),
      },
      output: {
        manualChunks: {
          vendor: ["react", "react-dom", "react-router-dom"],
        },
        format: "es",
        entryFileNames: "assets/[name]-[hash].js",
        chunkFileNames: "assets/[name]-[hash].js",
        assetFileNames: "assets/[name]-[hash].[ext]"
      },
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
    extensions: [".mjs", ".js", ".ts", ".jsx", ".tsx", ".json"],
  },
  optimizeDeps: {
    include: ["react", "react-dom", "react-router-dom"],
    esbuildOptions: {
      loader: {
        ".js": "jsx",
        ".ts": "tsx",
      },
    },
  },
  esbuild: {
    loader: "tsx",
    include: /src\/.*\.tsx?$/,
    exclude: [],
  },
});

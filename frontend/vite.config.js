import { loadEnv } from "vite";
import react from "@vitejs/plugin-react";

export default ({ command, mode }) => {
  const env = loadEnv(mode, process.cwd());

  return {
    plugins: [react()],
    server: {
      port: 3000,
      host: true,
      watch: {
        usePolling: true,
      },
      esbuild: {
        target: "esnext",
        platform: "linux",
      },
    },
    define: {
      VITE_APP_BACKEND_ADDRESS: JSON.stringify(env.VITE_APP_BACKEND_ADDRESS),
    },
    build: {
      outDir: "dist", // Changed from "frontend/dist" to just "dist"
      assetsDir: "assets",
      // Remove the rollupOptions section or correct the path to index.html
      // rollupOptions: {
      //   input: "frontend/index.html" 
      // },
      base: "/", 
    },
  };
};
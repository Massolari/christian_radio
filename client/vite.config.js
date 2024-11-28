import gleam from "vite-gleam";
import { defineConfig } from "vite";
import { execSync } from "child_process";

export default defineConfig({
  root: "src",
  plugins: [gleam()],
  build: {
    outDir: "../../server/static/",
  },
  define: {
    GIT_COMMIT_HASH: JSON.stringify(
      execSync("git rev-parse --short HEAD").toString().trim()
    ),
  },
  server: {
    port: 9000,
    proxy: {
      "^/api/*": {
        target: "http://localhost:8000",
        secure: false,
        changeOrigin: true,
      },
      "^/assets/*": {
        target: "http://localhost:8000",
        secure: false,
        changeOrigin: true,
      },
      "^/sw.js": {
        target: "http://localhost:8000",
        secure: false,
        changeOrigin: true,
      },
      "^/manifest.json": {
        target: "http://localhost:8000",
        secure: false,
        changeOrigin: true,
      },
      "^/ws": {
        target: "ws://localhost:8000",
        secure: false,
        changeOrigin: true,
      },
    },
  },
});

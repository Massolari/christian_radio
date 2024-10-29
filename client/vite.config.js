import gleam from 'vite-gleam'
import { defineConfig } from 'vite'

export default defineConfig({
  root: 'src',
  plugins: [gleam()],
  build: {
    outDir: "../../server/static/"
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
    }
  },
})

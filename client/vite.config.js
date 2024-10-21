import gleam from "vite-gleam"

/** @type {import('vite').UserConfig} */
export default {
  root: "src",
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
      "^/ws": {
        target: "ws://localhost:8000",
        secure: false,
        changeOrigin: true,
      },
    }
  },
}

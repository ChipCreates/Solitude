import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["favicon.ico", "apple-touch-icon.png", "mask-icon.svg"],
      manifest: {
        name: "Solitude Solitaire",
        short_name: "Solitude",
        description: "A beautiful, privacy-first, offline-capable Solitaire game collection",
        theme_color: "#0f2d1a",
        background_color: "#131313",
        display: "standalone",
        orientation: "any",
        icons: [
          {
            src: "pwa-192x192.png",
            sizes: "192x192",
            type: "image/png",
          },
          {
            src: "pwa-512x512.png",
            sizes: "512x512",
            type: "image/png",
          },
        ],
      },
      workbox: {
        globPatterns: ["**/*.{js,css,html,ico,png,svg,wasm,mp3}"],
      },
    }),
  ],
  build: {
    outDir: "dist-web",
    emptyOutDir: true,
  },
});

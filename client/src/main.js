import { main } from "./client.gleam";
import iosPWASplash from "ios-pwa-splash";

iosPWASplash("/assets/icon-192x192.png", "#677A98");

// Make :active work on iOS
window.onload = function () {
  if (/iP(hone|ad)/.test(window.navigator.userAgent)) {
    document.body.addEventListener("touchstart", function () {}, false);
  }
};

// Register Service Worker
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker
      .register("/sw.js", { updateViaCache: "none" })
      .then((registration) => {
        console.log("ServiceWorker registration successful");

        // Verifica se há uma versão nova sempre que o app volta a ficar
        // visível, para não depender só do ciclo padrão de update do navegador.
        document.addEventListener("visibilitychange", () => {
          if (document.visibilityState === "visible") {
            registration.update();
          }
        });
      })
      .catch((err) => {
        console.log("ServiceWorker registration failed: ", err);
      });
  });
}

main();

const CACHE_NAME = 'christian-radio-v1';
const ASSETS_TO_CACHE = [
  '/',
  '/index.html',
  '/manifest.json',
  '/assets/favicon.ico',
  '/assets/station-gospel-mix.jpg',
];

// Instalação do Service Worker
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
  // Force o novo service worker a se tornar ativo imediatamente
  self.skipWaiting();
});

// Ativação do Service Worker
self.addEventListener('activate', (event) => {
  event.waitUntil(
    // Limpa os caches antigos
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((cacheName) => {
            // Remove caches antigos (que começam com 'christian-radio-' mas não são o atual)
            return cacheName.startsWith('christian-radio-') && cacheName !== CACHE_NAME;
          })
          .map((cacheName) => {
            return caches.delete(cacheName);
          })
      );
    })
  );
});

// Interceptação de requisições
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      // Retorna do cache se encontrar, senão faz a requisição
      return response || fetch(event.request);
    })
  );
}); 
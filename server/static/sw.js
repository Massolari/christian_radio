const CACHE_PREFIX = 'christian-radio-';
const CACHE_NAME = CACHE_PREFIX + GIT_COMMIT_HASH;

const ASSETS_TO_CACHE = [
  '/',
  '/index.html',
  '/manifest.json',
  '/assets/favicon.ico',
  '/assets/station-gospel-adoracao.png',
  '/assets/station-gospel-mix.jpg',
  '/assets/station-christian-hits.jpg',
  '/assets/station-christian-rock.jpg',
  '/assets/station-melodia.png',
  '/assets/station-radio-93.png',
];

const VITE_ASSETS_PATTERN = /\/assets\/index-.+\.(js|css)$/;

// Instalação do Service Worker
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => 
      cache.addAll(ASSETS_TO_CACHE)
    )
  );
  // Force o novo service worker a se tornar ativo imediatamente
  self.skipWaiting();
});

// Ativação do Service Worker
self.addEventListener('activate', (event) => {
  event.waitUntil(
    // Limpa os caches antigos
    caches.keys().then((cacheNames) => 
      Promise.all(
        cacheNames
          .filter((cacheName) => 
            // Remove caches antigos (que começam com 'christian-radio-' mas não são o atual)
            cacheName.startsWith('christian-radio-') && cacheName !== CACHE_NAME
          )
          .map((cacheName) => 
            caches.delete(cacheName)
          )
      )
    )
  );
});

// Interceptação de requisições
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      if (response) {
        return response;
      }

      return fetch(event.request).then((response) => {
        // Verifica se é uma resposta válida
        if (!response || response.status !== 200 || response.type !== 'basic') {
          return response;
        }

        // Verifica se é um arquivo index.js ou index.css do Vite
        if (VITE_ASSETS_PATTERN.test(event.request.url)) {
          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }

        return response;
      });
    })
  );
}); 
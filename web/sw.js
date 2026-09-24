// Service worker: guarda la app para que funcione sin conexión en el gimnasio.
// Cambia VERSION en cada publicación para que el móvil descargue la nueva.
const VERSION = 'goazen-v1.2.0';
const FILES = [
  './',
  'index.html',
  'manifest.webmanifest',
  'css/app.css',
  'js/app.js',
  'js/store.js',
  'js/progression.js',
  'js/coach.js',
  'js/charts.js',
  'js/export.js',
  'js/importer.js',
  'js/timer.js',
  'js/ui.js',
  'js/data/exercises.js',
  'js/data/blocks.js',
  'js/data/history.js',
  'js/views/home.js',
  'js/views/session.js',
  'js/views/plan.js',
  'js/views/progress.js',
  'js/views/body.js',
  'js/views/more.js',
  'vendor/xlsx.mini.min.js',
  'icons/icon.svg',
  'icons/icon-192.png',
  'icons/icon-512.png',
];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(VERSION).then((c) => c.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== VERSION).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

// Primero la caché (rápido y sin conexión); en segundo plano se actualiza desde la red.
self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET' || new URL(e.request.url).origin !== location.origin) return;
  e.respondWith(
    caches.open(VERSION).then(async (cache) => {
      const cached = await cache.match(e.request, { ignoreSearch: true });
      const network = fetch(e.request)
        .then((res) => {
          if (res.ok) cache.put(e.request, res.clone());
          return res;
        })
        .catch(() => cached);
      return cached ?? network;
    }),
  );
});

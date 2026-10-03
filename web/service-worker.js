// Optional app-shell worker. It deliberately excludes map tiles, Firebase data, photos and admin responses.
const CACHE = 'tortoise-watch-shell-v2';
const SHELL = ['/', '/index.html', '/manifest.json', '/icons/icon-192.png', '/icons/icon-512.png'];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(SHELL)));
});

self.addEventListener('activate', (event) => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE).map(key => caches.delete(key)))));
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  // Exact allowlist: never intercept APIs, tile images, photos or admin data.
  if (event.request.method !== 'GET' || url.origin !== self.location.origin || !SHELL.includes(url.pathname) || url.search) return;
  event.respondWith(caches.match(event.request).then((cached) => cached || fetch(event.request)));
});

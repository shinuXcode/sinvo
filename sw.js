/* Retire the legacy Sinvo offline web service worker. The website is showcase-only. */
self.addEventListener("install", event => event.waitUntil(self.skipWaiting()));
self.addEventListener("activate", event => event.waitUntil((async () => {
  const keys = await caches.keys();
  await Promise.all(keys.map(key => caches.delete(key)));
  await self.clients.claim();
  await self.registration.unregister();
})()));
self.addEventListener("fetch", event => {
  if (event.request.method === "GET") event.respondWith(fetch(event.request));
});

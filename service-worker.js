const CACHE_NAME = "universal-converter-v11";
const CORE_ASSETS = [
  "/",
  "/index.html",
  "/styles.css",
  "/app.js",
  "/adsense-config.js",
  "/adsense.js",
  "/analytics-config.js",
  "/google-analytics.js",
  "/logo.svg",
  "/favicon.svg",
  "/site.webmanifest",
  "/unit-converter.html",
  "/online-calculator.html",
  "/sitemap.html",
  "/404.html",
  "/convert/",
  "/guides.html",
  "/metric-vs-imperial.html",
  "/what-is-a-kilometer.html",
  "/acre-vs-hectare.html",
  "/celsius-vs-fahrenheit.html",
  "/digital-storage-units-guide.html",
  "/pressure-units-guide.html",
  "/references.html",
  "/about.html",
  "/contact.html",
  "/privacy.html",
  "/terms.html"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(CORE_ASSETS))
      .then(() => self.skipWaiting())
      .catch(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;

  const requestUrl = new URL(event.request.url);
  const isSameOrigin = requestUrl.origin === self.location.origin;
  const isNavigation = event.request.mode === "navigate";
  const isHtml = isSameOrigin && requestUrl.pathname.endsWith(".html");

  if (isNavigation || isHtml) {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
          return response;
        })
        .catch(async () => {
          const cached = await caches.match(event.request);
          return cached || caches.match("/index.html");
        })
    );
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then((response) => {
        if (isSameOrigin && response.ok) {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
        }
        return response;
      }).catch(() => caches.match("/index.html"));
    })
  );
});

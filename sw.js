const CACHE = "gba-swap-check-v88";
const ASSETS = [
  "./",
  "index.html",
  "manifest.json",
  "Logo.png",
  "swap-icon.png"
];

self.addEventListener("install", (e) => {
  e.waitUntil(
    caches.open(CACHE)
      /* "reload" bypasses the browser's HTTP cache, so a new release can never
         be installed with a stale copy of a file */
      .then((cache) => Promise.all(ASSETS.map((url) =>
        fetch(new Request(url, { cache: "reload" }))
          .then((resp) => (resp && resp.ok ? cache.put(url, resp) : null))
          .catch(() => null)
      )))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(
      keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))
    )).then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  if (e.request.method !== "GET") return;
  if (new URL(e.request.url).origin !== self.location.origin) return;

  /* the page itself: try the network first, so a new release shows up as soon
     as the crew member is online, and fall back to the cache when they are not */
  if (e.request.mode === "navigate") {
    e.respondWith(
      fetch(e.request)
        .then((resp) => {
          if (resp && resp.ok && resp.type === "basic") {
            const copy = resp.clone();
            caches.open(CACHE).then((cache) => cache.put("./", copy));
          }
          return resp;
        })
        .catch(() => caches.match("./").then((r) => r || caches.match("index.html")))
    );
    return;
  }

  /* everything else is served from the cache and refreshed in the background */
  e.respondWith(
    caches.match(e.request).then((cached) => {
      if (cached) return cached;
      return fetch(e.request).then((resp) => {
        if (resp && resp.ok && resp.type === "basic") {
          const copy = resp.clone();
          caches.open(CACHE).then((cache) => cache.put(e.request, copy));
        }
        return resp;
      }).catch(() => caches.match("./"));
    })
  );
});

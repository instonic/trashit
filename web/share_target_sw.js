// Minimal service worker to handle Web Share Target POSTs
// Scope: /share-target/

self.addEventListener('install', (event) => {
  // Activate immediately so the share target works right after install
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Only handle our share target path
  if (url.pathname === '/share-target/' && event.request.method === 'POST') {
    event.respondWith((async () => {
      try {
        const formData = await event.request.formData();
        const title = formData.get('title') || '';
        const text = formData.get('text') || '';
        const sharedUrl = formData.get('url') || '';

        const params = new URLSearchParams();
        params.set('share_target', '1');
        if (title) params.set('title', title);
        if (text) params.set('text', text);
        if (sharedUrl) params.set('url', sharedUrl);

        // Redirect to the app with query params the Flutter app can read
        return Response.redirect('/?' + params.toString(), 303);
      } catch (e) {
        // On error, just open the app home
        return Response.redirect('/', 303);
      }
    })());
    return;
  }

  if (url.pathname === '/share-target/' && event.request.method === 'GET') {
    event.respondWith(Response.redirect('/', 303));
    return;
  }
});

const CACHE_NAME = 'songsplit-v2';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/icon-192x192.png',
  '/icons/icon-512x512.png'
];

// Install event - cache static assets individually so one bad response can't
// poison the cache (the hosting catch-all rewrite returns HTML with HTTP 200
// for missing paths, which cache.addAll would happily store as an "icon").
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) =>
        Promise.allSettled(
          STATIC_ASSETS.map(async (url) => {
            const response = await fetch(url);
            const type = response.headers.get('content-type') || '';
            if (!response.ok || (url.endsWith('.png') && !type.startsWith('image/'))) {
              throw new Error(`Skipping ${url}: ${response.status} ${type}`);
            }
            return cache.put(url, response);
          })
        )
      )
      .then((results) => {
        results.forEach((r) => {
          if (r.status === 'rejected') console.warn('Precache skip:', r.reason?.message || r.reason);
        });
      })
      .catch((err) => {
        console.error('Cache install failed:', err);
      })
  );
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      );
    })
  );
  self.clients.claim();
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }

  // Skip Supabase API requests (don't cache realtime data)
  if (url.hostname.includes('supabase.co')) {
    return;
  }

  // Strategy: Cache First, then Network
  event.respondWith(
    caches.match(request).then((cachedResponse) => {
      if (cachedResponse) {
        // Return cached version and update cache in background
        fetch(request)
          .then((networkResponse) => {
            if (networkResponse.ok) {
              caches.open(CACHE_NAME).then((cache) => {
                cache.put(request, networkResponse);
              });
            }
          })
          .catch(() => {
            // Network failed, cached version already returned
          });
        return cachedResponse;
      }

      // Not in cache, fetch from network
      return fetch(request)
        .then((networkResponse) => {
          if (!networkResponse || networkResponse.status !== 200) {
            return networkResponse;
          }

          // Cache the new response
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(request, responseToCache);
          });

          return networkResponse;
        })
        .catch((error) => {
          console.error('Fetch failed:', error);
          // Return offline fallback if available
          if (request.mode === 'navigate') {
            return caches.match('/index.html');
          }
          throw error;
        });
    })
  );
});

// Background sync for offline actions
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-collaborators') {
    event.waitUntil(syncCollaborators());
  }
});

// Push notifications (for session updates)
self.addEventListener('push', (event) => {
  const data = event.data.json();
  
  const options = {
    body: data.body || 'Session updated',
    icon: '/icons/icon-192x192.png',
    badge: '/icons/icon-72x72.png',
    tag: data.sessionId,
    data: data,
    actions: [
      {
        action: 'open',
        title: 'Open Session'
      },
      {
        action: 'close',
        title: 'Dismiss'
      }
    ]
  };

  event.waitUntil(
    self.registration.showNotification('SongSplit', options)
  );
});

// Notification click handler
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  if (event.action === 'open' || !event.action) {
    const sessionId = event.notification.data?.sessionId;
    const url = sessionId ? `/?session=${sessionId}` : '/';
    
    event.waitUntil(
      clients.openWindow(url)
    );
  }
});

// Helper function for background sync
async function syncCollaborators() {
  // This would sync any queued updates when coming back online
  // Implementation would depend on IndexedDB storage of pending changes
  console.log('Background sync triggered');
}

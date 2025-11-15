/**
 * Service Worker for Harvia MSGA
 * Handles background schedule execution and notifications for web platform
 */

const CACHE_NAME = "harvia-msga-v1";
const SCHEDULE_STORAGE_KEY = "harvia_schedules";

// Install event - cache critical assets
self.addEventListener("install", (event) => {
  console.log("Service Worker: Installing...");
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener("activate", (event) => {
  console.log("Service Worker: Activating...");
  event.waitUntil(self.clients.claim());
});

// Fetch event - serve from cache when offline
self.addEventListener("fetch", (event) => {
  // Network-first strategy for API calls
  if (event.request.url.includes("/api/")) {
    event.respondWith(
      fetch(event.request).catch(() => {
        return new Response(
          JSON.stringify({ error: "Offline - request queued" }),
          { headers: { "Content-Type": "application/json" } }
        );
      })
    );
  }
});

// Push notification event
self.addEventListener("push", (event) => {
  const data = event.data ? event.data.json() : {};
  const options = {
    body: data.body || "Sauna notification",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    vibrate: [200, 100, 200],
    data: data,
  };

  event.waitUntil(
    self.registration.showNotification(data.title || "Harvia MSGA", options)
  );
});

// Notification click event
self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow("/"));
});

// Background sync for schedule execution
self.addEventListener("sync", (event) => {
  if (event.tag === "execute-schedule") {
    event.waitUntil(executeScheduledTasks());
  }
});

// Periodic background sync for schedule checks (when supported)
self.addEventListener("periodicsync", (event) => {
  if (event.tag === "check-schedules") {
    event.waitUntil(checkAndExecuteSchedules());
  }
});

// Execute scheduled tasks
async function executeScheduledTasks() {
  console.log("Service Worker: Executing scheduled tasks...");
  // Implementation will be added in T096a
  // This will check schedules and send power/temperature commands
}

// Check and execute due schedules
async function checkAndExecuteSchedules() {
  console.log("Service Worker: Checking schedules...");
  // Implementation will be added in T096a
  // This will wake the app for schedule execution
}

/* eslint-disable no-restricted-globals, no-console */
/* globals clients */
// Take over right away so agents get the current handlers without having to
// close every Chatwoot tab first.
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', event => {
  event.waitUntil(clients.claim());
});

self.addEventListener('push', event => {
  let notification = event.data && event.data.json();

  event.waitUntil(
    self.registration.showNotification(notification.title, {
      body: notification.body,
      icon: '/android-icon-192x192.png',
      tag: notification.tag,
      data: {
        url: notification.url,
      },
    })
  );
});

// Focus an open Chatwoot tab and route it to the conversation; open one only
// when none is around.
self.addEventListener('notificationclick', event => {
  event.notification.close();
  const { url } = event.notification.data;

  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then(windowClients => {
        const appWindow = windowClients.find(client =>
          client.url.startsWith(self.location.origin)
        );
        if (appWindow) {
          appWindow.postMessage({ type: 'navigate', url });
          return appWindow.focus();
        }
        return clients.openWindow(url);
      })
  );
});

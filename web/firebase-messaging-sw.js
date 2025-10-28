/* eslint-disable no-undef */
// Firebase Cloud Messaging service worker for Flutter web
// This file must be at the root of your hosted site: /firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.2/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in the
// messagingSenderId. The rest of the config is optional for FCM.
firebase.initializeApp({
  messagingSenderId: '525011825099',
});

const messaging = firebase.messaging();

// Optional: handle background messages
messaging.onBackgroundMessage((payload) => {
  // Customize notification here if needed
  const notificationTitle = payload.notification?.title || 'JobScaffold';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

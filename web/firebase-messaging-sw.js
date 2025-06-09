// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyALVaUXzWOn3fP2PjsxXXkdd2UC_Om4dGc",
  authDomain: "xabe-ai.firebaseapp.com",
  projectId: "xabe-ai",
  storageBucket: "xabe-ai.firebasestorage.app",
  messagingSenderId: "428700861857",
  appId: "1:428700861857:web:996ae3b1b7050392dbf7e0",
});

const messaging = firebase.messaging();

// Optional: Handle background push notification clicks
self.addEventListener('notificationclick', function (event) {
  const clickAction = event.notification.data?.click_action || '/';
  event.notification.close();
  event.waitUntil(clients.openWindow(clickAction));
});

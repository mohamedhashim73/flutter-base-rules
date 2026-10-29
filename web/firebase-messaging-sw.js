/* Credexa background notification worker. A VAPID key must be configured in
 * Firebase Console and passed to FirebaseMessaging.register for token-based
 * push delivery; in-app notifications remain available without it. */
importScripts('https://www.gstatic.com/firebasejs/11.10.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.10.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD2v-I6xF2_n0SfNnMGuJ1rlbLm0P-yc-U',
  authDomain: 'credixa-422a1.firebaseapp.com',
  projectId: 'credixa-422a1',
  storageBucket: 'credixa-422a1.firebasestorage.app',
  messagingSenderId: '676825012432',
  appId: '1:676825012432:web:72cc3063a12db1dbc3a6d5',
});

firebase.messaging();

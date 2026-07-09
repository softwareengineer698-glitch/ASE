importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDIqoro3Q0pS-BkmDyHhd5LucTMF4SoIx8',
  authDomain: 'foodbank1-49283.firebaseapp.com',
  databaseURL: 'https://foodbank1-49283-default-rtdb.firebaseio.com',
  projectId: 'foodbank1-49283',
  storageBucket: 'foodbank1-49283.firebasestorage.app',
  messagingSenderId: '824249688083',
  appId: '1:824249688083:web:949a8aa1fd61f16c5b1fe6',
  measurementId: 'G-TDVPDH32TF',
});

firebase.messaging();

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyClOuAsC987LyI3b1mXqHRVTfG_iZrYi-0',
    appId: '1:717797446075:web:scanner',
    messagingSenderId: '717797446075',
    projectId: 'scanner-4bd39',
    authDomain: 'scanner-4bd39.firebaseapp.com',
    storageBucket: 'scanner-4bd39.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyClOuAsC987LyI3b1mXqHRVTfG_iZrYi-0',
    appId: '1:717797446075:android:ea2d5be0edd378df53749e',
    messagingSenderId: '717797446075',
    projectId: 'scanner-4bd39',
    storageBucket: 'scanner-4bd39.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAMstQOO6Gpgn1P5zJmYKIXIE1eTtSwRgE',
    appId: '1:717797446075:ios:0453f8aab42d222253749e',
    messagingSenderId: '717797446075',
    projectId: 'scanner-4bd39',
    iosBundleId: 'com.example.scanner',
    storageBucket: 'scanner-4bd39.firebasestorage.app',
  );

  static const FirebaseOptions macos = ios;
}

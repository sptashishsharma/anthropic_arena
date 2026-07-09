import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for the anthropic-arena project.
///
/// Web and Android apps are registered (July 2026). iOS is not registered
/// yet — add it in the console (or with `flutterfire configure`) before
/// shipping that platform, then fill in its options below.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS app not registered with Firebase yet — see FIREBASE_SETUP.md.',
        );
      default:
        throw UnsupportedError('Platform not configured for Firebase.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD2Fgu6hEdz9BCLDP-L3Z7rTSdESKMLBEs',
    appId: '1:1076701512218:android:8a9ddc364ac411363447a3',
    messagingSenderId: '1076701512218',
    projectId: 'anthropic-arena',
    storageBucket: 'anthropic-arena.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAF4tUJd1h969w0Q-V-6Q5WBWrIUa0fLEY',
    authDomain: 'anthropic-arena.firebaseapp.com',
    projectId: 'anthropic-arena',
    storageBucket: 'anthropic-arena.firebasestorage.app',
    messagingSenderId: '1076701512218',
    appId: '1:1076701512218:web:8b627e8daaa3c5083447a3',
    measurementId: 'G-9J1LS62BJ7',
  );
}

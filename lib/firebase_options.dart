import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for the anthropic-arena project.
///
/// Web config registered in the Firebase console (July 2026). Android and
/// iOS apps are not registered yet — add them in the console (or with
/// `flutterfire configure`) before shipping those platforms, then fill in
/// their options below.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'Android app not registered with Firebase yet — see FIREBASE_SETUP.md.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS app not registered with Firebase yet — see FIREBASE_SETUP.md.',
        );
      default:
        throw UnsupportedError('Platform not configured for Firebase.');
    }
  }

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

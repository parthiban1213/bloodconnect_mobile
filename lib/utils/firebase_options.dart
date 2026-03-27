// ─────────────────────────────────────────────────────────────
//  firebase_options.dart
//  Manually generated from google-services.json.
//  Values taken from:
//    project_id   : hsblood-a4cd7
//    app_id       : 1:587504872144:android:a8c1fa42ce31f67515ccd5
//    api_key      : AIzaSyDnkrQkhLZ7xiW3U_jR6D79gS-PwXh6-7c
//    gcm_sender_id: 587504872144
// ─────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyDnkrQkhLZ7xiW3U_jR6D79gS-PwXh6-7c',
    appId:             '1:587504872144:android:a8c1fa42ce31f67515ccd5',
    messagingSenderId: '587504872144',
    projectId:         'hsblood-a4cd7',
    storageBucket:     'hsblood-a4cd7.firebasestorage.app',
  );

  // iOS — fill these in if you add an iOS app to Firebase later
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyDnkrQkhLZ7xiW3U_jR6D79gS-PwXh6-7c',
    appId:             '1:587504872144:android:a8c1fa42ce31f67515ccd5',
    messagingSenderId: '587504872144',
    projectId:         'hsblood-a4cd7',
    storageBucket:     'hsblood-a4cd7.firebasestorage.app',
    iosBundleId:       'com.hsblood.bloodconnect',
  );

  // Web — fill these in if you add a web app to Firebase later
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyDnkrQkhLZ7xiW3U_jR6D79gS-PwXh6-7c',
    appId:             '1:587504872144:android:a8c1fa42ce31f67515ccd5',
    messagingSenderId: '587504872144',
    projectId:         'hsblood-a4cd7',
    storageBucket:     'hsblood-a4cd7.firebasestorage.app',
  );
}

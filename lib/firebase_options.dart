import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBUda5XRtKPPcC0L3UipQm0FmD0bwt0vCk',
    authDomain: 'royal-4366a.firebaseapp.com',
    projectId: 'royal-4366a',
    storageBucket: 'royal-4366a.firebasestorage.app',
    messagingSenderId: '102173797511',
    appId: '1:102173797511:web:a04d2532e2cd2e21d6dc22',
    measurementId: 'G-H0EGER5TNJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBUda5XRtKPPcC0L3UipQm0FmD0bwt0vCk',
    appId: '1:102173797511:android:ced037ebd70ce70fd6dc22',
    messagingSenderId: '102173797511',
    projectId: 'royal-4366a',
    storageBucket: 'royal-4366a.firebasestorage.app',
  );
}
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Enterprise-grade Default Firebase Options for Home Care.
///
/// Fitur Utama:
/// 1. Graceful platform handling dengan [isSupported] dan [currentPlatformOrNull]
///    untuk mencegah crash [UnsupportedError] pada platform desktop / test runners.
/// 2. Multi-environment ready via compile-time `--dart-define` dengan fallback aman.
/// 3. Cross-platform ready (Android, Web, dan iOS configuration placeholder).
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  /// Mengecek apakah platform saat ini didukung oleh konfigurasi Firebase.
  static bool get isSupported {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  /// Getter aman yang mengembalikan [FirebaseOptions] jika platform didukung,
  /// atau `null` jika tidak didukung (mencegah crash unhandled exception).
  static FirebaseOptions? get currentPlatformOrNull {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return null;
    }
  }

  /// Getter aktif untuk platform saat ini.
  /// Melempar [UnsupportedError] jika platform tidak didukung.
  static FirebaseOptions get currentPlatform {
    final options = currentPlatformOrNull;
    if (options != null) return options;

    throw UnsupportedError(
      'DefaultFirebaseOptions tidak didukung untuk platform: $defaultTargetPlatform.',
    );
  }

  // --- Environment Overrides (Compile-time Dart-Defines dengan default fallback) ---
  static const String _envProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'royal-4366a',
  );
  static const String _envSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '102173797511',
  );
  static const String _envStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'royal-4366a.firebasestorage.app',
  );

  /// Konfigurasi Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'AIzaSyBUda5XRtKPPcC0L3UipQm0FmD0bwt0vCk',
    ),
    authDomain: 'royal-4366a.firebaseapp.com',
    projectId: _envProjectId,
    storageBucket: _envStorageBucket,
    messagingSenderId: _envSenderId,
    appId: '1:102173797511:web:a04d2532e2cd2e21d6dc22',
    measurementId: 'G-H0EGER5TNJ',
  );

  /// Konfigurasi Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'AIzaSyBUda5XRtKPPcC0L3UipQm0FmD0bwt0vCk',
    ),
    appId: '1:102173797511:android:ced037ebd70ce70fd6dc22',
    messagingSenderId: _envSenderId,
    projectId: _envProjectId,
    storageBucket: _envStorageBucket,
  );

  /// Konfigurasi iOS (Siap pakai ketika sertifikat APNs & Apple Developer diintegrasikan)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_IOS_API_KEY',
      defaultValue: 'AIzaSyBUda5XRtKPPcC0L3UipQm0FmD0bwt0vCk',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_IOS_APP_ID',
      defaultValue: '1:102173797511:ios:placeholder',
    ),
    messagingSenderId: _envSenderId,
    projectId: _envProjectId,
    storageBucket: _envStorageBucket,
    iosBundleId: 'com.example.homeCare',
  );
}

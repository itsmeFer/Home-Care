import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_care/core/config/firebase_options.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/core/theme/app_theme.dart';
import 'package:home_care/core/widgets/app_error_boundary.dart';
import 'package:home_care/features/auth/presentation/screens/login.dart';
import 'package:home_care/features/auth/presentation/screens/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

// Re-export RootAuthGate for backward compatibility
export 'package:home_care/features/auth/presentation/screens/root_auth_gate.dart';

/// Global Navigation Key untuk routing di luar BuildContext (misal: 401 interceptor).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Global Error Handlers (Mencegah silent crash)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[PlatformError] $error');
    return true;
  };

  // 2. Inisialisasi Firebase (dengan platform guard)
  if (DefaultFirebaseOptions.isSupported) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[Firebase] Berhasil diinisialisasi.');
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint('[Firebase] Aplikasi sudah terinisialisasi.');
      } else {
        debugPrint('[Firebase] Init error: ${e.message}');
      }
    } catch (e) {
      debugPrint('[Firebase] Error tak terduga: $e');
    }
  } else {
    debugPrint('[Firebase] Platform tidak didukung, inisialisasi dilewati.');
  }

  // 3. Inisialisasi Locale Formatting Indonesia
  await initializeDateFormatting('id_ID', null);

  // 4. Interceptor Sesi Kedaluwarsa (401 Unauthorized)
  ApiClient.onUnauthorized = () async {
    debugPrint('[Auth] Sesi berakhir (401). Menghapus kredensial dan kembali ke Login.');
    await StorageService.clearAuth();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  };

  // 5. Bootstrap UI (DevicePreview hanya aktif di debug mode non-release)
  runApp(
    DevicePreview(
      enabled: !kReleaseMode && kDebugMode,
      builder: (context) => const MyApp(),
    ),
  );
}

/// Root Widget Aplikasi Home Care
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRIMA HomeCare',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        final current = DevicePreview.appBuilder(context, child);
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return AppErrorBoundary(errorDetails: errorDetails);
        };
        return current;
      },
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

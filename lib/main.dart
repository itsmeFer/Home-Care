import 'dart:convert';

import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_care/ITDev/dashboard_it_page.dart';
import 'package:home_care/admin/dashboard.dart';
import 'package:home_care/direktur/direktur_dashboard.dart';
import 'package:home_care/kordinator/dashboard.dart';
import 'package:home_care/manager/manager_dashboard.dart';
import 'package:home_care/perawat/dashboard.dart';
import 'package:home_care/screen/SplashScreen.dart';
import 'package:home_care/screen/login.dart';
import 'package:home_care/services/firebase_notification_service.dart';
import 'package:home_care/users/HomePage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint('⚠️ Firebase already initialized');
    } else {
      debugPrint('❌ Firebase init error: $e');
    }
  } catch (e) {
    debugPrint('❌ Unknown Firebase init error: $e');
  }

  await initializeDateFormatting('id_ID', null);

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}

class RootAuthGate extends StatefulWidget {
  const RootAuthGate({super.key});

  @override
  State<RootAuthGate> createState() => _RootAuthGateState();
}

class _RootAuthGateState extends State<RootAuthGate> {
  static const String baseUrl = 'http://147.93.81.243/api';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _decideStartPage();
  }

  Future<void> _decideStartPage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      debugPrint('⚠️ Auth token tidak ada, arahkan ke login');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (res.statusCode != 200) {
        debugPrint('⚠️ Token invalid / expired. Status: ${res.statusCode}');
        await prefs.remove('auth_token');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        return;
      }

      final body = jsonDecode(res.body);
      final data = body['data'] as Map<String, dynamic>? ?? {};

      await prefs.setInt('user_id', (data['user_id'] ?? 0) as int);
      await prefs.setInt('pasien_id', (data['pasien_id'] ?? 0) as int);
      await prefs.setInt('perawat_id', (data['perawat_id'] ?? 0) as int);
      await prefs.setInt('koordinator_id', (data['koordinator_id'] ?? 0) as int);

      await prefs.setString(
        'nama_lengkap',
        (data['nama_lengkap'] ?? '').toString(),
      );
      await prefs.setString(
        'email',
        (data['email'] ?? '').toString(),
      );
      await prefs.setString(
        'no_rekam_medis',
        (data['no_rekam_medis'] ?? '').toString(),
      );

      final roleData =
          data['role']?.toString().toLowerCase() ??
          data['user']?['role']?.toString().toLowerCase() ??
          '';

      await prefs.setString('role', roleData);

      if (!kIsWeb) {
        try {
          final notifService = FirebaseNotificationService();
          await notifService.initialize();
          await notifService.syncTokenToBackend();
          debugPrint('✅ Firebase Notification initialized after auth check');
        } catch (e) {
          debugPrint('❌ Notification init error: $e');
        }
      }

      Widget nextPage;

      switch (roleData) {
        case 'admin':
          nextPage = const AdminDashboard();
          break;
        case 'koordinator':
          nextPage = const KoordinatorDashboard();
          break;
        case 'perawat':
          nextPage = const PerawatDashboard();
          break;
        case 'direktur':
          nextPage = const DirekturDashboard();
          break;
        case 'manager':
          nextPage = const ManagerDashboard();
          break;
        case 'it':
          nextPage = const ITDevDashboard();
          break;
        case 'pasien':
          nextPage = const HomePage();
          break;
        default:
          debugPrint('⚠️ Role tidak dikenali: $roleData');
          await prefs.remove('auth_token');
          nextPage = const LoginPage();
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } catch (e) {
      debugPrint('❌ Error checking auth: $e');
      await prefs.remove('auth_token');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
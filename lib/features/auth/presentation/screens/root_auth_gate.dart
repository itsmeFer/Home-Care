import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_care/ITDev/dashboard_it_page.dart';
import 'package:home_care/admin/dashboard.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/services/firebase_notification_service.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/direktur/direktur_dashboard.dart';
import 'package:home_care/features/auth/presentation/screens/login.dart';
import 'package:home_care/kordinator/dashboard.dart';
import 'package:home_care/manager/manager_dashboard.dart';
import 'package:home_care/perawat/dashboard.dart';
import 'package:home_care/users/home.dart';

/// RootAuthGate bertanggung jawab menentukan halaman awal pengguna:
/// 1. Verifikasi validitas token sesi lokal.
/// 2. Mengambil profil terkini (`/me`) dari backend.
/// 3. Inisialisasi token push notification (non-web).
/// 4. Mengarahkan pengguna ke dashboard yang sesuai dengan peran (role).
class RootAuthGate extends StatefulWidget {
  const RootAuthGate({super.key});

  @override
  State<RootAuthGate> createState() => _RootAuthGateState();
}

class _RootAuthGateState extends State<RootAuthGate> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _decideStartPage();
  }

  Future<void> _decideStartPage() async {
    final token = await StorageService.getToken();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      debugPrint('[AuthGate] Token tidak ditemukan, mengarahkan ke LoginPage.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    final prefs = await StorageService.instance;

    try {
      final body = await ApiClient.get('/me');

      if (!mounted) return;

      final data = (body is Map && body['data'] is Map)
          ? body['data'] as Map<String, dynamic>
          : (body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{});

      await prefs.setInt('user_id', (data['user_id'] ?? 0) as int);
      await prefs.setInt('pasien_id', (data['pasien_id'] ?? 0) as int);
      await prefs.setInt('perawat_id', (data['perawat_id'] ?? 0) as int);
      await prefs.setInt('koordinator_id', (data['koordinator_id'] ?? 0) as int);

      await prefs.setString('nama_lengkap', (data['nama_lengkap'] ?? '').toString());
      await prefs.setString('email', (data['email'] ?? '').toString());
      await prefs.setString('no_rekam_medis', (data['no_rekam_medis'] ?? '').toString());

      final roleData =
          data['role']?.toString().toLowerCase() ??
          data['user']?['role']?.toString().toLowerCase() ??
          '';

      await StorageService.saveRole(roleData);

      if (!kIsWeb) {
        try {
          final notifService = FirebaseNotificationService();
          await notifService.initialize();
          await notifService.syncTokenToBackend();
          debugPrint('[Notification] Berhasil sinkronisasi token notifikasi.');
        } catch (e) {
          debugPrint('[Notification] Gagal inisialisasi notifikasi: $e');
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
          debugPrint('[AuthGate] Role tidak dikenali ($roleData), mengarahkan ke LoginPage.');
          await StorageService.clearAuth();
          nextPage = const LoginPage();
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } catch (e) {
      debugPrint('[AuthGate] Error validasi autentikasi: $e');
      await StorageService.clearAuth();

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
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

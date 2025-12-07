import 'package:flutter/material.dart';
import 'package:home_care/chat/perawat_chat_list_page.dart';
import 'package:home_care/perawat/lihatOrderanMasuk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/screen/login.dart';
import 'package:home_care/perawat/profil.dart'; // ⬅️ TAMBAH INI

class PerawatDashboard extends StatelessWidget {
  const PerawatDashboard({super.key});

  /// ============================
  /// LOGOUT FUNCTION
  /// ============================
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('perawat_id');
    await prefs.remove('nama_lengkap');
    await prefs.remove('role');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Dashboard Perawat'),
        backgroundColor: const Color(0xFF0BA5A7),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          const Center(
            child: Text(
              'Selamat datang di Dashboard Perawat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 24),

          // ============================
          // TOMBOL MENUJU PROFIL PERAWAT
          // ============================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PerawatProfilPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline),
                label: const Text(
                  'Lihat Profil Perawat',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0BA5A7),
                  side: const BorderSide(color: Color(0xFF0BA5A7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ============================
          // TOMBOL ORDERAN BARU
          // ============================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LihatOrderanMasukPerawatPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline),
                label: const Text(
                  'Lihat Orderan Baru',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0BA5A7),
                  side: const BorderSide(color: Color(0xFF0BA5A7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PerawatChatListPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline),
                label: const Text(
                  'Lihat Chat Masuk',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0BA5A7),
                  side: const BorderSide(color: Color(0xFF0BA5A7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),

          /// ============================
          /// TOMBOL LOGOUT
          /// ============================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/chat/koordinator_chat_list_page.dart';
import 'package:home_care/kordinator/lihatOrderanMasuk.dart';
import 'package:home_care/users/HomePage.dart';
import 'package:home_care/kordinator/kelolaPerawat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/screen/login.dart'; // pastikan ini benar

class KoordinatorDashboard extends StatelessWidget {
  const KoordinatorDashboard({super.key});

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HCColor.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================
  /// LOGOUT FUNCTION
  /// ============================
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // Arahkan kembali ke login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        title: const Text('Koordinator Dashboard'),
        backgroundColor: HCColor.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ============================
            /// MENU: KELOLA PERAWAT
            /// ============================
            _menuItem(
              icon: Icons.person_search,
              label: 'Kelola Perawat',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KelolaPerawatPage()),
                );
              },
            ),

            /// ============================
            /// MENU: LIHAT ORDERAN MASUK
            /// ============================
            _menuItem(
              icon: Icons.person_search,
              label: 'Lihat Orderan Masuk',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LihatOrderanMasukKoordinatorPage(),
                  ),
                );
              },
            ),

            /// ============================
            /// MENU: CHAT PASIEN
            /// ============================
            _menuItem(
              icon: Icons.chat,
              label: 'Chat dengan Pasien',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const KoordinatorChatListPage(),
                  ),
                );
              },
            ),

            const Spacer(),

            /// ============================
            /// TOMBOL LOGOUT
            /// ============================
            GestureDetector(
              onTap: () => _logout(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

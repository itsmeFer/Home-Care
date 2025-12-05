import 'package:flutter/material.dart';
import 'package:home_care/admin/kelolaKordinator.dart';
import 'package:home_care/admin/kelolaLayanan.dart';
import 'package:home_care/admin/lihatLayananMasuk.dart';
import 'package:home_care/admin/lihatPerawat.dart';   // ⬅️ TAMBAHKAN INI
import 'package:home_care/users/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/screen/login.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: HCColor.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // -----------------------------
            // Kelola Layanan
            // -----------------------------
            _menuItem(
              icon: Icons.medical_services,
              label: 'Kelola Layanan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KelolaLayananPage()),
                );
              },
            ),

            // -----------------------------
            // Kelola Koordinator
            // -----------------------------
            _menuItem(
              icon: Icons.person_pin_circle,
              label: 'Kelola Koordinator',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrudKordinatorPage()),
                );
              },
            ),

            // -----------------------------
            // 🔥 NEW BUTTON: Lihat Semua Perawat
            // -----------------------------
            _menuItem(
              icon: Icons.people_alt,
              label: 'Lihat Semua Perawat',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LihatPerawatPage()),
                );
              },
            ),
            // -----------------------------
            // Kelola Koordinator
            // -----------------------------
            _menuItem(
              icon: Icons.person_pin_circle,
              label: 'Lihat Layanan Masuk',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LihatLayananMasukPage()),
                );
              },
            ),
            // -----------------------------
            // Logout
            // -----------------------------
            _menuItem(
              icon: Icons.logout,
              label: 'Logout',
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

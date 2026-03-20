import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Import dengan ALIAS untuk menghindari konflik
import 'package:home_care/admin/lihatLayananMasuk.dart' as admin;

// Import pages lainnya
import 'package:home_care/admin/crudRole.dart';
import 'package:home_care/admin/crud_add-ons.dart';
import 'package:home_care/admin/crud_banner.dart';
import 'package:home_care/admin/crud_perawat.dart';
import 'package:home_care/admin/kelolaFee.dart';
import 'package:home_care/admin/kelolaKordinator.dart';
import 'package:home_care/admin/kelolaLayanan.dart';
import 'package:home_care/admin/lapor_it.dart';
import 'package:home_care/admin/lihatCatatanFee.dart';
import 'package:home_care/admin/lihatPerawat.dart';
import 'package:home_care/screen/login.dart';
import 'package:home_care/users/HomePage.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_DashboardMenu> menus = [
      _DashboardMenu(
        title: 'Kelola Layanan',
        icon: Icons.medical_services_rounded,
        page: const KelolaLayananPage(),
      ),
      _DashboardMenu(
        title: 'Kelola Add-Ons',
        icon: Icons.add_box_rounded,
        page: const CrudAddOnsPage(),
      ),
      _DashboardMenu(
        title: 'Kelola Koordinator',
        icon: Icons.person_pin_circle_rounded,
        page: const CrudKordinatorPage(),
      ),
      _DashboardMenu(
        title: 'Lihat Semua Perawat',
        icon: Icons.people_alt_rounded,
        page: const LihatPerawatPage(),
      ),
      _DashboardMenu(
        title: 'Lihat Layanan Masuk',
        icon: Icons.inbox_rounded,
        page: const admin.LihatLayananMasukPage(), // ✅ Pakai alias
      ),
      _DashboardMenu(
        title: 'Kelola Banner',
        icon: Icons.branding_watermark_rounded,
        page: const CrudBannerPage(),
      ),
      _DashboardMenu(
        title: 'Kelola Role',
        icon: Icons.admin_panel_settings_rounded,
        page: const CrudRolePage(),
      ),
      _DashboardMenu(
        title: 'Kelola Fee',
        icon: Icons.currency_exchange_rounded,
        page: const KelolaFeePage(),
      ),
      _DashboardMenu(
        title: 'Lapor IT',
        icon: Icons.report_problem_rounded,
        page: const LaporITPageAdmin(),
      ),
      _DashboardMenu(
        title: 'Lihat Catatan Fee',
        icon: Icons.receipt_long_rounded,
        page: const LihatCatatanFeePage(),
      ),
      _DashboardMenu(
        title: 'Kelola Perawat',
        icon: Icons.local_hospital_rounded,
        page: const CrudPerawatPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            _SimpleHeader(
              onLogout: () => _logout(context),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth >= 700) {
                    crossAxisCount = 3;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: menus.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.08,
                    ),
                    itemBuilder: (context, index) {
                      final item = menus[index];
                      return _MenuCard(
                        title: item.title,
                        icon: item.icon,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => item.page),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  final VoidCallback onLogout;

  const _SimpleHeader({
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HCColor.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HCColor.primary.withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.dashboard_customize_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola semua menu admin dengan cepat',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE9EEF5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: HCColor.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: HCColor.primary,
                  size: 23,
                ),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Buka menu',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A94A6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMenu {
  final String title;
  final IconData icon;
  final Widget page;

  _DashboardMenu({
    required this.title,
    required this.icon,
    required this.page,
  });
}
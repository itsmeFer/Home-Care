import 'package:flutter/material.dart';
import 'package:home_care/admin/crud_addons.dart';
import 'package:home_care/admin/crud_banner.dart';
import 'package:home_care/admin/crud_kategori.dart';
import 'package:home_care/admin/crud_perawat.dart';
import 'package:home_care/admin/crud_role.dart';
import 'package:home_care/admin/dashboard/models/admin_dashboard_models.dart';
import 'package:home_care/admin/dashboard/services/admin_dashboard_service.dart';
import 'package:home_care/admin/dashboard/widgets/admin_dashboard_header.dart';
import 'package:home_care/admin/dashboard/widgets/dashboard_menu_card.dart';
import 'package:home_care/admin/dashboard/widgets/dashboard_summary_card.dart';
import 'package:home_care/admin/dashboard/widgets/role_stats_section.dart';
import 'package:home_care/admin/dashboard/widgets/role_users_sheet.dart';
import 'package:home_care/admin/kelola_fee.dart';
import 'package:home_care/admin/kelola_kordinator.dart';
import 'package:home_care/admin/kelola_layanan.dart';
import 'package:home_care/admin/lapor_it.dart';
import 'package:home_care/admin/lihat_catatan_fee.dart';
import 'package:home_care/admin/lihat_layanan_masuk.dart' as admin;
import 'package:home_care/admin/lihat_perawat.dart';
import 'package:home_care/screen/login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoadingStats = true;
  String? _errorMessage;
  DashboardSummary _summary = const DashboardSummary();
  List<RoleStatItem> _roleStats = [];

  final List<DashboardMenu> _menus = const [
    DashboardMenu(
      title: 'Kelola Layanan',
      icon: Icons.medical_services_rounded,
      page: KelolaLayananPage(),
    ),
    DashboardMenu(
      title: 'Kelola Kategori',
      icon: Icons.category_rounded,
      page: CrudKategoriPage(),
    ),
    DashboardMenu(
      title: 'Kelola Add-Ons',
      icon: Icons.add_box_rounded,
      page: CrudAddOnsPage(),
    ),
    DashboardMenu(
      title: 'Kelola Koordinator',
      icon: Icons.person_pin_circle_rounded,
      page: CrudKordinatorPage(),
    ),
    DashboardMenu(
      title: 'Lihat Semua Perawat',
      icon: Icons.people_alt_rounded,
      page: LihatPerawatPage(),
    ),
    DashboardMenu(
      title: 'Lihat Layanan Masuk',
      icon: Icons.inbox_rounded,
      page: admin.LihatLayananMasukPage(),
    ),
    DashboardMenu(
      title: 'Kelola Banner',
      icon: Icons.branding_watermark_rounded,
      page: CrudBannerPage(),
    ),
    DashboardMenu(
      title: 'Kelola Role',
      icon: Icons.admin_panel_settings_rounded,
      page: CrudRolePage(),
    ),
    DashboardMenu(
      title: 'Kelola Fee',
      icon: Icons.currency_exchange_rounded,
      page: KelolaFeePage(),
    ),
    DashboardMenu(
      title: 'Lapor IT',
      icon: Icons.report_problem_rounded,
      page: LaporITPageAdmin(),
    ),
    DashboardMenu(
      title: 'Lihat Catatan Fee',
      icon: Icons.receipt_long_rounded,
      page: LihatCatatanFeePage(),
    ),
    DashboardMenu(
      title: 'Kelola Perawat',
      icon: Icons.local_hospital_rounded,
      page: CrudPerawatPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    setState(() {
      _isLoadingStats = true;
      _errorMessage = null;
    });

    try {
      final stats = await AdminDashboardService.fetchStatistics();
      if (mounted) {
        setState(() {
          _summary = stats.summary;
          _roleStats = stats.roleStats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingStats = false;
        });
      }
    }
  }

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

    await AdminDashboardService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            AdminDashboardHeader(onLogout: () => _logout(context)),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchStatistics,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    DashboardSummaryCard(
                      isLoading: _isLoadingStats,
                      errorMessage: _errorMessage,
                      summary: _summary,
                      onRefresh: _fetchStatistics,
                    ),
                    const SizedBox(height: 14),
                    RoleStatsSection(
                      isLoading: _isLoadingStats,
                      roleStats: _roleStats,
                      onTapRole: (slug, name) {
                        RoleUsersSheet.show(
                          context,
                          roleSlug: slug,
                          roleName: name,
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Menu Admin',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2;
                        if (constraints.maxWidth >= 700) {
                          crossAxisCount = 3;
                        }

                        return GridView.builder(
                          itemCount: _menus.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.04,
                          ),
                          itemBuilder: (context, index) {
                            final item = _menus[index];
                            return DashboardMenuCard(
                              title: item.title,
                              icon: item.icon,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => item.page,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
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

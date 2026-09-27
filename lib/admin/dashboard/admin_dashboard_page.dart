import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/crud_addons_page.dart';
import 'package:home_care/admin/banners/crud_banner_page.dart';
import 'package:home_care/admin/dashboard/models/admin_dashboard_models.dart';
import 'package:home_care/admin/dashboard/services/admin_dashboard_service.dart';
import 'package:home_care/admin/dashboard/widgets/admin_dashboard_header.dart';
import 'package:home_care/admin/dashboard/widgets/dashboard_menu_card.dart';
import 'package:home_care/admin/dashboard/widgets/dashboard_summary_card.dart';
import 'package:home_care/admin/dashboard/widgets/role_stats_section.dart';
import 'package:home_care/admin/dashboard/widgets/role_users_sheet.dart';
import 'package:home_care/admin/fee/kelola_fee_page.dart';
import 'package:home_care/admin/fee/lihat_catatan_fee_page.dart';
import 'package:home_care/admin/kategori/crud_kategori_page.dart';
import 'package:home_care/admin/kordinator/crud_kordinator_page.dart';
import 'package:home_care/admin/layanan/kelola_layanan_page.dart';
import 'package:home_care/admin/layanan_masuk/lihat_layanan_masuk_page.dart' as admin;
import 'package:home_care/admin/perawat/crud_perawat_page.dart';
import 'package:home_care/admin/perawat/lihat_perawat_page.dart';
import 'package:home_care/admin/role/crud_role_page.dart';
import 'package:home_care/admin/support_it/lapor_it_page.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/auth/presentation/screens/login.dart';

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
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin keluar dari akun admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                color: AppColors.primary,
                onRefresh: _fetchStatistics,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final int crossAxisCount =
                              constraints.crossAxisExtent >= 700 ? 3 : 2;

                          return SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.04,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
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
                              childCount: _menus.length,
                            ),
                          );
                        },
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

// ManagerDashboard.dart (IMPROVED MOBILE) ✅
// ✅ UI mirip DirekturDashboard dengan mobile layout yang RAPI
// ✅ Top Bar mobile vertikal: Menu+Title di atas, Range di bawah
// ✅ Bottom Nav dengan height tetap dan SafeArea
// ✅ Mobile Menu (Bottom Sheet) lengkap dengan logout
// ✅ Responsive padding dan spacing yang konsisten

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:home_care/manager/pages/audit_page.dart';
import 'package:home_care/manager/pages/kelola_perawat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'pages/overview_page.dart';
import 'package:home_care/manager/pages/keuangan_page.dart';
import 'pages/tim_page.dart';
import 'pages/lapor_it.dart'; // ✅ Import Lapor IT
import 'package:home_care/screen/login.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  // ====== SHADCN-LIKE PALETTE ======
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);
  static const Color kPrimary = Color(0xFF0EA5E9);

  int _tabIndex = 0;

  final List<String> _ranges = const [
    'Hari ini',
    '7 hari',
    '30 hari',
    'Bulan ini',
  ];
  String _range = '7 hari';

  String _userName = '...';
  Key _pageAnimKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  void _setTab(int i) {
    if (i == _tabIndex) return;
    setState(() {
      _tabIndex = i;
      _pageAnimKey = UniqueKey();
    });
  }

  void _setRange(String v) {
    if (v == _range) return;
    setState(() {
      _range = v;
      _pageAnimKey = UniqueKey();
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Logout?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text('Kamu akan keluar dari akun ini.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('role_slug');
    await prefs.remove('user_role');
    await prefs.remove('name');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _loadMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
            .trim();

    final localName = (prefs.getString('name') ?? '').trim();
    if (mounted && localName.isNotEmpty) setState(() => _userName = localName);

    if (token.isEmpty) {
      if (mounted && _userName.trim().isEmpty) {
        setState(() => _userName = 'Manager');
      }
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('http://192.168.1.6:8000/api/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        final name = _pickName(body);
        if (mounted) setState(() => _userName = name);
      } else {
        if (mounted && _userName.trim().isEmpty) {
          setState(() => _userName = 'Manager');
        }
      }
    } catch (_) {
      if (mounted && _userName.trim().isEmpty) {
        setState(() => _userName = 'Manager');
      }
    }
  }

  String _pickName(dynamic body) {
    dynamic root = body;
    if (root is Map && root['data'] != null) root = root['data'];

    if (root is Map) {
      final direct = root['name'] ?? root['nama'] ?? root['nama_lengkap'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString().trim();
      }

      final u = root['user'];
      if (u is Map) {
        final nested = u['name'] ?? u['nama'] ?? u['nama_lengkap'];
        if (nested != null && nested.toString().trim().isNotEmpty) {
          return nested.toString().trim();
        }
      }
    }
    return 'Manager';
  }

  String _titleForTab(int i) {
    switch (i) {
      case 0:
        return 'Overview';
      case 1:
        return 'Keuangan';
      case 2:
        return 'Kinerja Tim';
      case 3:
        return 'Kelola Perawat';
      case 4:
        return 'Audit';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildTabPage(
    int i, {
    required String range,
    required bool isDesktop,
    required bool isTablet,
  }) {
    switch (i) {
      case 0:
        return ManagerOverviewPage(
          isDesktop: isDesktop,
          isTablet: isTablet,
          range: range,
        );
      case 1:
        return ManagerKeuanganPage(
          isDesktop: isDesktop,
          isTablet: isTablet,
          range: range,
        );
      case 2:
        return TimPage(isDesktop: isDesktop, isTablet: isTablet, range: range);
      case 3:
        return KelolaPerawatPage(
          isDesktop: isDesktop,
          isTablet: isTablet,
        );
      case 4:
        return AuditPageManager(
          isDesktop: isDesktop,
          isTablet: isTablet,
          range: range,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isDesktop = w >= 1100;
    final bool isTablet = w >= 760 && w < 1100;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              _Sidebar(
                selectedIndex: _tabIndex,
                userName: _userName,
                onSelect: _setTab,
                onLogout: _logout,
              ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: _titleForTab(_tabIndex),
                    rangeValue: _range,
                    ranges: _ranges,
                    onRangeChanged: _setRange,
                    userName: _userName,
                    onLogout: _logout,
                    onOpenMenu: isDesktop
                        ? null
                        : () => showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => _MobileMenu(
                              selectedIndex: _tabIndex,
                              userName: _userName,
                              onSelect: (i) {
                                _setTab(i);
                                Navigator.pop(context);
                              },
                              onLogout: () {
                                Navigator.pop(context);
                                _logout();
                              },
                            ),
                          ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 22 : (isTablet ? 16 : 12),
                        isDesktop ? 10 : 8,
                        isDesktop ? 22 : (isTablet ? 16 : 12),
                        18,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) {
                          final fade = CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOut,
                          );
                          final slide =
                              Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                          return FadeTransition(
                            opacity: fade,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: _pageAnimKey,
                          child: _buildTabPage(
                            _tabIndex,
                            range: _range,
                            isDesktop: isDesktop,
                            isTablet: isTablet,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _BottomNav(index: _tabIndex, onChanged: _setTab),
    );
  }
}

/* ============================================================
  TOP BAR - RESPONSIVE MOBILE/DESKTOP
============================================================ */
class _TopBar extends StatelessWidget {
  final String title;
  final String rangeValue;
  final List<String> ranges;
  final ValueChanged<String> onRangeChanged;
  final VoidCallback? onOpenMenu;
  final String userName;
  final VoidCallback onLogout;

  const _TopBar({
    required this.title,
    required this.rangeValue,
    required this.ranges,
    required this.onRangeChanged,
    required this.userName,
    required this.onLogout,
    this.onOpenMenu,
  });

  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 760;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: kCard.withOpacity(.92),
        border: const Border(bottom: BorderSide(color: kBorder)),
      ),
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Baris 1: Menu + Title + Avatar
                Row(
                  children: [
                    if (onOpenMenu != null)
                      IconButton(
                        onPressed: onOpenMenu,
                        icon: const Icon(Icons.menu_rounded),
                        tooltip: 'Menu',
                        iconSize: 22,
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: kText,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Manager Suite',
                            style: TextStyle(
                              color: kMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _AvatarChipMobile(
                      name: userName,
                      onTap: onOpenMenu ?? () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Baris 2: Range Selector (Mobile Segmented Control)
                _MobileRangeSelector(
                  value: rangeValue,
                  items: ranges,
                  onChanged: onRangeChanged,
                ),
              ],
            )
          : Row(
              children: [
                if (onOpenMenu != null)
                  IconButton(
                    onPressed: onOpenMenu,
                    icon: const Icon(Icons.menu_rounded),
                    tooltip: 'Menu',
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: kText,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'HomeCare • Manager Dashboard',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _GhostButton(
                    icon: Icons.search_rounded, label: 'Cari', onTap: () {}),
                const SizedBox(width: 8),
                _Select(
                    value: rangeValue, items: ranges, onChanged: onRangeChanged),
                const SizedBox(width: 8),
                _AvatarChip(
                    name: userName, subtitle: 'Manager Access', onTap: () {}),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onLogout,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Color(0xFF334155),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Keluar',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: 12.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* ============================================================
  MOBILE RANGE SELECTOR (SEGMENTED CONTROL)
============================================================ */
class _MobileRangeSelector extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _MobileRangeSelector({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kPrimary = Color(0xFF0EA5E9);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: items.map((item) {
          final selected = item == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: selected
                      ? Border.all(color: kPrimary.withOpacity(0.3))
                      : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  item,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? kPrimary : kMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/* ============================================================
  SIDEBAR (DESKTOP)
============================================================ */
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String userName;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.userName,
    required this.onLogout,
  });

  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);
  static const Color kPrimary = Color(0xFF0EA5E9);
  static const Color kDanger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(right: BorderSide(color: kBorder)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _BrandHeader(name: userName),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: kBorder),
          const SizedBox(height: 10),
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: 'Overview',
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            icon: Icons.account_balance_outlined,
            label: 'Keuangan',
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          _NavItem(
            icon: Icons.groups_outlined,
            label: 'Kinerja Tim',
            selected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
          _NavItem(
            icon: Icons.medical_services_outlined,
            label: 'Kelola Perawat',
            selected: selectedIndex == 3,
            onTap: () => onSelect(3),
          ),
          _NavItem(
            icon: Icons.shield_outlined,
            label: 'Audit',
            selected: selectedIndex == 4,
            onTap: () => onSelect(4),
          ),
          
          const SizedBox(height: 8),
          const Divider(height: 1, color: kBorder),
          const SizedBox(height: 8),
          
          // ✅ Menu Lapor IT
          _NavItem(
            icon: Icons.support_agent_rounded,
            label: 'Lapor IT',
            selected: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LaporITPageManager(),
                ),
              );
            },
          ),
          
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFECACA)),
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFFEF2F2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: kDanger),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontSize: 12.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444)),
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

class _BrandHeader extends StatelessWidget {
  final String name;
  const _BrandHeader({required this.name});

  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final displayName =
        (name.trim().isEmpty || name == '...') ? 'Manager' : name;

    return Row(
      children: [
        SizedBox(
          height: 44,
          width: 44,
          child: Image.asset(
            'assets/images/home_nobg.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  color: kText,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              const Text(
                'Manager Suite',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);
  static const Color kPrimary = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? const Color(0xFFE0F2FE) : Colors.transparent,
            border: Border.all(
              color: selected ? const Color(0xFFBAE6FD) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? kPrimary : kMuted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? kText : kMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.2,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
  BOTTOM NAV (MOBILE/TABLET) - IMPROVED
============================================================ */
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _BottomNav({required this.index, required this.onChanged});

  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kMuted = Color(0xFF64748B);
  static const Color kPrimary = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        border: const Border(top: BorderSide(color: kBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.dashboard_outlined,
                label: 'Overview',
                selected: index == 0,
                onTap: () => onChanged(0),
              ),
              _BottomNavItem(
                icon: Icons.account_balance_outlined,
                label: 'Keuangan',
                selected: index == 1,
                onTap: () => onChanged(1),
              ),
              _BottomNavItem(
                icon: Icons.groups_outlined,
                label: 'Tim',
                selected: index == 2,
                onTap: () => onChanged(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color kMuted = Color(0xFF64748B);
  static const Color kPrimary = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? kPrimary : kMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? kPrimary : kMuted,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
  MOBILE MENU (BOTTOM SHEET) - IMPROVED
============================================================ */
class _MobileMenu extends StatelessWidget {
  final int selectedIndex;
  final String userName;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _MobileMenu({
    required this.selectedIndex,
    required this.userName,
    required this.onSelect,
    required this.onLogout,
  });

  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);
  static const Color kPrimary = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: kCard.withOpacity(.98),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                height: 5,
                width: 46,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),

              // Header dengan Avatar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFE0F2FE),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: kPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (userName.trim().isEmpty || userName == '...')
                                ? 'Manager'
                                : userName,
                            style: const TextStyle(
                              color: kText,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Manager Suite',
                            style: TextStyle(
                              color: kMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Menu Title
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Menu Manager',
                  style: TextStyle(
                    color: kText,
                    fontSize: 14.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Menu Items
              _menuItem(0, Icons.dashboard_outlined, 'Overview'),
              _menuItem(1, Icons.account_balance_outlined, 'Keuangan'),
              _menuItem(2, Icons.groups_outlined, 'Kinerja Tim'),
              _menuItem(3, Icons.medical_services_outlined, 'Kelola Perawat'),
              _menuItem(4, Icons.shield_outlined, 'Audit'),

              const SizedBox(height: 8),
              const Divider(height: 1, color: kBorder),
              const SizedBox(height: 8),

              // ✅ Menu Lapor IT
              InkWell(
                onTap: () {
                  Navigator.pop(context); // Close menu first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LaporITPageManager(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                    color: const Color(0xFFE0F2FE),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        color: kPrimary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lapor IT',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: kText,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: kPrimary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Logout Button
              InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                    color: const Color(0xFFFEF2F2),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(int i, IconData icon, String label) {
    final bool selected = selectedIndex == i;
    return InkWell(
      onTap: () => onSelect(i),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFBAE6FD) : kBorder,
          ),
          color: selected ? const Color(0xFFE0F2FE) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? kPrimary : kMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: selected ? kText : const Color(0xFF334155),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: selected ? kPrimary : const Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
  SMALL UI COMPONENTS
============================================================ */
class _Select extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _Select({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF64748B)),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 12.8,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const _AvatarChip({
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  static const Color kBorder = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFE0F2FE),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child:
                  const Icon(Icons.person_outline, color: Color(0xFF0284C7)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (name.trim().isEmpty || name == '...') ? 'Manager' : name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 12.8,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarChipMobile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _AvatarChipMobile({
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFE0F2FE),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: const Icon(
          Icons.medical_services_outlined,
          color: Color(0xFF0284C7),
          size: 20,
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          color: const Color(0xFFF8FAFC),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 12.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
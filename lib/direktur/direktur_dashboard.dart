import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:home_care/direktur/pages/lapor_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'pages/overview_page.dart';
import 'pages/keuangan_page.dart';
import 'pages/tim_page.dart';
import 'pages/pasien_page.dart';
import 'pages/audit_page.dart';
import 'package:home_care/screen/login.dart';

class DirekturDashboard extends StatefulWidget {
  const DirekturDashboard({super.key});

  @override
  State<DirekturDashboard> createState() => _DirekturDashboardState();
}

class _DirekturDashboardState extends State<DirekturDashboard> {
  // ====== SHADCN-LIKE PALETTE (CLEAN / ELEGANT) ======
  static const Color kBg = Color(0xFFF8FAFC); // slate-50
  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0); // slate-200
  static const Color kText = Color(0xFF0F172A); // slate-900
  static const Color kMuted = Color(0xFF64748B); // slate-500
  static const Color kPrimary = Color(0xFF0EA5E9); // sky-500

  int _tabIndex = 0;

  final List<String> _ranges = const [
    'Hari ini',
    '7 hari',
    'Bulan ini',
    'Tahun ini',
  ];
  String _range = 'Bulan ini';

  // ✅ Nama user login
  String _userName = '...';

  // ✅ KUNCI: supaya tiap ganti TAB / RANGE halaman di-recreate -> chart replay animasi
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
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();

    // ✅ hapus token + data role/user (biar bersih)
    await prefs.remove('auth_token');
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('role_slug');
    await prefs.remove('user_role');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _openLaporIT() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LaporITPage()),
    );
  }

  Future<void> _loadMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
            .trim();

    if (token.isEmpty) {
      if (mounted) setState(() => _userName = 'Direktur');
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('http://192.168.1.5:8000/api/me'),
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
        if (mounted) setState(() => _userName = 'Direktur');
      }
    } catch (_) {
      if (mounted) setState(() => _userName = 'Direktur');
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
    return 'Direktur';
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
                    onOpenMenu: isDesktop
                        ? null
                        : () => showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
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
                        isDesktop ? 22 : 16,
                        10,
                        isDesktop ? 22 : 16,
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

  String _titleForTab(int i) {
    switch (i) {
      case 0:
        return 'Executive Overview';
      case 1:
        return 'Laporan Keuangan';
      case 2:
        return 'Kinerja Tim';
      case 3:
        return 'Pasien & Insight';
      case 4:
        return 'Audit & Control';
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
        return OverviewPage(
          isDesktop: isDesktop,
          isTablet: isTablet,
          range: range,
        );
      case 1:
        return KeuanganPage(
          isDesktop: isDesktop,
          isTablet: isTablet,
          range: range,
        );
      case 2:
        return TimPage(isDesktop: isDesktop, isTablet: isTablet, range: range);
      case 3:
        return PasienPage(
          isDesktop: isDesktop,
          isTablet: isTablet,
          range: range,
        );
      case 4:
        return AuditPage(
          isDesktop: isDesktop,
          isTablet: isTablet,
          range: range,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/* ============================================================
  TOP BAR - FULLY RESPONSIVE
============================================================ */
class _TopBar extends StatelessWidget {
  final String title;
  final String rangeValue;
  final List<String> ranges;
  final ValueChanged<String> onRangeChanged;
  final VoidCallback? onOpenMenu;
  final String userName;

  const _TopBar({
    required this.title,
    required this.rangeValue,
    required this.ranges,
    required this.onRangeChanged,
    required this.userName,
    this.onOpenMenu,
  });

  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 8 : 14,
        isMobile ? 8 : 12,
        isMobile ? 8 : 14,
        isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: kCard.withOpacity(.92),
        border: const Border(bottom: BorderSide(color: kBorder)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Menu + Title
                Row(
                  children: [
                    if (onOpenMenu != null)
                      IconButton(
                        onPressed: onOpenMenu,
                        icon: const Icon(Icons.menu_rounded, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (onOpenMenu != null) const SizedBox(width: 8),
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
                            'HomeCare • Dashboard',
                            style: TextStyle(
                              color: kMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 2: Select + Avatar (scrollable jika perlu)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Select(
                        value: rangeValue,
                        items: ranges,
                        onChanged: onRangeChanged,
                      ),
                      const SizedBox(width: 8),
                      _AvatarChip(
                        name: userName,
                        subtitle: 'Direktur',
                        onTap: () {},
                      ),
                    ],
                  ),
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
                if (onOpenMenu != null) const SizedBox(width: 6),
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
                        'HomeCare • Executive Dashboard',
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
                  icon: Icons.search_rounded,
                  label: 'Cari',
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                _Select(
                  value: rangeValue,
                  items: ranges,
                  onChanged: onRangeChanged,
                ),
                const SizedBox(width: 8),
                _AvatarChip(
                  name: userName,
                  subtitle: 'All Access',
                  onTap: () {},
                ),
              ],
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
            icon: Icons.people_alt_outlined,
            label: 'Pasien & Insight',
            selected: selectedIndex == 3,
            onTap: () => onSelect(3),
          ),
          _NavItem(
            icon: Icons.security_outlined,
            label: 'Audit & Control',
            selected: selectedIndex == 4,
            onTap: () => onSelect(4),
          ),
          _NavItem(
            icon: Icons.support_agent_outlined,
            label: 'Hubungi IT',
            selected: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LaporITPage()),
            ),
          ),

          const Spacer(),

          // ✅ Logout Button
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
                child: Row(
                  children: const [
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
    final displayName = (name.trim().isEmpty || name == '...')
        ? 'Direktur'
        : name;

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
                'Executive Suite',
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
              Icon(icon, color: selected ? kPrimary : kMuted),
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
  BOTTOM NAV (MOBILE/TABLET)
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
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: BottomNavigationBar(
        currentIndex: index,
        onTap: onChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: kCard,
        selectedItemColor: kPrimary,
        unselectedItemColor: kMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined, size: 22),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_outlined, size: 22),
            label: 'Keuangan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined, size: 22),
            label: 'Tim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined, size: 22),
            label: 'Pasien',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security_outlined, size: 22),
            label: 'Audit',
          ),
        ],
      ),
    );
  }
}

/* ============================================================
  MOBILE MENU - WITH LOGOUT
============================================================ */
class _MobileMenu extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String userName;
  final VoidCallback onLogout;

  const _MobileMenu({
    required this.selectedIndex,
    required this.onSelect,
    required this.userName,
    required this.onLogout,
  });

  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kDanger = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: kCard.withOpacity(.95),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 46,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Menu Direktur - $userName',
                    style: const TextStyle(
                      color: kText,
                      fontSize: 14.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _menuItem(context, 0, Icons.dashboard_outlined, 'Overview'),
                _menuItem(
                  context,
                  1,
                  Icons.account_balance_outlined,
                  'Keuangan',
                ),
                _menuItem(context, 2, Icons.groups_outlined, 'Kinerja Tim'),
                _menuItem(
                  context,
                  3,
                  Icons.people_alt_outlined,
                  'Pasien & Insight',
                ),
                _menuItem(
                  context,
                  4,
                  Icons.security_outlined,
                  'Audit & Control',
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: kBorder),
                const SizedBox(height: 8),
                // ✅ Logout Button
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
                    child: Row(
                      children: const [
                        Icon(Icons.logout_rounded, color: kDanger),
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
      ),
    );
  }

  Widget _menuItem(BuildContext context, int i, IconData icon, String label) {
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
              color: selected
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF334155),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
  SMALL UI: SELECT, AVATAR CHIP, BUTTONS - RESPONSIVE
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
        color: const Color(0xFFFFFFFF),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF64748B), size: 20),
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
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 10,
          vertical: isMobile ? 6 : 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: isMobile ? 28 : 34,
              width: isMobile ? 28 : 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFE0F2FE),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Icon(
                Icons.person_outline,
                color: const Color(0xFF0284C7),
                size: isMobile ? 16 : 18,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: isMobile ? 11.5 : 12.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 10.5 : 11.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
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
          mainAxisSize: MainAxisSize.min,
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
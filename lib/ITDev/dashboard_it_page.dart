import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/dashboard_it_page.dart';
import 'pages/audit_sistem_page.dart';
import 'pages/user_monitor_page.dart';
import 'pages/support_ticket_page.dart';
import 'pages/system_maintenance_page.dart';
import 'pages/session_token_page.dart';

// ✅ sesuaikan path login kamu
import 'package:home_care/screen/login.dart';

class ITDevDashboard extends StatefulWidget {
  const ITDevDashboard({super.key});

  @override
  State<ITDevDashboard> createState() => _ITDevDashboardState();
}

class _ITDevDashboardState extends State<ITDevDashboard> {
  // ====== SHADCN-LIKE PALETTE ======
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
    '30 hari',
    'Bulan ini',
  ];
  String _range = '7 hari';

  String _userName = 'IT';
  Key _pageAnimKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadMeLocal();
  }

  Future<void> _loadMeLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final localName = (prefs.getString('name') ?? '').trim();
    if (mounted && localName.isNotEmpty) setState(() => _userName = localName);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
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

  String _titleForTab(int i) {
    switch (i) {
      case 0:
        return 'Dashboard IT';
      case 1:
        return 'Audit Sistem';
      case 2:
        return 'User Monitor';
      case 3:
        return 'Support Ticket';
      case 4:
        return 'System Maintenance';
      case 5:
        return 'Session & Token';
      default:
        return 'IT Suite';
    }
  }

  Widget _buildTabPage(int i,
      {required String range,
      required bool isDesktop,
      required bool isTablet}) {
    switch (i) {
      case 0:
        return DashboardITPage(
            isDesktop: isDesktop, isTablet: isTablet, range: range);
      case 1:
        return AuditSistemPage(
            isDesktop: isDesktop, isTablet: isTablet, range: range);
      case 2:
        return UserMonitorPage(
            isDesktop: isDesktop, isTablet: isTablet, range: range);
      case 3:
        return SupportTicketPage(
            isDesktop: isDesktop, isTablet: isTablet, range: range);
      case 4:
        return SystemMaintenancePage(
            isDesktop: isDesktop, isTablet: isTablet, range: range);
      case 5:
        return SessionTokenPage(
            isDesktop: isDesktop, isTablet: isTablet, range: range);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isDesktop = w >= 1100;
    final bool isTablet = w >= 760 && w < 1100;
    final bool isMobile = w < 760;

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
                  // ✅ Top Bar yang sudah diperbaiki untuk mobile
                  _TopBar(
                    title: _titleForTab(_tabIndex),
                    rangeValue: _range,
                    ranges: _ranges,
                    onRangeChanged: _setRange,
                    userName: _userName,
                    isMobile: isMobile,
                    onLogout: _logout,
                    onOpenMenu: isDesktop
                        ? null
                        : () => _showMobileMenu(context),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 12 : (isDesktop ? 22 : 16),
                        isMobile ? 8 : 10,
                        isMobile ? 12 : (isDesktop ? 22 : 16),
                        isMobile ? 12 : 18,
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
                          final slide = Tween<Offset>(
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

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
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
    );
  }
}

/* ============================================================
  TOP BAR - DIPERBAIKI UNTUK MOBILE
============================================================ */
class _TopBar extends StatelessWidget {
  final String title;
  final String rangeValue;
  final List<String> ranges;
  final ValueChanged<String> onRangeChanged;
  final VoidCallback? onOpenMenu;
  final VoidCallback onLogout;
  final String userName;
  final bool isMobile;

  const _TopBar({
    required this.title,
    required this.rangeValue,
    required this.ranges,
    required this.onRangeChanged,
    required this.userName,
    required this.onLogout,
    required this.isMobile,
    this.onOpenMenu,
  });

  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      // ✅ MOBILE: Layout vertikal yang lebih rapi
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: kCard,
          border: const Border(bottom: BorderSide(color: kBorder)),
        ),
        child: Column(
          children: [
            // Baris 1: Menu + Title
            Row(
              children: [
                if (onOpenMenu != null)
                  IconButton(
                    onPressed: onOpenMenu,
                    icon: const Icon(Icons.menu_rounded, size: 22),
                    tooltip: 'Menu',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                if (onOpenMenu != null) const SizedBox(width: 4),
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
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'IT Security & Support',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Baris 2: Range Selector (Full Width)
            _MobileRangeSelector(
              value: rangeValue,
              items: ranges,
              onChanged: onRangeChanged,
            ),
          ],
        ),
      );
    }

    // ✅ TABLET/DESKTOP: Layout horizontal seperti sebelumnya
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: kCard.withOpacity(.92),
        border: const Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
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
                  'HomeCare • IT Security & Support',
                  style: TextStyle(
                    color: kMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _Select(value: rangeValue, items: ranges, onChanged: onRangeChanged),
          const SizedBox(width: 8),
          _AvatarChip(name: userName, subtitle: 'IT Access', onTap: () {}),
          const SizedBox(width: 8),
          InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
                color: const Color(0xFFF8FAFC),
              ),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: Color(0xFF334155)),
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
  MOBILE RANGE SELECTOR
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
  static const Color kMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = item == value;
          final isFirst = item == items.first;
          final isLast = item == items.last;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(11) : Radius.zero,
                    right: isLast ? const Radius.circular(11) : Radius.zero,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item,
                  style: TextStyle(
                    color: isSelected ? Colors.white : kMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
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
      width: 292,
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
            icon: Icons.monitor_heart_outlined,
            label: 'Dashboard IT',
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            icon: Icons.policy_outlined,
            label: 'Audit Sistem',
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          _NavItem(
            icon: Icons.manage_accounts_outlined,
            label: 'User Monitor',
            selected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
          _NavItem(
            icon: Icons.support_agent_outlined,
            label: 'Support Ticket',
            selected: selectedIndex == 3,
            onTap: () => onSelect(3),
          ),
          _NavItem(
            icon: Icons.build_circle_outlined,
            label: 'Maintenance',
            selected: selectedIndex == 4,
            onTap: () => onSelect(4),
          ),
          _NavItem(
            icon: Icons.vpn_key_outlined,
            label: 'Session & Token',
            selected: selectedIndex == 5,
            onTap: () => onSelect(5),
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
    final displayName = (name.trim().isEmpty) ? 'IT' : name;
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
              ),
              const SizedBox(height: 2),
              const Text(
                'IT Suite',
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
  BOTTOM NAV (MOBILE/TABLET) - DIPERBAIKI
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
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.monitor_heart_outlined, 'Health'),
              _buildNavItem(1, Icons.policy_outlined, 'Audit'),
              _buildNavItem(2, Icons.manage_accounts_outlined, 'Users'),
              _buildNavItem(3, Icons.support_agent_outlined, 'Ticket'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int idx, IconData icon, String label) {
    final isSelected = index == idx;

    return Expanded(
      child: InkWell(
        onTap: () => onChanged(idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? kPrimary : kMuted,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? kPrimary : kMuted,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ============================================================
  MOBILE MENU - DIPERBAIKI
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
  static const Color kMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: kCard.withOpacity(.98),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SafeArea(
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

                // Header dengan avatar
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFE0F2FE),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF0284C7),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.isEmpty ? 'IT' : userName,
                              style: const TextStyle(
                                color: kText,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'IT Suite',
                              style: TextStyle(
                                color: kMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Menu items
                _menuItem(context, 0, Icons.monitor_heart_outlined, 'Dashboard IT'),
                _menuItem(context, 1, Icons.policy_outlined, 'Audit Sistem'),
                _menuItem(context, 2, Icons.manage_accounts_outlined, 'User Monitor'),
                _menuItem(context, 3, Icons.support_agent_outlined, 'Support Ticket'),
                _menuItem(context, 4, Icons.build_circle_outlined, 'Maintenance'),
                _menuItem(context, 5, Icons.vpn_key_outlined, 'Session & Token'),

                const SizedBox(height: 12),
                const Divider(height: 1, color: kBorder),
                const SizedBox(height: 12),

                // Logout
                _actionItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: const Color(0xFFEF4444),
                  backgroundColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    int i,
    IconData icon,
    String label,
  ) {
    final bool selected = selectedIndex == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onSelect(i),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: selected ? kText : const Color(0xFF334155),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: selected
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          color: backgroundColor,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
  SMALL UI: SELECT, AVATAR CHIP
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
          icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF64748B)),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 12.8,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => v == null ? null : onChanged(v),
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
              child: const Icon(Icons.shield_outlined, color: Color(0xFF0284C7)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (name.trim().isEmpty) ? 'IT' : name,
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
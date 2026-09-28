import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_care/features/auth/data/auth_repository.dart';
import 'package:home_care/features/auth/presentation/screens/login.dart';
import 'package:home_care/perawat/chat/perawat_chat_list_page.dart';
import 'package:home_care/perawat/lapor_it/lapor_it_page.dart';
import 'package:home_care/perawat/orderan/lihat_orderan_masuk_page.dart';
import 'package:home_care/perawat/profil/profil_page.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'services/dashboard_service.dart';

class PerawatDashboard extends StatefulWidget {
  const PerawatDashboard({super.key});

  @override
  State<PerawatDashboard> createState() => _PerawatDashboardState();
}

class _PerawatDashboardState extends State<PerawatDashboard> {
  final ValueNotifier<int> _chatUnread = ValueNotifier<int>(0);
  final ValueNotifier<int> _orderUnread = ValueNotifier<int>(0);

  bool _isLoadingBadge = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    _loadBadges();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _startPolling();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _chatUnread.dispose();
    _orderUnread.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadBadges(silent: true);
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    await AuthRepository().logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _loadBadges({bool silent = false}) async {
    if (_isLoadingBadge && !silent) return;

    _isLoadingBadge = true;

    try {
      final results = await Future.wait([
        PerawatDashboardService.getChatUnread(),
        PerawatDashboardService.getOrderUnread(),
      ]);

      if (mounted) {
        _chatUnread.value = results[0];
        _orderUnread.value = results[1];
        _isLoadingBadge = false;
      }
    } catch (e) {
      debugPrint('LOAD PERAWAT BADGES ERROR: $e');
      if (mounted) {
        _isLoadingBadge = false;
      }
    }
  }

  Widget _buildBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();

    final text = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color color,
    required String title,
    int count = 0,
    ValueNotifier<int>? countListenable,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HCColor.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            if (countListenable != null)
              ValueListenableBuilder<int>(
                valueListenable: countListenable,
                builder: (_, val, __) => Text(
                  '$val',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              )
            else
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: HCColor.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int badgeCount = 0,
    ValueNotifier<int>? badgeListenable,
    Color color = HCColor.primary,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HCColor.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                if (badgeListenable != null)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: ValueListenableBuilder<int>(
                      valueListenable: badgeListenable,
                      builder: (_, count, __) => _buildBadge(count),
                    ),
                  )
                else if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: _buildBadge(badgeCount),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      body: RefreshIndicator(
        onRefresh: () => _loadBadges(silent: false),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 54, 20, 26),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [HCColor.primary, HCColor.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Dashboard Perawat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: Listenable.merge([_chatUnread, _orderUnread]),
                        builder: (context, _) {
                          final totalBadge = _chatUnread.value + _orderUnread.value;
                          if (totalBadge <= 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              totalBadge > 99 ? '99+' : '$totalBadge',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),

                      IconButton(
                        onPressed: () {
                          debugPrint('ðŸ”„ Manual Refresh Perawat Badge');
                          _loadBadges(silent: false);
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh Badge',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pantau orderan masuk, chat pasien, dan kelola aktivitas harian Anda.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (_isLoadingBadge) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Memuat notifikasi...',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _summaryCard(
                        icon: Icons.assignment_outlined,
                        color: Colors.orange,
                        title: 'Orderan Aktif',
                        countListenable: _orderUnread,
                      ),
                      const SizedBox(width: 12),
                      _summaryCard(
                        icon: Icons.chat_bubble_outline,
                        color: HCColor.primary,
                        title: 'Chat Belum Dibaca',
                        countListenable: _chatUnread,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _menuItem(
                    icon: Icons.person_outline,
                    label: 'Lihat Profil Perawat',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PerawatProfilPage(),
                        ),
                      );
                      _loadBadges(silent: true);
                    },
                  ),

                  _menuItem(
                    icon: Icons.assignment_outlined,
                    label: 'Lihat Orderan Baru',
                    badgeListenable: _orderUnread,
                    color: Colors.orange,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LihatOrderanMasukPerawatPage(),
                        ),
                      );

                      _loadBadges(silent: false);
                    },
                  ),

                  _menuItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Lihat Chat Masuk',
                    badgeListenable: _chatUnread,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PerawatChatListPage(),
                        ),
                      );

                      _loadBadges(silent: false);
                    },
                  ),

                  _menuItem(
                    icon: Icons.report_problem_outlined,
                    label: 'Lapor IT / Lapor Masalah',
                    color: Colors.redAccent,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LaporITPagePerawat(),
                        ),
                      );
                      _loadBadges(silent: true);
                    },
                  ),

                  const SizedBox(height: 10),

                  AnimatedBuilder(
                    animation: Listenable.merge([_chatUnread, _orderUnread]),
                    builder: (context, _) {
                      final chatCount = _chatUnread.value;
                      final orderCount = _orderUnread.value;
                      if (chatCount <= 0 && orderCount <= 0) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications_active,
                                  size: 18,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Ringkasan Aktivitas',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (orderCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Ada $orderCount orderan yang perlu ditangani.',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (chatCount > 0)
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: HCColor.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ada $chatCount pesan chat yang belum dibaca.',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
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
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

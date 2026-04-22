import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/chat/koordinator_chat_list_page.dart';
import 'package:home_care/kordinator/kelolaPerawat.dart';
import 'package:home_care/kordinator/lapor_it.dart';
import 'package:home_care/kordinator/lihatOrderanMasuk.dart';
import 'package:home_care/screen/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HCColor {
  static const primary = Color(0xFF0BA5A7);
  static const primaryDark = Color(0xFF088088);
  static const bg = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textMuted = Colors.black54;
}

class KoordinatorDashboard extends StatefulWidget {
  const KoordinatorDashboard({super.key});

  @override
  State<KoordinatorDashboard> createState() => _KoordinatorDashboardState();
}

class _KoordinatorDashboardState extends State<KoordinatorDashboard> {
  static const String kBaseUrl = 'http://192.168.1.5:8000/api';

  int _chatUnreadCount = 0;
  int _orderUnreadCount = 0;

  bool _isLoadingBadge = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Load badges pertama kali
    _loadBadges();
    // Start polling setelah delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _startPolling();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? prefs.getString('token');
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('koordinator_id');
    await prefs.remove('nama_lengkap');
    await prefs.remove('role');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _loadBadges({bool silent = false}) async {
    // Prevent multiple simultaneous loads
    if (_isLoadingBadge && !silent) return;

    if (!silent && mounted) {
      setState(() {
        _isLoadingBadge = true;
      });
    } else {
      _isLoadingBadge = true;
    }

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ TOKEN NOT FOUND');
        if (mounted) {
          setState(() {
            _chatUnreadCount = 0;
            _orderUnreadCount = 0;
            _isLoadingBadge = false;
          });
        }
        return;
      }

      debugPrint('🔄 Loading badges...');

      // Fetch both in parallel
      final results = await Future.wait([
        _fetchChatUnread(token),
        _fetchOrderUnread(token),
      ]);

      final chatUnread = results[0];
      final orderUnread = results[1];

      debugPrint('✅ Chat Unread: $chatUnread');
      debugPrint('✅ Order Unread: $orderUnread');

      if (mounted) {
        setState(() {
          _chatUnreadCount = chatUnread;
          _orderUnreadCount = orderUnread;
          _isLoadingBadge = false;
        });
      }
    } catch (e) {
      debugPrint('❌ LOAD KOORDINATOR BADGES ERROR: $e');

      if (mounted) {
        setState(() {
          _isLoadingBadge = false;
        });
      }
    }
  }

  Future<int> _fetchChatUnread(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/chat/unread-summary'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📨 Chat Unread Response: ${res.statusCode}');
      debugPrint('📨 Chat Unread Body: ${res.body}');

      if (res.statusCode != 200) return 0;

      final body = json.decode(res.body);
      
      // Handle different response formats
      if (body is Map) {
        if (body['success'] == true) {
          final data = body['data'];
          if (data is Map) {
            final totalUnread = data['total_unread'];
            if (totalUnread is int) return totalUnread;
            return int.tryParse(totalUnread?.toString() ?? '0') ?? 0;
          }
        }
        // Alternative format
        final totalUnread = body['total_unread'];
        if (totalUnread is int) return totalUnread;
        return int.tryParse(totalUnread?.toString() ?? '0') ?? 0;
      }

      return 0;
    } catch (e) {
      debugPrint('❌ FETCH KOORDINATOR CHAT UNREAD ERROR: $e');
      return 0;
    }
  }

  Future<int> _fetchOrderUnread(String token) async {
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/koordinator/order-layanan'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📦 Order Response: ${res.statusCode}');
      debugPrint('📦 Order Body: ${res.body}');

      if (res.statusCode != 200) return 0;

      final body = json.decode(res.body);

      List data = [];
      
      // Handle different response formats
      if (body is List) {
        data = body;
      } else if (body is Map<String, dynamic>) {
        if (body['success'] == true || body['success'] == 1) {
          final raw = body['data'];
          if (raw is List) {
            data = raw;
          }
        } else if (body['data'] is List) {
          data = body['data'];
        }
      }

      // Filter hanya status yang relevan untuk "orderan masuk"
      final relevantStatuses = [
        'pending',
        'menunggu_penugasan',
      ];

      final filteredData = data.where((item) {
        if (item is! Map) return false;
        final status = item['status_order']?.toString() ?? '';
        return relevantStatuses.contains(status);
      }).toList();

      debugPrint('📊 Total Orders: ${data.length}');
      debugPrint('📊 Filtered Orders (pending/menunggu): ${filteredData.length}');

      return filteredData.length;
    } catch (e) {
      debugPrint('❌ FETCH KOORDINATOR ORDER UNREAD ERROR: $e');
      return 0;
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
            color: Colors.red.withOpacity(0.3),
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
    required int count,
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
                if (badgeCount > 0)
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
    final totalBadge = _chatUnreadCount + _orderUnreadCount;

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
                          'Dashboard Koordinator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (totalBadge > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
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
                        ),
                      const SizedBox(width: 10),
                      // Debug button - hapus di production
                      IconButton(
                        onPressed: () {
                          debugPrint('🔄 Manual Refresh Badge');
                          _loadBadges(silent: false);
                        },
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                        ),
                        tooltip: 'Refresh Badge',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kelola perawat, orderan masuk, dan percakapan pasien dalam satu tempat.',
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
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
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
                        title: 'Orderan Masuk',
                        count: _orderUnreadCount,
                      ),
                      const SizedBox(width: 12),
                      _summaryCard(
                        icon: Icons.chat_bubble_outline,
                        color: HCColor.primary,
                        title: 'Chat Belum Dibaca',
                        count: _chatUnreadCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _menuItem(
                    icon: Icons.people_alt_outlined,
                    label: 'Kelola Perawat',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KelolaPerawatPage(),
                        ),
                      );
                      _loadBadges(silent: true);
                    },
                  ),

                  _menuItem(
                    icon: Icons.assignment_outlined,
                    label: 'Lihat Orderan Masuk',
                    badgeCount: _orderUnreadCount,
                    color: Colors.orange,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LihatOrderanMasukKoordinatorPage(),
                        ),
                      );
                      // Force refresh after returning
                      _loadBadges(silent: false);
                    },
                  ),

                  _menuItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat dengan Pasien',
                    badgeCount: _chatUnreadCount,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KoordinatorChatListPage(),
                        ),
                      );
                      // Force refresh after returning
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
                          builder: (_) => const LaporITPageKoordinator(),
                        ),
                      );
                      _loadBadges(silent: true);
                    },
                  ),

                  const SizedBox(height: 10),

                  if (_chatUnreadCount > 0 || _orderUnreadCount > 0)
                    Container(
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
                          if (_orderUnreadCount > 0)
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
                                      'Ada $_orderUnreadCount orderan masuk baru yang perlu ditangani.',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_chatUnreadCount > 0)
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
                                    'Ada $_chatUnreadCount pesan chat yang belum dibaca.',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
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
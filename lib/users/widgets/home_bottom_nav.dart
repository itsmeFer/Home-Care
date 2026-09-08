import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/chat/pasien_chat_list_page.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/users/home_page.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/lihat_histori_pemesanan.dart';
import 'package:home_care/users/profile.dart';

class HCBottomNav extends StatefulWidget {
  final int currentIndex;
  const HCBottomNav({super.key, this.currentIndex = 0});

  @override
  State<HCBottomNav> createState() => _HCBottomNavState();
}

class _HCBottomNavState extends State<HCBottomNav> {
  static const Color activeColor = AppColors.primary;
  static const Color inactiveColor = Color(0xFF94A3B8);

  int _chatUnreadCount = 0;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    _loadChatUnread();
    _startBadgePolling();
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  void _startBadgePolling() {
    _badgeTimer?.cancel();
    _badgeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadChatUnread();
    });
  }

  Future<void> _loadChatUnread() async {
    try {
      final body = await ApiClient.get('/chat/unread-summary');
      if (body is! Map || body['success'] != true) return;

      final data = body['data'] ?? {};
      final totalUnread = data['total_unread'];

      int parsedUnread = 0;
      if (totalUnread is int) {
        parsedUnread = totalUnread;
      } else {
        parsedUnread = int.tryParse(totalUnread.toString()) ?? 0;
      }

      if (!mounted) return;

      setState(() {
        _chatUnreadCount = parsedUnread;
      });
    } catch (_) {}
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    bool isActive, {
    int badgeCount = 0,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == widget.currentIndex) return;

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PilihLayananPage()),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PasienChatListPage()),
            ).then((_) {
              _loadChatUnread();
            });
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LihatHistoriPemesananPage(),
              ),
            );
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? activeColor.withValues(alpha: 0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      return ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.85,
                          end: 1.0,
                        ).animate(animation),
                        child: child,
                      );
                    },
                    child: Icon(
                      isActive ? activeIcon : icon,
                      key: ValueKey<bool>(isActive),
                      color: isActive ? activeColor : inactiveColor,
                      size: 24,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: 4,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4757),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4757).withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isActive ? activeColor : inactiveColor,
                fontSize: isActive ? 11 : 10.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              0,
              IconlyLight.home,
              IconlyBold.home,
              'Beranda',
              currentIndex == 0,
            ),
            _buildNavItem(
              1,
              IconlyLight.category,
              IconlyBold.category,
              'Layanan',
              currentIndex == 1,
            ),
            _buildNavItem(
              2,
              IconlyLight.chat,
              IconlyBold.chat,
              'Chat',
              currentIndex == 2,
              badgeCount: _chatUnreadCount,
            ),
            _buildNavItem(
              3,
              IconlyLight.document,
              IconlyBold.document,
              'Riwayat',
              currentIndex == 3,
            ),
            _buildNavItem(
              4,
              IconlyLight.profile,
              IconlyBold.profile,
              'Profil',
              currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }
}

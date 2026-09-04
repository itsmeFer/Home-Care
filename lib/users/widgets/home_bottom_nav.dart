import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/chat/pasien_chat_list_page.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/users/HomePage.dart';
import 'package:home_care/users/layananPage.dart';
import 'package:home_care/users/lihatHistoriPemesanan.dart';
import 'package:home_care/users/profile.dart';

class HCBottomNav extends StatefulWidget {
  final int currentIndex;
  const HCBottomNav({super.key, this.currentIndex = 0});

  @override
  State<HCBottomNav> createState() => _HCBottomNavState();
}

class _HCBottomNavState extends State<HCBottomNav> {
  static const Color activeColor = Color(0xFF0BA5A7);
  static const Color inactiveColor = Colors.black54;

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
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive ? const Color(0x150BA5A7) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isActive ? activeIcon : icon,
                      key: ValueKey<bool>(isActive),
                      color:
                          isActive ? const Color(0xFF0BA5A7) : Colors.grey[400],
                      size: isActive ? 26 : 24,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: 6,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive ? const Color(0xFF0BA5A7) : Colors.grey[500],
                fontSize: isActive ? 11 : 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              0,
              Icons.home_outlined,
              Icons.home,
              'Beranda',
              currentIndex == 0,
            ),
            _buildNavItem(
              1,
              Icons.medical_services_outlined,
              Icons.medical_services,
              'Layanan',
              currentIndex == 1,
            ),
            _buildNavItem(
              2,
              Icons.chat_bubble_outline,
              Icons.chat_bubble_rounded,
              'Chat',
              currentIndex == 2,
              badgeCount: _chatUnreadCount,
            ),
            _buildNavItem(
              3,
              Icons.history_outlined,
              Icons.history,
              'Riwayat',
              currentIndex == 3,
            ),
            _buildNavItem(
              4,
              Icons.person_outline,
              Icons.person,
              'Profil',
              currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }
}

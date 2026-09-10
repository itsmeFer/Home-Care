import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/users/home_page.dart';

class HCBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const HCBottomNav({super.key, this.currentIndex = 0, this.onTap});

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

  void _handleTap(int index) {
    if (widget.onTap != null) {
      widget.onTap!(index);
    } else {
      HomePage.switchTab(context, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 62.0;
    const double floatOverhang = 18.0;
    final double totalHeight = barHeight + floatOverhang + bottomPadding;
    final bool isChatActive = widget.currentIndex == 2;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Curved Background with Center Scoop Cradle
          Positioned.fill(
            child: CustomPaint(
              painter: _CurvedNavPainter(floatOverhang: floatOverhang),
            ),
          ),

          // 2. Navigation Items Row (Side items with center gap)
          Positioned(
            top: floatOverhang,
            left: 0,
            right: 0,
            height: barHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tab 0: Beranda (Home)
                Expanded(
                  child: _buildSideItem(
                    index: 0,
                    lightIcon: IconlyLight.home,
                    boldIcon: IconlyBold.home,
                  ),
                ),

                // Tab 1: Layanan (Star)
                Expanded(
                  child: _buildSideItem(
                    index: 1,
                    lightIcon: IconlyLight.star,
                    boldIcon: IconlyBold.star,
                  ),
                ),

                // Center Spacer for the floating Chat button and scooped cradle
                const SizedBox(width: 88.0),

                // Tab 3: Riwayat / Pesanan (Bell)
                Expanded(
                  child: _buildSideItem(
                    index: 3,
                    lightIcon: IconlyLight.notification,
                    boldIcon: IconlyBold.notification,
                  ),
                ),

                // Tab 4: Profil
                Expanded(
                  child: _buildSideItem(
                    index: 4,
                    lightIcon: IconlyLight.profile,
                    boldIcon: IconlyBold.profile,
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Elevated Center Action Button (Chat)
          Positioned(
            top: 1.0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _handleTap(2),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: 55.0,
                  height: 55.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isChatActive
                              ? const [
                                Color(0xFF22D3EE),
                                Color(0xFF0BA5A7),
                                Color(0xFF07767C),
                              ]
                              : const [
                                Color(0xFF2DD4BF),
                                Color(0xFF0BA5A7),
                                Color(0xFF097980),
                              ],
                    ),
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF0BA5A7,
                        ).withValues(alpha: isChatActive ? 0.48 : 0.35),
                        blurRadius: isChatActive ? 18.0 : 14.0,
                        offset: const Offset(0, 6.0),
                        spreadRadius: isChatActive ? 1.0 : 0.0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2.0),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedScale(
                          scale: isChatActive ? 1.10 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            isChatActive ? IconlyBold.chat : IconlyLight.chat,
                            color: Colors.white,
                            size: 25.0,
                          ),
                        ),
                        if (_chatUnreadCount > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 17,
                                minHeight: 17,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4757),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF4757,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 4.0,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Text(
                                _chatUnreadCount > 99
                                    ? '99+'
                                    : '$_chatUnreadCount',
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideItem({
    required int index,
    required IconData lightIcon,
    required IconData boldIcon,
  }) {
    final bool isActive = widget.currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(index),
        splashColor: activeColor.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            // Active top indicator pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: isActive ? 28.0 : 0.0,
              height: 3.5,
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            // Centered icon
            Expanded(
              child: Center(
                child: AnimatedScale(
                  scale: isActive ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isActive ? boldIcon : lightIcon,
                    color: isActive ? activeColor : inactiveColor,
                    size: 24.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4.0),
          ],
        ),
      ),
    );
  }
}

class _CurvedNavPainter extends CustomPainter {
  final double floatOverhang;

  _CurvedNavPainter({required this.floatOverhang});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    const double scoopHalfWidth = 44.0;
    const double scoopDepth = 22.0;
    final double top = floatOverhang;

    final Path path = Path();
    path.moveTo(0, top);
    path.lineTo(cx - scoopHalfWidth, top);

    // Smooth cubic curve down into the cradle
    path.cubicTo(
      cx - 24.0,
      top,
      cx - 26.0,
      top + scoopDepth,
      cx,
      top + scoopDepth,
    );

    // Smooth cubic curve up from the cradle
    path.cubicTo(
      cx + 26.0,
      top + scoopDepth,
      cx + 24.0,
      top,
      cx + scoopHalfWidth,
      top,
    );

    path.lineTo(w, top);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // 1. Soft elevated top shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.06), 10.0, true);

    // 2. Crisp solid white fill
    final Paint fillPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Subtle hairline border along top edge for crispness
    final Path strokePath = Path();
    strokePath.moveTo(0, top);
    strokePath.lineTo(cx - scoopHalfWidth, top);
    strokePath.cubicTo(
      cx - 24.0,
      top,
      cx - 26.0,
      top + scoopDepth,
      cx,
      top + scoopDepth,
    );
    strokePath.cubicTo(
      cx + 26.0,
      top + scoopDepth,
      cx + 24.0,
      top,
      cx + scoopHalfWidth,
      top,
    );
    strokePath.lineTo(w, top);

    final Paint strokePaint =
        Paint()
          ..color = const Color(0xFFF1F5F9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedNavPainter oldDelegate) =>
      oldDelegate.floatOverhang != floatOverhang;
}

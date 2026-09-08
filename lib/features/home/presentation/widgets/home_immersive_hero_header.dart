import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:http/http.dart' as http;
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/notifikasi_page.dart';
import 'package:home_care/users/profile.dart';
import 'package:home_care/users/search_page.dart';

class HomeImmersiveHeroHeader extends StatefulWidget {
  const HomeImmersiveHeroHeader({super.key});

  @override
  State<HomeImmersiveHeroHeader> createState() =>
      _HomeImmersiveHeroHeaderState();
}

class _HomeImmersiveHeroHeaderState extends State<HomeImmersiveHeroHeader> {
  String? _nama;
  String? _lokasi;
  int _notifUnreadCount = 0;
  Timer? _notifTimer;

  // Typing animation in search bar
  final List<String> _searchTexts = [
    'Lagi butuh layanan kesehatan apa?',
    'Cari perawat siap datang ke rumah...',
    'Butuh fisioterapi nyaman di rumah?',
    'Cari medical check-up tanpa ribet...',
    'Mau konsultasi dokter lebih tenang?',
  ];
  int _currentTextIndex = 0;
  String _displayedText = '';
  Timer? _typingTimer;
  bool _isTyping = true;

  static String get baseUrl => ApiConstants.apiBase;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadNotifUnread();
    _startNotifPolling();
    _startTypingAnimation();
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startNotifPolling() {
    _notifTimer?.cancel();
    _notifTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadNotifUnread();
    });
  }

  void _startTypingAnimation() {
    int charIndex = 0;
    final currentText = _searchTexts[_currentTextIndex];

    _typingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_isTyping) {
          if (charIndex <= currentText.length) {
            _displayedText = currentText.substring(0, charIndex);
            charIndex++;
          } else {
            timer.cancel();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _isTyping = false;
                _startDeletingAnimation();
              }
            });
          }
        }
      });
    });
  }

  void _startDeletingAnimation() {
    final currentText = _searchTexts[_currentTextIndex];
    int charIndex = currentText.length;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (charIndex > 0) {
          _displayedText = currentText.substring(0, charIndex);
          charIndex--;
        } else {
          timer.cancel();
          _currentTextIndex = (_currentTextIndex + 1) % _searchTexts.length;
          _isTyping = true;
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              _startTypingAnimation();
            }
          });
        }
      });
    });
  }

  Future<void> _loadNotifUnread() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) return;

      final res = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) return;

      final body = json.decode(res.body);
      if (body is! Map || body['success'] != true) return;

      int unreadCount = 0;
      if (body['meta'] is Map && body['meta']['unread_count'] != null) {
        final raw = body['meta']['unread_count'];
        unreadCount = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
      } else {
        final List data = (body['data'] ?? []) as List;
        unreadCount =
            data.where((e) => e is Map && e['is_read'] != true).length;
      }

      if (!mounted) return;
      setState(() {
        _notifUnreadCount = unreadCount;
      });
    } catch (_) {}
  }

  Future<void> _loadProfileData() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) return;

      final res = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) return;

      final body = json.decode(res.body);
      if (body is! Map || body['success'] != true) return;

      final data = body['data'] ?? {};
      final pasien = data['pasien'] as Map<String, dynamic>?;
      final user = data['user'] as Map<String, dynamic>?;

      final kota = (pasien?['kota'] ?? '').toString().trim();
      String lokasi = 'Kota Medan';
      if (kota.isNotEmpty) {
        lokasi = kota;
      }

      if (!mounted) return;
      setState(() {
        _nama = (pasien?['nama_lengkap'] ?? user?['name'])?.toString();
        _lokasi = lokasi;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    // Header image height based on screen size
    final double bannerHeight = isTablet ? 410.0 : 365.0;
    const double searchBarHeight = 52.0;
    final double totalHeight = bannerHeight + (searchBarHeight / 2); // 26px overlap for search bar

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Immersive Full-Bleed Dark Hero Image with Multi-layer Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bannerHeight,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=1000&auto=format&fit=crop&q=80',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 32 : 18,
                  topPadding + 10,
                  isTablet ? 32 : 18,
                  54, // 26px search bar overlap + 28px airy breathing room
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: Location (Left) + Notification Bell (Right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Location Info
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfilePage(),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _nama != null ? 'Halo, ${_nama!}' : 'Lokasi Pasien',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    IconlyBold.location,
                                    size: 15,
                                    color: HCColor.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _lokasi ?? 'Kota Medan',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    IconlyLight.arrowDown2,
                                    size: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Notification Bell with Badge
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotifikasiPage(),
                              ),
                            );
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  IconlyLight.notification,
                                  color: Colors.white,
                                  size: 21,
                                ),
                                if (_notifUnreadCount > 0)
                                  Positioned(
                                    top: 7,
                                    right: 8,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Center Headline: Elegant, clean & balanced (not overly bold)
                    Text(
                      'Layanan Medis &\nPerawatan Terbaik\nLangsung di Rumah!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: isTablet ? 26 : 21,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.26,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Bottom Row on Image: CTA Pill Button (Left) + Promo Sticker Badge (Right)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // CTA Pill Button (Matching "Order Now" from reference)
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [HCColor.primary, Color(0xFF14B8A6)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: HCColor.primary.withValues(alpha: 0.32),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PilihLayananPage(),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10.5,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Pesan Sekarang',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      IconlyLight.arrowRight2,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Circular Discount / Promo Badge (Matching "35% Discount" from reference)
                        Transform.rotate(
                          angle: 0.06,
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: HCColor.primary.withValues(alpha: 0.18),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'DISKON',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w700,
                                    color: HCColor.textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '25%',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: HCColor.primary,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Floating Overlapping Rounded Search Bar with Filter Button
          Positioned(
            left: isTablet ? 32 : 18,
            right: isTablet ? 32 : 18,
            bottom: 0,
            height: searchBarHeight,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(left: 18, right: 6),
                child: Row(
                  children: [
                    const Icon(
                      IconlyLight.search,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _displayedText.isNotEmpty
                            ? _displayedText
                            : 'Cari layanan medis, perawat...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF94A3B8),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    // Filter slider button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: HCColor.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: HCColor.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          IconlyLight.filter,
                          color: HCColor.primary,
                          size: 19,
                        ),
                      ),
                    ),
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

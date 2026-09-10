import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/notifikasi_page.dart';
import 'package:home_care/users/profile.dart';
import 'package:home_care/users/profile/services/user_profile_service.dart';
import 'home_hero_search_bar.dart';

/// Immersive Hero Header untuk Beranda Pasien.
/// Menampilkan greeting lokasi, badge notifikasi, headline hero, CTA, dan floating search bar.
class HomeImmersiveHeroHeader extends StatefulWidget {
  const HomeImmersiveHeroHeader({super.key});

  @override
  State<HomeImmersiveHeroHeader> createState() =>
      _HomeImmersiveHeroHeaderState();
}

class _HomeImmersiveHeroHeaderState extends State<HomeImmersiveHeroHeader> {
  final _notifService = const NotifikasiService();
  final _profileService = const UserProfileService();

  String? _nama;
  String? _lokasi;
  int _notifUnreadCount = 0;
  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadNotifUnread();
    _startNotifPolling();
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  void _startNotifPolling() {
    _notifTimer?.cancel();
    _notifTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadNotifUnread();
    });
  }

  Future<void> _loadNotifUnread() async {
    try {
      final unread = await _notifService.fetchUnreadCount();
      if (!mounted) return;
      setState(() {
        _notifUnreadCount = unread;
      });
    } catch (_) {}
  }

  Future<void> _loadProfileData() async {
    try {
      final data = await _profileService.fetchProfile();
      if (!mounted || data == null) return;

      final pasien = data['pasien'] as Map<String, dynamic>?;
      final user = data['user'] as Map<String, dynamic>?;

      final kota = (pasien?['kota'] ?? '').toString().trim();
      String lokasi = 'Kota Medan';
      if (kota.isNotEmpty) {
        lokasi = kota;
      }

      setState(() {
        _nama = (pasien?['nama_lengkap'] ?? user?['name'])?.toString();
        _lokasi = lokasi;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bool isTablet = screenWidth >= 600;

    final double bannerHeight = isTablet ? 410.0 : 365.0;
    const double searchBarHeight = 52.0;
    final double totalHeight = bannerHeight + (searchBarHeight / 2);

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
                  image: CachedNetworkImageProvider(
                    'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=1000&auto=format&fit=crop&q=80',
                    maxHeight: 800,
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
                  54,
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

                    // Center Headline
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

                    // Bottom Row on Image: CTA Pill Button + Promo Sticker Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // CTA Pill Button
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

                        // Circular Discount Badge
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
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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

          // 2. Floating Search Bar with Isolated Micro-Animation
          HomeHeroSearchBar(isTablet: isTablet),
        ],
      ),
    );
  }
}

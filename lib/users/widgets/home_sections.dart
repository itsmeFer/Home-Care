import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/users/home_page.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/notifikasi_page.dart';
import 'package:home_care/users/profile.dart';
import 'package:home_care/users/search_page.dart';
import 'package:home_care/utils/app_cached_image.dart';

class TopLocationBar extends StatefulWidget {
  const TopLocationBar();

  @override
  State<TopLocationBar> createState() => _TopLocationBarState();
}

class _TopLocationBarState extends State<TopLocationBar> {
  String? _fotoProfilUrl;
  String? _nama;
  String? _lokasi;
  bool _isLoadingFoto = false;

  int _notifUnreadCount = 0;
  Timer? _notifTimer;

  static String get baseUrl => ApiConstants.apiBase;

  @override
  void initState() {
    super.initState();
    _loadProfileFoto();
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
    _notifTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadNotifUnread();
    });
  }

  String? _resolveMediaUrl(String? raw) => ApiConstants.resolveMediaUrl(raw);

  Future<void> _openProfilePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );

    if (!mounted) return;
    _loadProfileFoto();
  }

  Future<void> _loadNotifUnread() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
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

  Future<void> _loadProfileFoto() async {
    try {
      setState(() => _isLoadingFoto = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
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

      final rawFoto = pasien?['foto_profil_url'] ?? pasien?['foto_profil'];
      final kota = (pasien?['kota'] ?? '').toString().trim();

      String lokasi = 'Lokasi belum tersedia';
      if (kota.isNotEmpty) {
        lokasi = kota;
      }

      setState(() {
        _fotoProfilUrl = _resolveMediaUrl(rawFoto?.toString());
        _nama = (pasien?['nama_lengkap'] ?? user?['name'])?.toString();
        _lokasi = lokasi;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sapaanNama =
        (_nama != null && _nama!.trim().isNotEmpty) ? _nama!.trim() : 'Sahabat';

    return Container(
      color: HCColor.bg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _openProfilePage,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child:
                  (_fotoProfilUrl != null && _fotoProfilUrl!.isNotEmpty)
                      ? CircleAvatar(
                        radius: 18,
                        backgroundColor: HCColor.primary.withOpacity(0.12),
                        backgroundImage: NetworkImage(_fotoProfilUrl!),
                      )
                      : CircleAvatar(
                        radius: 18,
                        backgroundColor: HCColor.primary.withOpacity(0.12),
                        child: const Icon(
                          Icons.person_outline,
                          color: HCColor.primary,
                          size: 18,
                        ),
                      ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openProfilePage,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoadingFoto
                          ? 'Halo, sebentar ya...'
                          : 'Halo, $sapaanNama',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: HCColor.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _isLoadingFoto
                                ? 'Sedang memuat lokasi...'
                                : (_lokasi ?? 'Lokasi belum tersedia'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
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
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotifikasiPage()),
              );
              _loadNotifUnread();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
                if (_notifUnreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Text(
                        _notifUnreadCount > 99 ? '99+' : '$_notifUnreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeroImageBanner extends StatefulWidget {
  const HeroImageBanner();

  @override
  State<HeroImageBanner> createState() => _HeroImageBannerState();
}

class _HeroImageBannerState extends State<HeroImageBanner> {
  final List<String> _searchTexts = [
    'Lagi butuh layanan kesehatan apa hari ini?',
    'Cari perawat yang siap datang ke rumah...',
    'Butuh fisioterapi yang nyaman di rumah?',
    'Cari medical check-up tanpa ribet...',
    'Mau konsultasi dokter dengan lebih tenang?',
  ];

  int _currentTextIndex = 0;
  String _displayedText = '';
  Timer? _typingTimer;
  bool _isTyping = true;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
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
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _startTypingAnimation();
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final bannerHeight = (screenWidth * 0.5).clamp(180.0, 250.0);
        final horizontalPadding = screenWidth > 600 ? 32.0 : 16.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              Container(
                height: bannerHeight,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1631217868264-e5b90bb7e133?w=800',
                    ),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      color: Colors.black.withOpacity(0.15),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Kami hadir untuk merawat Anda dan keluarga dengan hangat, tenang, dan sepenuh hati.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth > 600 ? 22 : 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -25),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchPage()),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: screenWidth > 600 ? 40 : 20,
                    ),
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayedText,
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: screenWidth > 600 ? 18 : 16,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.search,
                          color: Colors.black38,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CategoryIconsSection extends StatefulWidget {
  const CategoryIconsSection();

  @override
  State<CategoryIconsSection> createState() => _CategoryIconsState();
}

class _CategoryIconsState extends State<CategoryIconsSection> {
  late Future<List<LayananCategory>> _futureKategori;

  @override
  void initState() {
    super.initState();
    _futureKategori = KategoriLayananService.fetchKategori();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LayananCategory>>(
      future: _futureKategori,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
            child: const Text(
              'Kategori layanan belum bisa ditampilkan saat ini',
              style: TextStyle(
                fontSize: 13,
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayedCategories = categories.take(8).toList();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Layanan untuk Anda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E2323),
                        height: 1.1,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PilihLayananPage(),
                        ),
                      );
                    },
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur lihat semua tips akan segera hadir',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(
                          color: Color(0xFF0BA5A7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih layanan yang paling cocok untuk kebutuhan Anda di rumah.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black.withOpacity(0.58),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      displayedCategories
                          .map(
                            (cat) => Padding(
                              padding: const EdgeInsets.only(right: 18),
                              child: _DynamicCategoryIconWidget(category: cat),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Layanan untuk Anda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E2323),
                  ),
                ),
              ),
              Text(
                'Lihat semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB7A9A9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(right: 18),
                  child: _CategoryLoadingItem(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicCategoryIconWidget extends StatelessWidget {
  final LayananCategory category;

  const _DynamicCategoryIconWidget({required this.category});

  String _formatLabel(String text) {
    if (text.trim().isEmpty) return '-';

    final words = text.trim().split(' ');
    if (words.length == 1) return words.first;

    if (text.length <= 12) return text;

    if (words.length >= 2) {
      final first = words.first;
      final second = words.skip(1).join(' ');
      return '$first\n$second';
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final iconData = KategoriLayananService.mapKategoriToIcon(category);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PilihLayananPage(kategori: category.namaKategori),
          ),
        );
      },
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1E6E6),
              ),
              child: ClipOval(
                child:
                    (category.gambarUrl != null &&
                            category.gambarUrl!.trim().isNotEmpty)
                        ? AppCachedImage(
                          imageUrl: category.gambarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: const Color(0xFFF1E6E6),
                            alignment: Alignment.center,
                            child: Icon(
                              iconData,
                              color: const Color(0xFF9C7B7B),
                              size: 30,
                            ),
                          ),
                        )
                        : Container(
                          color: const Color(0xFFF1E6E6),
                          alignment: Alignment.center,
                          child: Icon(
                            iconData,
                            color: const Color(0xFF9C7B7B),
                            size: 30,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formatLabel(category.namaKategori),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E2323),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryLoadingItem extends StatelessWidget {
  const _CategoryLoadingItem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF1E6E6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 56,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF1E6E6),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class SquareBannerSection extends StatefulWidget {
  const SquareBannerSection();

  @override
  State<SquareBannerSection> createState() => _SquareBannerSectionState();
}

class _SquareBannerSectionState extends State<SquareBannerSection> {
  late Future<List<BannerItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = BannerService.fetchSquareBanners();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SquareBannerLoading();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final banners = snapshot.data ?? [];

        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final cardWidth = (screenWidth * 0.42).clamp(145.0, 185.0);
            final cardHeight = (cardWidth * 2.18).clamp(300.0, 380.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilihan favorit untuk Anda',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 22 : 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Layanan yang paling sering dipilih untuk perawatan yang nyaman dan terpercaya.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withOpacity(0.6),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PilihLayananPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Lihat semua',
                          style: TextStyle(
                            color: Color(0xFF0BA5A7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: cardHeight,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: banners.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder:
                        (_, i) => _SquareBannerCard(
                          item: banners[i],
                          width: cardWidth,
                          height: cardHeight,
                        ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SquareBannerCard extends StatelessWidget {
  final BannerItem item;
  final double width;
  final double height;

  const _SquareBannerCard({
    required this.item,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        (item.judul != null && item.judul!.trim().isNotEmpty)
            ? item.judul!.trim()
            : (item.layanan?['nama_layanan']?.toString() ?? 'Layanan');

    final subtitle = item.subtitle?.trim() ?? '';
    final teksDiskon = item.teksDiskon?.trim() ?? '';
    final kodePromo = item.kodePromo?.trim() ?? '';

    final hargaAsli = item.layanan?['harga_fix'];
    final hargaDiskon = item.layanan?['harga_diskon'];
    final selisih = item.layanan?['selisih'];

    final imageHeight = width * 0.95;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child:
                      (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
                          ? AppCachedImage(
                            imageUrl: item.gambarUrl!,
                            fit: BoxFit.cover,
                            errorWidget: _fallbackImage(),
                          )
                          : _fallbackImage(),
                ),
              ),
              if (teksDiskon.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4F),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        teksDiskon,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: width > 160 ? 15 : 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.black.withOpacity(0.58),
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (hargaDiskon != null && hargaAsli != null) ...[
                    Text(
                      formatRupiah(hargaDiskon),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: HCColor.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(hargaAsli),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.black.withOpacity(0.35),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ] else if (hargaAsli != null) ...[
                    Text(
                      formatRupiah(hargaAsli),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: HCColor.primary,
                      ),
                    ),
                  ],
                  if (selisih != null &&
                      (selisih is num ? selisih > 0 : true)) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Lebih hemat ${formatRupiah(selisih)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (kodePromo.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Kode promo: $kodePromo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  if (item.minTransaksi > 0) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Minimal transaksi ${formatRupiah(item.minTransaksi)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 34, color: Colors.grey),
    );
  }
}

class _SquareBannerLoading extends StatelessWidget {
  const _SquareBannerLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilihan favorit untuk Anda',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Layanan yang paling sering dipilih untuk perawatan yang nyaman dan terpercaya.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 330,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder:
                (_, __) => Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

class HealthTipsCarousel extends StatelessWidget {
  const HealthTipsCarousel();

  @override
  Widget build(BuildContext context) {
    final tips = [
      _HealthTip(
        icon: Icons.water_drop_outlined,
        title: 'Cukupi air putih',
        description: 'Minum air yang cukup bantu tubuh tetap segar dan tidak mudah lelah.',
        color: Colors.blue.shade400,
      ),
      _HealthTip(
        icon: Icons.directions_run_outlined,
        title: 'Bergerak tiap hari',
        description: 'Aktivitas ringan 30 menit sehari bisa bantu tubuh tetap bugar.',
        color: Colors.green.shade400,
      ),
      _HealthTip(
        icon: Icons.restaurant_outlined,
        title: 'Makan lebih seimbang',
        description: 'Sayur, buah, dan makanan bergizi bantu tubuh pulih dan tetap kuat.',
        color: Colors.orange.shade400,
      ),
      _HealthTip(
        icon: Icons.nightlight_round_outlined,
        title: 'Istirahat yang cukup',
        description: 'Tidur yang cukup bantu tubuh lebih cepat pulih dan pikiran lebih tenang.',
        color: Colors.purple.shade400,
      ),
      _HealthTip(
        icon: Icons.self_improvement_outlined,
        title: 'Jaga pikiran tetap tenang',
        description: 'Luangkan waktu sebentar untuk relaksasi agar tubuh dan hati lebih nyaman.',
        color: Colors.teal.shade400,
      ),
      _HealthTip(
        icon: Icons.clean_hands_outlined,
        title: 'Jaga kebersihan diri',
        description: 'Kebiasaan kecil seperti cuci tangan rutin sangat berarti untuk kesehatan.',
        color: Colors.cyan.shade400,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HCColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: HCColor.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jurnal Sehat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Langkah kecil untuk hidup lebih baik',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 154,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: tips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, i) => _HealthTipCard(tip: tips[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthTip {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _HealthTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _HealthTipCard extends StatelessWidget {
  final _HealthTip tip;
  const _HealthTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tip.color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: tip.color.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tip.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(tip.icon, color: tip.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tip.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.black54,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LandscapeBannerSection extends StatefulWidget {
  const LandscapeBannerSection();

  @override
  State<LandscapeBannerSection> createState() =>
      _LandscapeBannerSectionState();
}

class _LandscapeBannerSectionState extends State<LandscapeBannerSection> {
  late Future<List<BannerItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = BannerService.fetchLandscapeBanners();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LandscapeBannerLoading();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final banners = snapshot.data ?? [];
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final cardWidth = (screenWidth * 0.72).clamp(250.0, 320.0);
            final cardHeight = cardWidth * 0.62;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paket perawatan pilihan',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 22 : 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pilihan perawatan lengkap agar Anda dan keluarga merasa lebih tenang.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withOpacity(0.6),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PilihLayananPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Lihat semua',
                          style: TextStyle(
                            color: Color(0xFF0BA5A7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: cardHeight,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: banners.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder:
                        (_, i) => _LandscapeBannerCard(
                          item: banners[i],
                          width: cardWidth,
                        ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LandscapeBannerCard extends StatelessWidget {
  final BannerItem item;
  final double width;

  const _LandscapeBannerCard({required this.item, required this.width});

  @override
  Widget build(BuildContext context) {
    final title =
        item.judul?.trim().isNotEmpty == true
            ? item.judul!.trim()
            : (item.layanan?['nama_layanan']?.toString() ?? 'Paket Perawatan');

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
              AppCachedImage(
                imageUrl: item.gambarUrl!,
                fit: BoxFit.cover,
                errorWidget: _fallback(),
              )
            else
              _fallback(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width > 280 ? 18 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 36),
    );
  }
}

class _LandscapeBannerLoading extends StatelessWidget {
  const _LandscapeBannerLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paket perawatan pilihan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pilihan perawatan lengkap agar Anda dan keluarga merasa lebih tenang.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder:
                (_, __) => Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

class PromoFullWidthSection extends StatefulWidget {
  const PromoFullWidthSection();

  @override
  State<PromoFullWidthSection> createState() => _PromoFullWidthSectionState();
}

class _PromoFullWidthSectionState extends State<PromoFullWidthSection> {
  late Future<List<BannerItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = BannerService.fetchFullWidthBanners();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PromoFullWidthLoading();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final banners = snapshot.data ?? [];
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final cardWidth = (screenWidth * 0.85).clamp(300.0, 380.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Promo spesial untuk Anda',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 20 : 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Biar perawatan tetap terasa nyaman, tenang, dan lebih hemat.',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 14 : 13,
                                color: Colors.black.withOpacity(0.6),
                                height: 1.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Lihat semua',
                          style: TextStyle(
                            color: Color(0xFF0BA5A7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: banners.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder:
                        (_, i) => _PromoFullWidthCard(
                          item: banners[i],
                          width: cardWidth,
                        ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PromoFullWidthCard extends StatelessWidget {
  final BannerItem item;
  final double width;

  const _PromoFullWidthCard({required this.item, required this.width});

  @override
  Widget build(BuildContext context) {
    final title =
        item.judul?.trim().isNotEmpty == true
            ? item.judul!.trim()
            : (item.layanan?['nama_layanan']?.toString() ?? 'Promo');

    final subtitle = item.subtitle?.trim() ?? '';
    final teksDiskon = item.teksDiskon?.trim() ?? '';
    final hargaAsli = item.layanan?['harga_fix'];
    final hargaDiskon = item.layanan?['harga_diskon'];

    return Container(
      width: width,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child:
                    (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
                        ? AppCachedImage(
                          imageUrl: item.gambarUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorWidget: _fallback(),
                        )
                        : _fallback(),
              ),
              if (teksDiskon.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      teksDiskon,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.minTransaksi > 0)
                        Text(
                          'Minimal transaksi ${formatRupiah(item.minTransaksi)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withOpacity(0.5),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: width > 260 ? 15 : 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      if (hargaDiskon != null && hargaAsli != null) ...[
                        Text(
                          formatRupiah(hargaDiskon),
                          style: TextStyle(
                            fontSize: width > 260 ? 15 : 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatRupiah(hargaAsli),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.4),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else if (hargaAsli != null) ...[
                        Text(
                          formatRupiah(hargaAsli),
                          style: TextStyle(
                            fontSize: width > 260 ? 15 : 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
}

class _PromoFullWidthLoading extends StatelessWidget {
  const _PromoFullWidthLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Promo spesial untuk Anda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder:
                (_, __) => Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

class TestimonialsSection extends StatefulWidget {
  const TestimonialsSection();

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  late Future<List<Testimonial>> _futureTestimonials;

  @override
  void initState() {
    super.initState();
    _futureTestimonials = TestimonialService.fetchTestimonials();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Testimonial>>(
      future: _futureTestimonials,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final testimonials = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: Color(0xFF0BA5A7),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Cerita hangat dari pasien',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fitur lihat semua testimoni akan segera hadir',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Lihat semua',
                      style: TextStyle(
                        color: Color(0xFF0BA5A7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Kepercayaan dan kenyamanan mereka adalah semangat kami untuk terus merawat dengan sepenuh hati.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.6),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: testimonials.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder:
                    (_, i) => _TestimonialCard(testimonial: testimonials[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.format_quote, color: Color(0xFF0BA5A7), size: 24),
              SizedBox(width: 8),
              Text(
                'Cerita hangat dari pasien',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder:
                (_, __) => Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;
  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(testimonial.avatarUrl),
                backgroundColor: const Color(0xFF0BA5A7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial.nama,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < testimonial.rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              testimonial.komentar,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.7),
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (testimonial.layanan != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0BA5A7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                testimonial.layanan!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0BA5A7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

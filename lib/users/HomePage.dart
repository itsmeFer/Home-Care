import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/chat/pasien_chat_list_page.dart';
import 'package:home_care/users/Menu.dart';
import 'package:home_care/users/layananPage.dart';
import 'package:home_care/users/notifikasi_page.dart';
import 'package:home_care/users/profile.dart';
import 'package:home_care/users/search_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/users/lihatHistoriPemesanan.dart';

/// ========================================
/// COLOR SCHEME
/// ========================================
class HCColor {
  static const primary = Color(0xFF0BA5A7);
  static const primaryDark = Color(0xFF088088);
  static const bg = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textMuted = Colors.black54;
}

/// ========================================
/// MODELS
/// ========================================

class BannerItem {
  final int id;
  final String? judul;
  final String? subtitle;
  final String? gambarUrl;
  final String tipeCard;
  final bool aktif;

  final String? tipeDiskon;
  final double nilaiDiskon;
  final double? maxDiskon;
  final String? kodePromo;
  final double minTransaksi;
  final String? teksDiskon;

  final Map<String, dynamic>? layanan;

  BannerItem({
    required this.id,
    required this.judul,
    required this.subtitle,
    required this.gambarUrl,
    required this.tipeCard,
    required this.aktif,
    required this.tipeDiskon,
    required this.nilaiDiskon,
    required this.maxDiskon,
    required this.kodePromo,
    required this.minTransaksi,
    required this.teksDiskon,
    required this.layanan,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return BannerItem(
      id: json['id'] ?? 0,
      judul: json['judul']?.toString(),
      subtitle: json['subtitle']?.toString(),
      gambarUrl: json['gambar_url']?.toString(),
      tipeCard: (json['tipe_card'] ?? 'landscape').toString(),
      aktif: json['aktif'] == true,
      tipeDiskon: json['tipe_diskon']?.toString(),
      nilaiDiskon: parseNum(json['nilai_diskon']),
      maxDiskon: json['max_diskon'] == null
          ? null
          : parseNum(json['max_diskon']),
      kodePromo: json['kode_promo']?.toString(),
      minTransaksi: parseNum(json['min_transaksi']),
      teksDiskon: json['teks_diskon']?.toString(),
      layanan: json['layanan'] is Map<String, dynamic>
          ? json['layanan'] as Map<String, dynamic>
          : null,
    );
  }
}

class LayananCategory {
  final String nama;
  final IconData icon;

  LayananCategory({required this.nama, required this.icon});
}

// ✅ MODEL TESTIMONI BARU
class Testimonial {
  final int id;
  final String nama;
  final int rating;
  final String komentar;
  final String? layanan;
  final String tanggal;
  final String avatarUrl;

  Testimonial({
    required this.id,
    required this.nama,
    required this.rating,
    required this.komentar,
    this.layanan,
    required this.tanggal,
    required this.avatarUrl,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    return Testimonial(
      id: json['id'] ?? 0,
      nama: json['nama']?.toString() ?? 'Pengguna',
      rating: json['rating'] is int
          ? json['rating']
          : int.tryParse(json['rating'].toString()) ?? 5,
      komentar: json['komentar']?.toString() ?? '',
      layanan: json['layanan']?.toString(),
      tanggal: json['tanggal']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ??
          'https://ui-avatars.com/api/?name=U&background=0BA5A7&color=fff',
    );
  }
}

/// ========================================
/// HELPER FUNCTIONS
/// ========================================

String formatRupiah(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '0') ?? 0;

  final intValue = number.round();
  final reversed = intValue.toString().split('').reversed.join('');
  final chunks = <String>[];

  for (int i = 0; i < reversed.length; i += 3) {
    chunks.add(
      reversed.substring(i, i + 3 > reversed.length ? reversed.length : i + 3),
    );
  }

  return 'Rp ${chunks.join('.').split('').reversed.join('')}';
}

/// ========================================
/// SERVICES
/// ========================================

class BannerService {
  static const String baseUrl = 'http://192.168.1.5:8000/api';

  static Future<List<BannerItem>> _fetchBannersByType(String tipeCard) async {
    final res = await http.get(
      Uri.parse('$baseUrl/banners'),
      headers: {'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil banner');
    }

    final body = json.decode(res.body);

    if (body is! Map || body['success'] != true) {
      throw Exception('Response banner tidak valid');
    }

    final List data = body['data'] ?? [];

    return data
        .map((e) => BannerItem.fromJson(e as Map<String, dynamic>))
        .where((e) => e.aktif && e.tipeCard == tipeCard)
        .toList();
  }

  static Future<List<BannerItem>> fetchSquareBanners() {
    return _fetchBannersByType('square');
  }

  static Future<List<BannerItem>> fetchFullWidthBanners() {
    return _fetchBannersByType('full_width');
  }

  static Future<List<BannerItem>> fetchLandscapeBanners() {
    return _fetchBannersByType('landscape');
  }
}

// ✅ SERVICE TESTIMONI BARU
class TestimonialService {
  static const String baseUrl = 'http://192.168.1.5:8000/api';

  static Future<List<Testimonial>> fetchTestimonials() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/testimonials'),
        headers: {'Accept': 'application/json'},
      );

      if (res.statusCode != 200) {
        throw Exception('Gagal mengambil testimoni');
      }

      final body = json.decode(res.body);

      if (body is! Map || body['success'] != true) {
        throw Exception('Response testimoni tidak valid');
      }

      final List data = body['data'] ?? [];

      return data
          .map((e) => Testimonial.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching testimonials: $e');
      return [];
    }
  }
}

class KategoriLayananService {
  static const String baseUrl = 'http://192.168.1.5:8000/api';

  static Future<List<LayananCategory>> fetchKategori() async {
    final res = await http.get(
      Uri.parse('$baseUrl/layanan/kategori'),
      headers: {'Accept': 'application/json'},
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil kategori layanan');
    }

    final body = json.decode(res.body);

    if (body is! Map || body['success'] != true) {
      throw Exception('Response kategori tidak valid');
    }

    final List rawKategori = body['kategori'] ?? [];

    return rawKategori
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .map(
          (nama) => LayananCategory(nama: nama, icon: _mapKategoriToIcon(nama)),
        )
        .toList();
  }

  static IconData _mapKategoriToIcon(String kategori) {
    final value = kategori.toLowerCase();

    if (value.contains('umum')) {
      return Icons.local_hospital_outlined;
    } else if (value.contains('luka')) {
      return Icons.healing_outlined;
    } else if (value.contains('fisio')) {
      return Icons.accessibility_new_outlined;
    } else if (value.contains('anak')) {
      return Icons.child_care_outlined;
    }

    return Icons.medical_services_outlined;
  }
}

/// ========================================
/// MAIN HOMEPAGE
/// ========================================

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      bottomNavigationBar: const HCBottomNav(currentIndex: 0),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _TopLocationBar()),
            
            // ✅ SPACING: 8px setelah top bar
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            
            const SliverToBoxAdapter(child: _HeroImageBanner()),
            
            // ✅ SPACING: 20px setelah hero banner
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            
            const SliverToBoxAdapter(child: _CategoryIcons()),
            
            // ✅ SPACING: 28px sebelum square banner
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            
            const SliverToBoxAdapter(child: _SquareBannerSection()),
            
            // ✅ SPACING: 32px sebelum health tips
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            
            const SliverToBoxAdapter(child: _HealthTipsCarousel()),
            
            // ✅ SPACING: 32px sebelum landscape banner
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            
            const SliverToBoxAdapter(child: _LandscapeBannerSection()),
            
            // ✅ SPACING: 32px sebelum promo
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            
            const SliverToBoxAdapter(child: _PromoFullWidthSection()),
            
            // ✅ SPACING: 32px sebelum testimoni
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            
            const SliverToBoxAdapter(child: _TestimonialsSection()),
            
            // ✅ SPACING: 40px di akhir
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }
}

/// ========================================
/// WIDGETS
/// ========================================

class _TopLocationBar extends StatefulWidget {
  const _TopLocationBar();

  @override
  State<_TopLocationBar> createState() => _TopLocationBarState();
}

class _TopLocationBarState extends State<_TopLocationBar> {
  String? _fotoProfilUrl;
  String? _nama;
  String? _lokasi;
  bool _isLoadingFoto = false;

  int _notifUnreadCount = 0;
  Timer? _notifTimer;

  static const String baseUrl = 'http://192.168.1.5:8000/api';

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
        unreadCount = data.where((e) => e is Map && e['is_read'] != true).length;
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
        _fotoProfilUrl = (rawFoto is String && rawFoto.isNotEmpty)
            ? rawFoto
            : null;
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
    return Container(
      color: HCColor.bg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: HCColor.primary, size: 18),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _isLoadingFoto
                  ? 'Memuat lokasi...'
                  : (_lokasi ?? 'Lokasi belum tersedia'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotifikasiPage(),
                ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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

class _HeroImageBanner extends StatefulWidget {
  const _HeroImageBanner();

  @override
  State<_HeroImageBanner> createState() => _HeroImageBannerState();
}

class _HeroImageBannerState extends State<_HeroImageBanner> {
  final List<String> _searchTexts = [
    'Cari layanan kesehatan...',
    'Perawat profesional...',
    'Fisioterapi di rumah...',
    'Medical check-up...',
    'Konsultasi dokter...',
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
                    'Layanan Kesehatan Terbaik untuk Anda',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth > 600 ? 22 : 18,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // ✅ SEARCH BAR YANG BISA DIKLIK
              Transform.translate(
                offset: const Offset(0, -25),
                child: GestureDetector(
                  onTap: () {
                    // Navigate ke SearchPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchPage(),
                      ),
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
                        const Icon(Icons.search, color: Colors.black38, size: 24),
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

class _CategoryIcons extends StatefulWidget {
  const _CategoryIcons();

  @override
  State<_CategoryIcons> createState() => _CategoryIconsState();
}

class _CategoryIconsState extends State<_CategoryIcons> {
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
          return const SizedBox.shrink();
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayedCategories = categories.take(4).toList();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Kategori Layanan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                      "Semua",
                      style: TextStyle(
                        color: Color(0xFF0BA5A7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: displayedCategories
                    .map(
                      (cat) => Expanded(
                        child: _DynamicCategoryIconWidget(category: cat),
                      ),
                    )
                    .toList(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Kategori Layanan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F4F8),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(width: 50, height: 10, color: Color(0xFFF1F4F8)),
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

class _DynamicCategoryIconWidget extends StatelessWidget {
  final LayananCategory category;

  const _DynamicCategoryIconWidget({required this.category});

  String _formatLabel(String text) {
    if (text.length <= 14) return text;

    final words = text.split(' ');
    if (words.length >= 2) {
      final firstLine = words.take(2).join(' ');
      final secondLine = words.skip(2).join(' ');
      return secondLine.isEmpty ? firstLine : '$firstLine\n$secondLine';
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PilihLayananPage(kategori: category.nama),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              category.icon,
              color: const Color(0xFF0BA5A7),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatLabel(category.nama),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SquareBannerSection extends StatefulWidget {
  const _SquareBannerSection();

  @override
  State<_SquareBannerSection> createState() => _SquareBannerSectionState();
}

class _SquareBannerSectionState extends State<_SquareBannerSection> {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Layanan Populer',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 22 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilihan layanan terbaik untuk kebutuhan Anda',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.6),
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
                    itemBuilder: (_, i) => _SquareBannerCard(
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
    final title = (item.judul != null && item.judul!.trim().isNotEmpty)
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
                  child: (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
                      ? Image.network(
                          item.gambarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackImage(),
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
                      'Hemat ${formatRupiah(selisih)}',
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
                        'Kode: $kodePromo',
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
                      'Min. ${formatRupiah(item.minTransaksi)}',
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
                'Layanan Populer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pilihan layanan terbaik untuk kebutuhan Anda',
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
            itemBuilder: (_, __) => Container(
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

class _HealthTipsCarousel extends StatefulWidget {
  const _HealthTipsCarousel();

  @override
  State<_HealthTipsCarousel> createState() => _HealthTipsCarouselState();
}

class _HealthTipsCarouselState extends State<_HealthTipsCarousel> {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;

  final tips = [
    _HealthTip(
      '💧 Minum Air Putih',
      'Konsumsi minimal 8 gelas air putih per hari untuk menjaga kesehatan',
      Colors.blue.shade50,
      Colors.blue.shade700,
    ),
    _HealthTip(
      '🏃 Olahraga Rutin',
      'Lakukan aktivitas fisik minimal 30 menit setiap hari',
      Colors.green.shade50,
      Colors.green.shade700,
    ),
    _HealthTip(
      '🥗 Pola Makan Sehat',
      'Konsumsi sayur dan buah untuk nutrisi seimbang',
      Colors.orange.shade50,
      Colors.orange.shade700,
    ),
    _HealthTip(
      '😴 Tidur Cukup',
      'Tidur 7-8 jam setiap malam untuk pemulihan tubuh optimal',
      Colors.purple.shade50,
      Colors.purple.shade700,
    ),
    _HealthTip(
      '🧘 Kelola Stress',
      'Luangkan waktu untuk relaksasi dan meditasi setiap hari',
      Colors.teal.shade50,
      Colors.teal.shade700,
    ),
    _HealthTip(
      '🚭 Hindari Rokok',
      'Merokok dapat meningkatkan risiko berbagai penyakit serius',
      Colors.red.shade50,
      Colors.red.shade700,
    ),
    _HealthTip(
      '🦷 Jaga Kebersihan',
      'Sikat gigi 2x sehari dan cuci tangan secara teratur',
      Colors.cyan.shade50,
      Colors.cyan.shade700,
    ),
    _HealthTip(
      '☀️ Berjemur Pagi',
      'Dapatkan vitamin D alami dari sinar matahari pagi',
      Colors.amber.shade50,
      Colors.amber.shade700,
    ),
    _HealthTip(
      '📱 Batasi Screen Time',
      'Kurangi penggunaan gadget, istirahatkan mata setiap 20 menit',
      Colors.indigo.shade50,
      Colors.indigo.shade700,
    ),
    _HealthTip(
      '🩺 Cek Kesehatan Rutin',
      'Lakukan medical check-up minimal 1 tahun sekali',
      Colors.pink.shade50,
      Colors.pink.shade700,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (!mounted || !_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      const scrollSpeed = 1.0;

      if (currentScroll >= maxScroll) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.jumpTo(currentScroll + scrollSpeed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0BA5A7).withOpacity(0.05),
            const Color(0xFF088088).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Color(0xFF0BA5A7),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Tips Kesehatan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Panduan praktis untuk hidup lebih sehat',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tips.length * 100,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _HealthTipCard(tip: tips[i % tips.length]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthTip {
  final String title;
  final String description;
  final Color bgColor;
  final Color textColor;

  _HealthTip(this.title, this.description, this.bgColor, this.textColor);
}

class _HealthTipCard extends StatelessWidget {
  final _HealthTip tip;
  const _HealthTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tip.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tip.textColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tip.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tip.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip.description,
            style: TextStyle(
              fontSize: 13,
              color: tip.textColor.withOpacity(0.8),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LandscapeBannerSection extends StatefulWidget {
  const _LandscapeBannerSection();

  @override
  State<_LandscapeBannerSection> createState() =>
      _LandscapeBannerSectionState();
}

class _LandscapeBannerSectionState extends State<_LandscapeBannerSection> {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paket Perawatan',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 22 : 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Solusi perawatan lengkap untuk kesehatan optimal',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.6),
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
                    itemBuilder: (_, i) => _LandscapeBannerCard(
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
    final title = item.judul?.trim().isNotEmpty == true
        ? item.judul!.trim()
        : (item.layanan?['nama_layanan']?.toString() ?? 'Banner');

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
              Image.network(
                item.gambarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
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
                'Paket Perawatan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Solusi perawatan lengkap untuk kesehatan optimal',
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
            itemBuilder: (_, __) => Container(
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

class _PromoFullWidthSection extends StatefulWidget {
  const _PromoFullWidthSection();

  @override
  State<_PromoFullWidthSection> createState() => _PromoFullWidthSectionState();
}

class _PromoFullWidthSectionState extends State<_PromoFullWidthSection> {
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
                              'Promo Spesial Hari Ini',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 20 : 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dapatkan diskon untuk layanan kesehatan',
                              style: TextStyle(
                                fontSize: screenWidth > 600 ? 14 : 13,
                                color: Colors.black.withOpacity(0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See all',
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
                    itemBuilder: (_, i) =>
                        _PromoFullWidthCard(item: banners[i], width: cardWidth),
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
    final title = item.judul?.trim().isNotEmpty == true
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
                child: (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
                    ? Image.network(
                        item.gambarUrl!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallback(),
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
                          'Min. ${formatRupiah(item.minTransaksi)}',
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
            'Promo Spesial Hari Ini',
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
            itemBuilder: (_, __) => Container(
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

// ✅ TESTIMONI SECTION BARU DARI API
class _TestimonialsSection extends StatefulWidget {
  const _TestimonialsSection();

  @override
  State<_TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<_TestimonialsSection> {
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
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        // Error atau data kosong - tidak tampilkan section
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final testimonials = snapshot.data!;

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
                    'Testimoni',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Kata Mereka Tentang Kami',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.6),
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
                itemBuilder: (_, i) =>
                    _TestimonialCard(testimonial: testimonials[i]),
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
                'Testimoni',
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
            itemBuilder: (_, __) => Container(
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

// ✅ BOTTOM NAV
class HCBottomNav extends StatefulWidget {
  final int currentIndex;
  const HCBottomNav({super.key, this.currentIndex = 0});

  @override
  State<HCBottomNav> createState() => _HCBottomNavState();
}

class _HCBottomNavState extends State<HCBottomNav> {
  static const Color activeColor = Color(0xFF0BA5A7);
  static const Color inactiveColor = Colors.black54;
  static const String baseUrl = 'http://192.168.1.5:8000/api';

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) return;

      final res = await http.get(
        Uri.parse('$baseUrl/chat/unread-summary'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) return;

      final body = json.decode(res.body);
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

  Widget _navIcon(String path, bool active, {int badgeCount = 0}) {
    final icon = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.all(active ? 8 : 0),
      decoration: active
          ? const BoxDecoration(
              color: Color(0x220BA5A7),
              shape: BoxShape.circle,
            )
          : null,
      child: Transform.translate(
        offset: Offset(0, active ? -4 : 0),
        child: Image.asset(
          path,
          width: 24,
          height: 24,
        ),
      ),
    );

    if (badgeCount <= 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.currentIndex;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: activeColor,
      unselectedItemColor: inactiveColor,
      selectedFontSize: 12,
      unselectedFontSize: 11,
      onTap: (i) {
        if (i == currentIndex) return;

        if (i == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }

        if (i == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PilihLayananPage(),
            ),
          );
        }

        if (i == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PasienChatListPage(),
            ),
          ).then((_) {
            _loadChatUnread();
          });
        }

        if (i == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LihatHistoriPemesananPage(),
            ),
          );
        }

        if (i == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfilePage(),
            ),
          );
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: _navIcon(
            'assets/Icons/Navbar/Homepage.png',
            currentIndex == 0,
          ),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: _navIcon(
            'assets/Icons/Navbar/Layanan.png',
            currentIndex == 1,
          ),
          label: 'Layanan',
        ),
        BottomNavigationBarItem(
          icon: _navIcon(
            'assets/Icons/Navbar/Chat.png',
            currentIndex == 2,
            badgeCount: _chatUnreadCount,
          ),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: _navIcon(
            'assets/Icons/Navbar/Riwayat.png',
            currentIndex == 3,
          ),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: _navIcon(
            'assets/Icons/Navbar/Profil.png',
            currentIndex == 4,
          ),
          label: 'Profil',
        ),
      ],
    );
  }
}
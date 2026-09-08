import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/users/widgets/home_bottom_nav.dart';
import 'package:home_care/users/widgets/home_sections.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

export 'package:home_care/users/widgets/home_bottom_nav.dart';
export 'package:home_care/users/widgets/home_sections.dart';

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
      maxDiskon:
          json['max_diskon'] == null ? null : parseNum(json['max_diskon']),
      kodePromo: json['kode_promo']?.toString(),
      minTransaksi: parseNum(json['min_transaksi']),
      teksDiskon: json['teks_diskon']?.toString(),
      layanan:
          json['layanan'] is Map<String, dynamic>
              ? json['layanan'] as Map<String, dynamic>
              : null,
    );
  }
}

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
      nama: json['nama']?.toString() ?? 'Sahabat Care',
      rating:
          json['rating'] is int
              ? json['rating']
              : int.tryParse(json['rating'].toString()) ?? 5,
      komentar: json['komentar']?.toString() ?? '',
      layanan: json['layanan']?.toString(),
      tanggal: json['tanggal']?.toString() ?? '',
      avatarUrl:
          json['avatar_url']?.toString() ??
          'https://ui-avatars.com/api/?name=S&background=0BA5A7&color=fff',
    );
  }
}

String formatRupiah(dynamic value) {
  final number =
      value is num
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

class BannerService {
  static Future<List<BannerItem>> _fetchBannersByType(String tipeCard) async {
    try {
      final res = await ApiClient.get('/banners');
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data
            .map(
              (e) => BannerItem.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .where((e) => e.aktif && e.tipeCard == tipeCard)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching banners: $e');
      return [];
    }
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

class TestimonialService {
  static Future<List<Testimonial>> fetchTestimonials() async {
    try {
      final res = await ApiClient.get('/testimonials');
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data
            .map(
              (e) => Testimonial.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching testimonials: $e');
      return [];
    }
  }
}

class KategoriLayananService {
  static Future<List<LayananCategory>> fetchKategori() async {
    try {
      final res = await ApiClient.get('/kategori-layanan');
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data
            .map(
              (e) =>
                  LayananCategory.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .where((e) => e.namaKategori.trim().isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  static IconData mapKategoriToIcon(LayananCategory category) {
    final icon = (category.iconName ?? '').toLowerCase().trim();
    final nama = category.namaKategori.toLowerCase().trim();

    switch (icon) {
      case 'hospital':
      case 'local_hospital':
        return IconlyLight.activity;
      case 'healing':
        return IconlyLight.shieldDone;
      case 'child_care':
        return IconlyLight.user2;
      case 'accessibility':
      case 'accessibility_new':
        return IconlyLight.activity;
      case 'medical_services':
        return IconlyLight.work;
      case 'favorite':
      case 'monitor_heart':
        return IconlyLight.heart;
      case 'vaccines':
        return IconlyLight.discovery;
      case 'medication':
        return IconlyLight.timeCircle;
      case 'elderly':
        return IconlyLight.profile;
    }

    if (nama.contains('umum')) {
      return IconlyLight.activity;
    } else if (nama.contains('luka')) {
      return IconlyLight.shieldDone;
    } else if (nama.contains('fisio')) {
      return IconlyLight.activity;
    } else if (nama.contains('anak')) {
      return IconlyLight.user2;
    } else if (nama.contains('jantung')) {
      return IconlyLight.heart;
    } else if (nama.contains('obat')) {
      return IconlyLight.timeCircle;
    } else if (nama.contains('lansia')) {
      return IconlyLight.profile;
    }

    return IconlyLight.activity;
  }

  static Color mapKategoriColor(String? hexColor) {
    if (hexColor == null || hexColor.trim().isEmpty) {
      return const Color(0xFF0BA5A7);
    }

    String hex = hexColor.replaceAll('#', '').trim();

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    return Color(int.tryParse(hex, radix: 16) ?? 0xFF0BA5A7);
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      bottomNavigationBar: const HCBottomNav(currentIndex: 0),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: HomeImmersiveHeroHeader()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: CategoryIconsSection()),
          const SliverToBoxAdapter(child: SquareBannerSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: HealthTipsCarousel()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: LandscapeBannerSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: PromoFullWidthSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: TestimonialsSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 36)),
        ],
      ),
    );
  }
}

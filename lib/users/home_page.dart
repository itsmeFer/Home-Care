import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/chat/pasien_chat_list_page.dart';
import 'package:home_care/users/menu_page.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/notifikasi_page.dart';
import 'package:home_care/users/profile.dart';
import 'package:home_care/users/search_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/users/lihat_histori_pemesanan.dart';
import 'package:home_care/utils/app_cached_image.dart';
import 'package:home_care/users/widgets/home_bottom_nav.dart';
import 'package:home_care/users/widgets/home_sections.dart';

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

class LayananCategory {
  final int id;
  final String namaKategori;
  final String slug;
  final String? deskripsi;
  final String? gambarUrl;
  final String? iconName;
  final String? warna;
  final int urutan;
  final int jumlahLayanan;

  LayananCategory({
    required this.id,
    required this.namaKategori,
    required this.slug,
    required this.deskripsi,
    required this.gambarUrl,
    required this.iconName,
    required this.warna,
    required this.urutan,
    required this.jumlahLayanan,
  });

  factory LayananCategory.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return LayananCategory(
      id: parseInt(json['id']),
      namaKategori: (json['nama_kategori'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      deskripsi: json['deskripsi']?.toString(),
      gambarUrl: json['gambar_url']?.toString(),
      iconName: json['icon']?.toString(),
      warna: json['warna']?.toString(),
      urutan: parseInt(json['urutan']),
      jumlahLayanan: parseInt(json['jumlah_layanan']),
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
            .map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e as Map)))
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
            .map((e) =>
                Testimonial.fromJson(Map<String, dynamic>.from(e as Map)))
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
            .map((e) =>
                LayananCategory.fromJson(Map<String, dynamic>.from(e as Map)))
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
        return Icons.local_hospital_outlined;
      case 'healing':
        return Icons.healing_outlined;
      case 'child_care':
        return Icons.child_care_outlined;
      case 'accessibility':
      case 'accessibility_new':
        return Icons.accessibility_new_outlined;
      case 'medical_services':
        return Icons.medical_services_outlined;
      case 'favorite':
        return Icons.favorite_border;
      case 'vaccines':
        return Icons.vaccines_outlined;
      case 'monitor_heart':
        return Icons.monitor_heart_outlined;
      case 'medication':
        return Icons.medication_outlined;
      case 'elderly':
        return Icons.elderly_outlined;
    }

    if (nama.contains('umum')) {
      return Icons.local_hospital_outlined;
    } else if (nama.contains('luka')) {
      return Icons.healing_outlined;
    } else if (nama.contains('fisio')) {
      return Icons.accessibility_new_outlined;
    } else if (nama.contains('anak')) {
      return Icons.child_care_outlined;
    } else if (nama.contains('jantung')) {
      return Icons.monitor_heart_outlined;
    } else if (nama.contains('obat')) {
      return Icons.medication_outlined;
    } else if (nama.contains('lansia')) {
      return Icons.elderly_outlined;
    }

    return Icons.medical_services_outlined;
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
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      bottomNavigationBar: const HCBottomNav(currentIndex: 0),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: TopLocationBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(child: HeroImageBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(child: CategoryIconsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            const SliverToBoxAdapter(child: SquareBannerSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            const SliverToBoxAdapter(child: HealthTipsCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            const SliverToBoxAdapter(child: LandscapeBannerSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            const SliverToBoxAdapter(child: PromoFullWidthSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            const SliverToBoxAdapter(child: TestimonialsSection()),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/network/api_client.dart';
import '../models/home_models.dart';
export 'package:home_care/features/banners/data/banner_service.dart';

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

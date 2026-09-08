import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/users/home_page.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/notifikasi_page.dart';
import 'package:home_care/users/profile.dart';
import 'package:home_care/users/search_page.dart';
import 'package:home_care/utils/app_cached_image.dart';

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


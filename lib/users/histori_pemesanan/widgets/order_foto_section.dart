import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/theme/app_colors.dart';

class OrderFotoSection extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderFotoSection({super.key, required this.order});

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '${ApiConstants.apiBase}/media/$raw';
  }

  IconData _getFotoIcon(String title) {
    switch (title) {
      case 'Kondisi Pasien':
        return IconlyLight.shieldDone;
      case 'Bukti Kehadiran':
        return IconlyLight.location;
      case 'Setelah Tindakan':
        return IconlyLight.tickSquare;
      default:
        return IconlyLight.image;
    }
  }

  Widget _buildFotoCard(String title, String? rawPath) {
    final url = _resolveImageUrl(rawPath);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getFotoIcon(title), size: 18, color: HCColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (url == null)
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HCColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconlyLight.image, color: HCColors.textMuted, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada foto',
                    style: TextStyle(color: HCColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: HCColors.bg,
                  alignment: Alignment.center,
                  child: const Icon(
                    IconlyLight.image,
                    color: HCColors.textMuted,
                    size: 48,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFotoCard('Kondisi Pasien', order['kondisi_pasien']?.toString()),
        const SizedBox(height: 12),
        _buildFotoCard('Bukti Kehadiran', order['foto_hadir']?.toString()),
        const SizedBox(height: 12),
        _buildFotoCard('Setelah Tindakan', order['foto_selesai']?.toString()),
      ],
    );
  }
}

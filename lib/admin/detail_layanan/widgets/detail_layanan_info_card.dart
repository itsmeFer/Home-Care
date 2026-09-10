import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/utils/app_cached_image.dart';

class DetailLayananInfoCard extends StatelessWidget {
  final LayananDetail layanan;
  final String kategoriLabel;
  final ValueChanged<bool> onToggleActive;

  const DetailLayananInfoCard({
    super.key,
    required this.layanan,
    required this.kategoriLabel,
    required this.onToggleActive,
  });

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = layanan;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (l.gambarUrl != null && l.gambarUrl!.isNotEmpty) ...[
              AppCachedImage(
                imageUrl: l.gambarUrl!,
                height: 180,
                width: double.infinity,
                borderRadius: BorderRadius.circular(12),
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 14),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCircleAvatar(
                  imageUrl: l.gambarUrl,
                  radius: 28,
                  fallbackIcon: Icons.medical_services_outlined,
                  backgroundColor: HCColor.primary.withValues(alpha: 0.1),
                  foregroundColor: HCColor.primaryDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.namaLayanan,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (l.kodeLayanan.isNotEmpty)
                        Text(
                          'Kode: ${l.kodeLayanan}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Aktif',
                      style: TextStyle(fontSize: 12),
                    ),
                    Switch(
                      value: l.aktif,
                      onChanged: onToggleActive,
                      activeThumbColor: HCColor.primary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            _infoRow('Kategori', kategoriLabel),
            _infoRow('Tipe Layanan', l.tipeLayananLabel),
            _infoRow('Syarat Perawat', l.syaratPerawatLabel),
            _infoRow('Lokasi Tersedia', l.lokasiLabel),
            _infoRow(
              'Harga Dasar',
              'Rp ${l.hargaDasar.toStringAsFixed(0)}',
            ),
            if (l.durasiMenit != null)
              _infoRow(
                'Durasi',
                '${l.durasiMenit} menit',
              ),
            if (l.jumlahVisit != null)
              _infoRow(
                'Jumlah Visit (paket)',
                '${l.jumlahVisit}',
              ),
            if (l.deskripsi != null && l.deskripsi!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Deskripsi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                l.deskripsi!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

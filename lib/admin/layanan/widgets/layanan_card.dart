import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/utils/app_cached_image.dart';

class LayananCard extends StatelessWidget {
  final Layanan layanan;
  final String kategoriLabel;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LayananCard({
    super.key,
    required this.layanan,
    required this.kategoriLabel,
    required this.onTap,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = layanan;

    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCircleAvatar(
                imageUrl: l.gambarUrl,
                radius: 22,
                fallbackIcon: Icons.medical_services_outlined,
                backgroundColor: HCColor.primary.withValues(alpha: 0.1),
                foregroundColor: HCColor.primaryDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.namaLayanan,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if ((l.kategori ?? '').isNotEmpty)
                      Text(
                        'Kategori: $kategoriLabel',
                        style: const TextStyle(fontSize: 12),
                      ),
                    Text(
                      'Tipe: ${l.tipeLayananLabel} • Syarat: ${l.syaratPerawatLabel}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Lokasi: ${l.lokasiLabel}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Harga: Rp ${l.hargaDasar.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (l.durasiMenit != null)
                      Text(
                        'Durasi: ${l.durasiMenit} menit',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: l.aktif,
                      onChanged: onToggleActive,
                      activeThumbColor: HCColor.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: onDelete,
                        tooltip: 'Hapus',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

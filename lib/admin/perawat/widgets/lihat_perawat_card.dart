import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/nurses/domain/nurse_model.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class LihatPerawatCard extends StatelessWidget {
  final PerawatModel perawat;

  const LihatPerawatCard({
    super.key,
    required this.perawat,
  });

  @override
  Widget build(BuildContext context) {
    final p = perawat;
    final fotoUrl = p.foto;

    return Card(
      color: Colors.white.withValues(alpha: 0.9),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fotoUrl != null && fotoUrl.isNotEmpty)
              AppCircleAvatar(
                imageUrl: fotoUrl,
                radius: 22,
                fallbackIcon: Icons.person,
                backgroundColor: HCColor.primary.withValues(alpha: 0.1),
                foregroundColor: HCColor.primaryDark,
              )
            else
              CircleAvatar(
                radius: 22,
                backgroundColor: HCColor.primary.withValues(alpha: 0.1),
                child: Text(
                  p.inisial ?? '?',
                  style: TextStyle(
                    color: HCColor.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.namaLengkap.isNotEmpty ? p.namaLengkap : '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kode: ${p.kodePerawat ?? '-'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Koordinator: ${p.koordinatorNama ?? '-'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.chipColorVerifikasi.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          p.labelStatusVerifikasi,
                          style: TextStyle(
                            fontSize: 11,
                            color: p.chipColorVerifikasi,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.isActive
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          p.isActive ? 'Aktif' : 'Tidak Aktif',
                          style: TextStyle(
                            fontSize: 11,
                            color: p.isActive
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (p.verifiedAt != null && p.verifiedAt!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Tgl verifikasi: ${p.verifiedAt}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  if (p.catatanVerifikasi != null &&
                      p.catatanVerifikasi!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Catatan: ${p.catatanVerifikasi}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  if (p.verifikator != null && p.verifikator!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Diverifikasi oleh: ${p.verifikator}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

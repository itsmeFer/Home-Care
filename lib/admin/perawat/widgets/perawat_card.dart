import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/nurses/domain/nurse_model.dart';

class PerawatCard extends StatelessWidget {
  final PerawatModel perawat;
  final VoidCallback onEdit;
  final VoidCallback onAssignKoordinator;
  final VoidCallback onSetPassword;
  final VoidCallback onVerifikasi;
  final VoidCallback onDelete;

  const PerawatCard({
    super.key,
    required this.perawat,
    required this.onEdit,
    required this.onAssignKoordinator,
    required this.onSetPassword,
    required this.onVerifikasi,
    required this.onDelete,
  });

  static Color statusColor(String s) {
    switch (s) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  static String statusLabel(String s) {
    switch (s) {
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = perawat;
    final color = statusColor(p.statusVerifikasi);

    final koorText = (p.koordinatorNama != null &&
            p.koordinatorNama!.trim().isNotEmpty)
        ? '${p.koordinatorNama} • ID ${p.koordinatorId ?? "-"}'
        : (p.koordinatorId != null ? 'ID ${p.koordinatorId}' : '-');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: HCColor.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person_outline,
                color: HCColor.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.namaLengkap,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel(p.statusVerifikasi),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
                          color: (p.isActive ? Colors.green : Colors.grey)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          p.isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            color: p.isActive
                                ? Colors.green
                                : Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Kode: ${p.kodePerawat ?? "-"}',
                      style: const TextStyle(fontSize: 12)),
                  Text('Email: ${p.email ?? "-"}',
                      style: const TextStyle(fontSize: 12)),
                  Text('HP: ${p.noHp ?? "-"}',
                      style: const TextStyle(fontSize: 12)),
                  Text('NIK: ${p.nik ?? "-"}',
                      style: const TextStyle(fontSize: 12)),
                  Text('Koordinator: $koorText',
                      style: const TextStyle(fontSize: 12)),
                  Text(
                    'Rating: ${p.avgRatingPerawat.toStringAsFixed(1)} (${p.totalRatingPerawat})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if ((p.catatanVerifikasi ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Catatan: ${p.catatanVerifikasi}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Assign Koordinator',
                  icon: const Icon(Icons.people_alt_outlined, size: 20),
                  onPressed: onAssignKoordinator,
                ),
                IconButton(
                  tooltip: 'Set Password',
                  icon: const Icon(Icons.key_outlined, size: 20),
                  onPressed: onSetPassword,
                ),
                IconButton(
                  tooltip: 'Verifikasi',
                  icon: const Icon(Icons.verified_outlined, size: 20),
                  onPressed: onVerifikasi,
                ),
                IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

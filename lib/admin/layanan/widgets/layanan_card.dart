import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

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

  static String formatRupiah(num value) {
    final s = value.toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return 'Rp ${s.replaceAllMapped(reg, (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = layanan;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCircleAvatar(
                imageUrl: l.gambarUrl,
                radius: 26,
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
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(l.hargaDasar),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: HCColor.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (kategoriLabel.isNotEmpty && kategoriLabel != '-')
                          _buildBadge(
                            label: kategoriLabel,
                            bgColor: Colors.blue.shade50,
                            textColor: Colors.blue.shade800,
                          ),
                        _buildBadge(
                          label: l.tipeLayananLabel == 'Paket' &&
                                  l.jumlahVisit != null
                              ? 'Paket (${l.jumlahVisit}x)'
                              : l.tipeLayananLabel,
                          bgColor: Colors.orange.shade50,
                          textColor: Colors.orange.shade800,
                        ),
                        _buildBadge(
                          label: l.syaratPerawatLabel,
                          bgColor: Colors.purple.shade50,
                          textColor: Colors.purple.shade800,
                        ),
                        _buildBadge(
                          label: l.lokasiLabel,
                          bgColor: Colors.teal.shade50,
                          textColor: Colors.teal.shade800,
                        ),
                        if (l.durasiMenit != null && l.durasiMenit! > 0)
                          _buildBadge(
                            label: '${l.durasiMenit} mnt',
                            bgColor: Colors.grey.shade100,
                            textColor: Colors.grey.shade800,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: l.aktif ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l.aktif ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: l.aktif
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Ketuk untuk detail & perawat',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Switch(
                    value: l.aktif,
                    onChanged: onToggleActive,
                    activeThumbColor: HCColor.primary,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        onPressed: onEdit,
                        tooltip: 'Edit Layanan',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 19,
                          color: Colors.red,
                        ),
                        onPressed: onDelete,
                        tooltip: 'Hapus Layanan',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
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

  Widget _buildBadge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

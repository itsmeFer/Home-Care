import 'package:flutter/material.dart';
import 'package:home_care/admin/kategori/models/kategori_layanan_model.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class KategoriCard extends StatelessWidget {
  final KategoriLayanan item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onUpload;
  final VoidCallback onDelete;
  final VoidCallback onDeleteImage;

  const KategoriCard({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onUpload,
    required this.onDelete,
    required this.onDeleteImage,
  });

  static Color parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return HCColor.primary;
    final value = hex.replaceAll('#', '');
    if (value.length != 6) return HCColor.primary;
    return Color(int.parse('FF$value', radix: 16));
  }

  static IconData mapIcon(String? iconName) {
    switch (iconName) {
      case 'medical_services':
        return Icons.medical_services;
      case 'healing':
        return Icons.healing;
      case 'vaccines':
        return Icons.vaccines;
      case 'monitor_heart':
        return Icons.monitor_heart;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'favorite':
        return Icons.favorite;
      case 'elderly':
        return Icons.elderly;
      case 'child_care':
        return Icons.child_care;
      case 'accessible':
        return Icons.accessible;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(item.warna);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
              AppCachedImage(
                imageUrl: item.gambarUrl,
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(12),
                fit: BoxFit.cover,
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(mapIcon(item.icon), color: color, size: 32),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaKategori ?? '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Slug: ${item.slug ?? '-'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if ((item.deskripsi ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.deskripsi!,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: item.aktif == true ? 'Aktif' : 'Nonaktif',
                        color: item.aktif == true
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        textColor: item.aktif == true
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                      _buildChip(
                        label: 'Urutan: ${item.urutan ?? 0}',
                        color: Colors.blue.shade50,
                        textColor: Colors.blue.shade800,
                      ),
                      if (item.warna != null && item.warna!.isNotEmpty)
                        _buildChip(
                          label: item.warna!,
                          color: color.withValues(alpha: 0.12),
                          textColor: color,
                        ),
                    ],
                  ),
                  if (item.gambarUrl != null && item.gambarUrl!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: onDeleteImage,
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                      label: const Text(
                        'Hapus Gambar',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Switch(
                  value: item.aktif ?? false,
                  activeThumbColor: HCColor.primary,
                  onChanged: onToggle,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'upload':
                        onUpload();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'upload',
                      child: Text('Upload Gambar'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

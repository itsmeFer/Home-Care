import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/models/addon_admin_model.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class AddonCard extends StatelessWidget {
  final AddonItem item;
  final ValueChanged<AddonItem> onEdit;
  final Function(int id, bool newValue) onToggle;
  final ValueChanged<int> onDelete;

  const AddonCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  Widget _chip(String text, {Color? accent}) {
    final effectiveAccent = accent ?? AppColors.textSecondary;
    final bg = effectiveAccent.withValues(alpha: 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: effectiveAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: accent ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              height: 76,
              child: item.gambarUrl != null && item.gambarUrl!.isNotEmpty
                  ? AppCachedImage(
                      imageUrl: item.gambarUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 160,
                      memCacheHeight: 160,
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 28),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.namaAddon,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                      onSelected: (action) {
                        if (action == 'edit') {
                          onEdit(item);
                        } else if (action == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Hapus', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  AppFormatters.formatRupiah(item.hargaFix),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (item.categoryName != null && item.categoryName!.isNotEmpty)
                      _chip(item.categoryName!, accent: AppColors.primary),
                    _chip(
                      item.isQtyEnabled ? "Qty Aktif" : "Tanpa Qty",
                      accent: item.isQtyEnabled ? AppColors.success : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.aktif ? "Status: Aktif" : "Status: Nonaktif",
                      style: TextStyle(
                        fontSize: 12,
                        color: item.aktif ? AppColors.success : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch.adaptive(
                      value: item.aktif,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      onChanged: (val) => onToggle(item.id, val),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Add-on?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus add-on "${item.namaAddon}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(item.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

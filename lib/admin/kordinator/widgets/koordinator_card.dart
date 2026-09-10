import 'package:flutter/material.dart';
import 'package:home_care/admin/kordinator/models/koordinator_admin_model.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/utils/app_cached_image.dart';

class KoordinatorCard extends StatelessWidget {
  final Koordinator koordinator;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const KoordinatorCard({
    super.key,
    required this.koordinator,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final k = koordinator;
    final hasFoto = k.foto != null && k.foto!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasFoto)
              AppCircleAvatar(
                imageUrl: k.foto,
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
                  k.inisial ?? '?',
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    k.namaLengkap ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (k.email != null && k.email!.isNotEmpty)
                    Text(
                      k.email!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (k.noHp != null && k.noHp!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'No HP: ${k.noHp}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if (k.wilayah != null && k.wilayah!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Wilayah: ${k.wilayah}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
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
                    value: k.isActive ?? true,
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
    );
  }
}

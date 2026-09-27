import 'package:flutter/material.dart';
import 'package:home_care/admin/kordinator/models/koordinator_admin_model.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

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
    final isActive = k.isActive ?? true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasFoto)
              AppCircleAvatar(
                imageUrl: k.foto,
                radius: 24,
                fallbackIcon: Icons.person,
                backgroundColor: HCColor.primary.withValues(alpha: 0.1),
                foregroundColor: HCColor.primaryDark,
              )
            else
              CircleAvatar(
                radius: 24,
                backgroundColor: HCColor.primary.withValues(alpha: 0.1),
                child: Text(
                  k.inisial ?? '?',
                  style: const TextStyle(
                    color: HCColor.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          k.namaLengkap ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (k.kodeKoordinator != null &&
                          k.kodeKoordinator!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            k.kodeKoordinator!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (k.email != null && k.email!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.email_outlined,
                            size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            k.email!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (k.noHp != null && k.noHp!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          k.noHp!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (k.wilayah != null && k.wilayah!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            k.wilayah!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Text(
                          isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                      if (k.jabatan != null && k.jabatan!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Text(
                            k.jabatan!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade800,
                            ),
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
                  value: isActive,
                  onChanged: onToggleActive,
                  activeThumbColor: HCColor.primary,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      onPressed: onEdit,
                      tooltip: 'Edit',
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
                      tooltip: 'Hapus',
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
    );
  }
}

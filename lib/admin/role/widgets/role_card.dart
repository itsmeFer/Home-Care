import 'package:flutter/material.dart';
import 'package:home_care/admin/role/models/role_admin_models.dart';
import 'package:home_care/core/theme/app_colors.dart';

class RoleCard extends StatelessWidget {
  final RoleModel role;
  final List<UserSummary> assignedUsers;
  final VoidCallback onAssign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RoleCard({
    super.key,
    required this.role,
    required this.assignedUsers,
    required this.onAssign,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final r = role;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: HCColor.primary.withValues(alpha: 0.1),
              child: Text(
                r.inisial,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (r.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Slug: ${r.slug}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (r.description != null && r.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      r.description!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Dipakai user: ${r.usersCount}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    assignedUsers.isEmpty
                        ? 'User: -'
                        : 'User: ${assignedUsers.map((u) => u.name).join(', ')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Assign ke user',
                  icon: const Icon(Icons.person_add),
                  onPressed: onAssign,
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
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

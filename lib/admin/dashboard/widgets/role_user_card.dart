import 'package:flutter/material.dart';
import 'package:home_care/admin/dashboard/models/admin_dashboard_models.dart';
import 'package:home_care/admin/dashboard/widgets/user_detail_widgets.dart';

class RoleUserCard extends StatelessWidget {
  final AdminUserItem user;
  final Color roleColor;
  final VoidCallback onTap;

  const RoleUserCard({
    super.key,
    required this.user,
    required this.roleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9EEF5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: roleColor.withValues(alpha: 0.12),
                  child: Text(
                    user.name.trim().isNotEmpty
                        ? user.name.trim()[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.roleName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          UserMiniChip(
                            label: user.isActive ? 'Aktif' : 'Tidak Aktif',
                            bg: user.isActive
                                ? const Color(0xFFE8FFF1)
                                : const Color(0xFFF3F4F6),
                            fg: user.isActive
                                ? const Color(0xFF15803D)
                                : const Color(0xFF6B7280),
                          ),
                          UserMiniChip(
                            label: user.isFrozen ? 'Frozen' : 'Normal',
                            bg: user.isFrozen
                                ? const Color(0xFFFFEAEA)
                                : const Color(0xFFEFF6FF),
                            fg: user.isFrozen
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF2563EB),
                          ),
                          UserMiniChip(
                            label: user.isVerified ? 'Verified' : 'Belum Verify',
                            bg: user.isVerified
                                ? const Color(0xFFEEFDF3)
                                : const Color(0xFFFFF7ED),
                            fg: user.isVerified
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFEA580C),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

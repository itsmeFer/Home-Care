import 'package:flutter/material.dart';
import 'package:home_care/admin/dashboard/models/admin_dashboard_models.dart';
import 'package:home_care/admin/dashboard/widgets/role_card.dart';

export 'package:home_care/admin/dashboard/widgets/role_card.dart';

class RoleStatsSection extends StatelessWidget {
  final bool isLoading;
  final List<RoleStatItem> roleStats;
  final void Function(String slug, String name) onTapRole;

  const RoleStatsSection({
    super.key,
    required this.isLoading,
    required this.roleStats,
    required this.onTapRole,
  });

  @override
  Widget build(BuildContext context) {
    final int totalUsers = roleStats.fold<int>(
      0,
      (sum, item) => sum + (int.tryParse(item.total) ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daftar Pengguna Berdasarkan Role',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                if (!isLoading && roleStats.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Total $totalUsers pengguna terdaftar',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            if (!isLoading && roleStats.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '${roleStats.length} Role',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (roleStats.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'Belum ada data role.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          )
        else ...[
          // When role count is odd, render first role as Spotlight Featured Card.
          // Remaining roles form a symmetrical 2-column grid.
          if (roleStats.length % 2 != 0) ...[
            FeaturedRoleCard(
              item: roleStats.first,
              onTap: () =>
                  onTapRole(roleStats.first.roleSlug, roleStats.first.roleName),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: roleStats.length - 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.02,
              ),
              itemBuilder: (context, index) {
                final item = roleStats[index + 1];
                return RoleCard(
                  item: item,
                  onTap: () => onTapRole(item.roleSlug, item.roleName),
                );
              },
            ),
          ] else ...[
            GridView.builder(
              itemCount: roleStats.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.02,
              ),
              itemBuilder: (context, index) {
                final item = roleStats[index];
                return RoleCard(
                  item: item,
                  onTap: () => onTapRole(item.roleSlug, item.roleName),
                );
              },
            ),
          ],
        ],
      ],
    );
  }
}

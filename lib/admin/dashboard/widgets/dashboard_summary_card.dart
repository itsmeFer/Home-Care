import 'package:flutter/material.dart';
import 'package:home_care/admin/dashboard/models/admin_dashboard_models.dart';

class DashboardSummaryCard extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final DashboardSummary summary;
  final VoidCallback onRefresh;

  const DashboardSummaryCard({
    super.key,
    required this.isLoading,
    this.errorMessage,
    required this.summary,
    required this.onRefresh,
  });

  Widget _buildItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ringkasan Pendaftar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Segarkan',
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.redAccent, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                _buildItem(
                  'Total User',
                  '${summary.totalUsers}',
                  Icons.groups_rounded,
                  const Color(0xFF2E7DFF),
                ),
                const SizedBox(width: 10),
                _buildItem(
                  'Aktif',
                  '${summary.totalActive}',
                  Icons.check_circle_rounded,
                  const Color(0xFF16A34A),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildItem(
                  'Frozen',
                  '${summary.totalFrozen}',
                  Icons.ac_unit_rounded,
                  const Color(0xFFDC2626),
                ),
                const SizedBox(width: 10),
                _buildItem(
                  'Verified',
                  '${summary.totalVerified}',
                  Icons.verified_rounded,
                  const Color(0xFF2563EB),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

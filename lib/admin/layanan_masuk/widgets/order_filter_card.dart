import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/orders/domain/order_models.dart';

class OrderFilterCard extends StatelessWidget {
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;
  final int totalCount;
  final int pendingCount;
  final int selesaiCount;

  const OrderFilterCard({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.totalCount,
    required this.pendingCount,
    required this.selesaiCount,
  });

  static const List<String> statusOptions = [
    'pending',
    'menunggu_penugasan',
    'mendapatkan_perawat',
    'sedang_dalam_perjalanan',
    'sampai_ditempat',
    'sedang_berjalan',
    'selesai',
    'dibatalkan',
  ];

  static const Color _primary = AppColors.primary;
  static const Color _lightTeal = AppColors.lightTeal;
  static const Color _warning = AppColors.warning;
  static const Color _success = AppColors.success;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.filter_list, size: 20, color: _primary),
              SizedBox(width: 8),
              Text(
                'Filter Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _lightTeal.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(
                Icons.assignment,
                color: _primary,
                size: 20,
              ),
            ),
            hint: const Text('Semua Status'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua status'),
              ),
              ...statusOptions.map(
                (s) => DropdownMenuItem<String>(
                  value: s,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: OrderStatusHelper.color(s),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(OrderStatusHelper.label(s)),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Total', totalCount.toString(), _primary),
              const SizedBox(width: 8),
              _buildStatCard('Pending', pendingCount.toString(), _warning),
              const SizedBox(width: 8),
              _buildStatCard('Selesai', selesaiCount.toString(), _success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

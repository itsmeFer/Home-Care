import 'package:flutter/material.dart';
import 'package:home_care/admin/layanan_masuk/models/order_detail_admin_model.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class OrderQuickInfoCard extends StatelessWidget {
  final OrderLayananDetailAdmin order;

  const OrderQuickInfoCard({super.key, required this.order});

  static const Color _primary = AppColors.primary;
  static const Color _lightTeal = AppColors.lightTeal;
  static const Color _textMuted = AppColors.textMuted;

  String _fmtTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return iso;
    }
  }

  String _fmtJam(String? jam) {
    if (jam == null || jam.isEmpty) return '-';
    if (jam.length >= 5) return jam.substring(0, 5);
    return jam;
  }

  @override
  Widget build(BuildContext context) {
    final pasienNama = order.pasien?.nama ?? '-';

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _lightTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: _primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.namaLayanan,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pasien: $pasienNama',
                      style: const TextStyle(fontSize: 13, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _quickInfoItem(
                icon: Icons.calendar_today,
                label: _fmtTanggal(order.tanggalMulai),
              ),
              const SizedBox(width: 12),
              _quickInfoItem(
                icon: Icons.access_time,
                label: _fmtJam(order.jamMulai),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickInfoItem({required IconData icon, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _lightTeal.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

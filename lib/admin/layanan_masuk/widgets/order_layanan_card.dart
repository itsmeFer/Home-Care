import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/orders/domain/order_models.dart';
import 'package:intl/intl.dart';

class OrderLayananCard extends StatelessWidget {
  final OrderLayananAdmin order;
  final VoidCallback onTap;

  const OrderLayananCard({
    super.key,
    required this.order,
    required this.onTap,
  });

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

  String _getNama(Map<String, dynamic>? obj) {
    if (obj == null) return '-';
    return obj['nama']?.toString() ??
        obj['nama_lengkap']?.toString() ??
        obj['full_name']?.toString() ??
        '-';
  }

  @override
  Widget build(BuildContext context) {
    final tanggal = _fmtTanggal(order.tanggalMulai);
    final jam = _fmtJam(order.jamMulai);

    final pasienNama = _getNama(order.pasien);
    final koordinatorNama = _getNama(order.koordinator);
    final perawatNama = _getNama(order.perawat);

    final statusColor = OrderStatusHelper.color(order.statusOrder);
    final statusLabel = OrderStatusHelper.label(order.statusOrder);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _lightTeal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        color: _primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.kodeOrder,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.namaLayanan,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMetaChip(Icons.calendar_today, tanggal),
                    const SizedBox(width: 8),
                    _buildMetaChip(Icons.access_time, jam),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person, 'Pasien', pasienNama),
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.supervisor_account,
                  'Koordinator',
                  koordinatorNama,
                ),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.local_hospital, 'Perawat', perawatNama),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _lightTeal.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _textMuted),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: _textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

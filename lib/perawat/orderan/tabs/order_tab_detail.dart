import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class OrderTabDetail extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTabDetail({super.key, required this.order});

  String _getNama(Map<String, dynamic>? obj) {
    if (obj == null) return '-';
    return obj['nama_lengkap']?.toString() ??
        obj['nama']?.toString() ??
        obj['full_name']?.toString() ??
        '-';
  }

  Widget _infoRow(String label, dynamic value) {
    final text =
        (value == null || value.toString().isEmpty) ? '-' : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: HCColor.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pasien = order['pasien'] as Map<String, dynamic>?;
    final koordinator = order['koordinator'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Pasien', _getNama(pasien)),
        _infoRow('No HP Pasien', pasien?['no_hp']),
        _infoRow('Koordinator', _getNama(koordinator)),
        _infoRow('No HP Koordinator', koordinator?['no_hp']),
        const Divider(height: 24),
        _infoRow('Tipe Layanan', order['tipe_layanan']),
        _infoRow('Jumlah Visit', order['jumlah_visit_dipesan']),
        _infoRow('Durasi per Visit', '${order['durasi_menit_per_visit']} menit'),
        _infoRow('Quantity', order['qty']),
      ],
    );
  }
}

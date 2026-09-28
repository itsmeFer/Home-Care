import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class OrderTabLokasi extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTabLokasi({super.key, required this.order});

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Alamat', order['alamat_lengkap']),
        _infoRow('Kecamatan', order['kecamatan']),
        _infoRow('Kota', order['kota']),
        if (order['catatan_pasien'] != null) ...[
          const Divider(height: 24),
          const Text(
            'Catatan Pasien:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HCColor.lightTeal.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              order['catatan_pasien'].toString(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/admin/layanan_masuk/models/order_detail_admin_model.dart';
import 'package:home_care/admin/layanan_masuk/widgets/order_info_row.dart';
import 'package:home_care/core/theme/app_colors.dart';

class OrderLokasiTab extends StatelessWidget {
  final OrderLayananDetailAdmin order;

  const OrderLokasiTab({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OrderInfoRow(label: 'Alamat', value: order.alamatLengkap),
        OrderInfoRow(label: 'Kecamatan', value: order.kecamatan),
        OrderInfoRow(label: 'Kota', value: order.kota),
        OrderInfoRow(label: 'Latitude', value: order.latitude),
        OrderInfoRow(label: 'Longitude', value: order.longitude),
        if (order.catatanPasien != null && order.catatanPasien!.isNotEmpty) ...[
          const Divider(height: 24),
          const Text(
            'Catatan Pasien:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightTeal.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              order.catatanPasien!,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

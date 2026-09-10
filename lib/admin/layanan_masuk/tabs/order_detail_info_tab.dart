import 'package:flutter/material.dart';
import 'package:home_care/admin/layanan_masuk/models/order_detail_admin_model.dart';
import 'package:home_care/admin/layanan_masuk/widgets/order_info_row.dart';

class OrderDetailInfoTab extends StatelessWidget {
  final OrderLayananDetailAdmin order;

  const OrderDetailInfoTab({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final pasien = order.pasien;
    final perawat = order.perawat;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OrderInfoRow(label: 'Pasien', value: pasien?.nama),
        OrderInfoRow(label: 'No RM', value: pasien?.noRekamMedis),
        OrderInfoRow(label: 'No HP Pasien', value: pasien?.noHp),
        OrderInfoRow(label: 'Email Pasien', value: pasien?.email),
        const Divider(height: 24),
        OrderInfoRow(label: 'Perawat', value: perawat?.nama),
        OrderInfoRow(label: 'ID Perawat', value: perawat?.id),
        const Divider(height: 24),
        OrderInfoRow(label: 'Tipe Layanan', value: order.tipeLayanan),
        OrderInfoRow(label: 'Jumlah Visit', value: order.jumlahVisitDipesan),
        OrderInfoRow(
          label: 'Durasi per Visit',
          value: order.durasiMenitPerVisit != null
              ? '${order.durasiMenitPerVisit} menit'
              : null,
        ),
        OrderInfoRow(label: 'Quantity', value: order.qty),
      ],
    );
  }
}

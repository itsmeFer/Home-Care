import 'package:flutter/material.dart';
import 'package:home_care/admin/layanan_masuk/models/order_detail_admin_model.dart';
import 'package:home_care/admin/layanan_masuk/widgets/order_info_row.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:intl/intl.dart';

class OrderPembayaranTab extends StatelessWidget {
  final OrderLayananDetailAdmin order;

  const OrderPembayaranTab({super.key, required this.order});

  String _fmtUang(dynamic val) => AppFormatters.currency(val);

  String _fmtDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentInfo = order.paymentInfo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OrderInfoRow(label: 'Harga Satuan', value: _fmtUang(order.hargaSatuan)),
        OrderInfoRow(label: 'Subtotal', value: _fmtUang(order.subtotal)),
        OrderInfoRow(label: 'Diskon', value: _fmtUang(order.diskon)),
        OrderInfoRow(
          label: 'Biaya Tambahan',
          value: _fmtUang(order.biayaTambahan),
        ),
        if (order.addonsTotal != null && order.addonsTotal != 0)
          OrderInfoRow(
            label: 'Total Addons',
            value: _fmtUang(order.addonsTotal),
          ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Bayar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _fmtUang(order.totalBayar),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        OrderInfoRow(label: 'Metode', value: order.metodePembayaran),
        OrderInfoRow(label: 'Status', value: order.statusPembayaran),
        if (paymentInfo != null) ...[
          OrderInfoRow(label: 'Channel', value: paymentInfo.channel),
          OrderInfoRow(
            label: 'Dibayar pada',
            value: _fmtDateTime(order.dibayarPada),
          ),
        ],
      ],
    );
  }
}

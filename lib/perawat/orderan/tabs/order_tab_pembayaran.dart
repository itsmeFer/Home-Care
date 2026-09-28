import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';

class OrderTabPembayaran extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTabPembayaran({super.key, required this.order});

  String _fmtUang(dynamic val) => AppFormatters.currency(val);

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
    final paymentInfo = order['payment_info'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Harga Satuan', _fmtUang(order['harga_satuan'])),
        _infoRow('Subtotal', _fmtUang(order['subtotal'])),
        _infoRow('Diskon', _fmtUang(order['diskon'])),
        _infoRow('Biaya Tambahan', _fmtUang(order['biaya_tambahan'])),

        if (order['addons_total'] != null && order['addons_total'] != 0)
          _infoRow('Total Addons', _fmtUang(order['addons_total'])),

        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Bayar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _fmtUang(order['total_bayar']),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HCColor.primary,
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        _infoRow('Metode', order['metode_pembayaran']),
        _infoRow('Status', order['status_pembayaran']),
        if (paymentInfo != null) ...[
          const Divider(height: 24),
          const Text(
            'Informasi Pembayaran:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (paymentInfo['bank'] != null)
            _infoRow('Bank', paymentInfo['bank']),
          if (paymentInfo['va_number'] != null)
            _infoRow('Nomor VA', paymentInfo['va_number']),
          if (paymentInfo['paid_at'] != null)
            _infoRow('Waktu Bayar', paymentInfo['paid_at']),
        ],
      ],
    );
  }
}

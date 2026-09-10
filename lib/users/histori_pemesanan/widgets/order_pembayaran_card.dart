import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';

class OrderPembayaranCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderPembayaranCard({super.key, required this.order});

  num _getAddonsTotal() {
    final backendTotal =
        num.tryParse(order['addons_total']?.toString() ?? '0') ?? 0;
    if (backendTotal > 0) return backendTotal;

    final raw = order['order_addons'];
    num calculatedTotal = 0;
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          calculatedTotal += num.tryParse(item['subtotal']?.toString() ?? '0') ?? 0;
        }
      }
    }
    return calculatedTotal;
  }

  String _paymentMethodLabel(String? method) {
    if (method == null || method.isEmpty) return '-';
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'qris':
        return 'QRIS';
      case 'ewallet':
        return 'E-Wallet';
      case 'cod':
        return 'Bayar di Tempat';
      default:
        return method;
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'belum_bayar':
        return 'Belum Dibayar';
      case 'menunggu_pembayaran':
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'dibayar':
        return 'Sudah Dibayar';
      case 'lunas':
        return 'Lunas';
      case 'gagal':
        return 'Pembayaran Gagal';
      case 'expired':
        return 'Pembayaran Kedaluwarsa';
      case 'dikembalikan':
      case 'refund':
        return 'Refund';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  Widget _buildPaymentRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: HCColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isDiscount
                  ? HCColors.danger
                  : isTotal
                      ? HCColors.primary
                      : HCColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buktiUrl = order['bukti_pembayaran']?.toString() ??
        order['payment_info']?['bukti_pembayaran']?.toString();
    final uploadedAt = order['payment_info']?['bukti_uploaded_at']?.toString();

    return Column(
      children: [
        // Rincian Pembayaran
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HCColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                  Icon(IconlyLight.wallet, color: HCColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Rincian Pembayaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: HCColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPaymentRow(
                'Harga satuan',
                AppFormatters.currency(
                  num.tryParse(order['harga_satuan']?.toString() ?? '0'),
                ),
              ),
              _buildPaymentRow('Qty', '${order['qty'] ?? 1}'),
              const Divider(height: 20),
              _buildPaymentRow(
                'Subtotal',
                AppFormatters.currency(
                  num.tryParse(order['subtotal']?.toString() ?? '0'),
                ),
              ),
              _buildPaymentRow(
                'Diskon',
                AppFormatters.currency(
                  num.tryParse(order['diskon']?.toString() ?? '0'),
                ),
                isDiscount: true,
              ),
              _buildPaymentRow(
                'Add-ons',
                AppFormatters.currency(_getAddonsTotal()),
              ),
              const Divider(height: 20),
              _buildPaymentRow(
                'Total Bayar',
                AppFormatters.currency(
                  num.tryParse(order['total_bayar']?.toString() ?? '0'),
                ),
                isTotal: true,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBadge(
                    'Metode: ${_paymentMethodLabel(order['metode_pembayaran']?.toString())}',
                    HCColors.primary,
                  ),
                  _buildBadge(
                    'Status: ${_paymentStatusLabel(order['status_pembayaran']?.toString() ?? '')}',
                    HCColors.warning,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Bukti Transaksi Card
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HCColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                  Icon(IconlyLight.ticket, color: HCColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Bukti Transaksi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: HCColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (buktiUrl == null || buktiUrl.isEmpty)
                Container(
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: HCColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.image, color: HCColors.textMuted, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada bukti transaksi',
                        style: TextStyle(color: HCColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    buktiUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: HCColors.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IconlyLight.image, color: HCColors.textMuted, size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Gagal memuat bukti transaksi',
                            style: TextStyle(color: HCColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (uploadedAt != null && uploadedAt.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Diunggah: ${AppFormatters.dateTime(uploadedAt)}',
                    style: const TextStyle(fontSize: 12, color: HCColors.textMuted),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

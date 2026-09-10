import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/features/orders/domain/order_models.dart';

/// Isolated confirmation dialog for Cash on Delivery (COD) payments.
class ConfirmCodDialog extends StatelessWidget {
  final OrderHistory order;

  const ConfirmCodDialog({
    super.key,
    required this.order,
  });

  /// Shows the COD confirmation dialog and returns true if confirmed.
  static Future<bool?> show(BuildContext context, OrderHistory order) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmCodDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HCColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconlyLight.wallet,
                color: HCColors.warning,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Konfirmasi Pembayaran COD',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: HCColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Total: ${AppFormatters.currency(order.totalBayar)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: HCColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pesanan ini menggunakan metode Bayar di Tempat (COD). Pembayaran akan dilakukan saat perawat datang.',
              style: TextStyle(
                fontSize: 14,
                color: HCColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: HCColors.textMuted.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 15,
                        color: HCColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HCColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'OK, Mengerti',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

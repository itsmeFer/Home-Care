import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

/// Dialog konfirmasi pembatalan pesanan oleh pasien.
class OrderCancelDialog extends StatefulWidget {
  final int orderId;
  final Future<void> Function(String alasan) onConfirm;

  const OrderCancelDialog({
    super.key,
    required this.orderId,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required int orderId,
    required Future<void> Function(String alasan) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => OrderCancelDialog(
        orderId: orderId,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<OrderCancelDialog> createState() => _OrderCancelDialogState();
}

class _OrderCancelDialogState extends State<OrderCancelDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: HCColors.danger.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconlyBold.danger,
                  color: HCColors.danger,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Batalkan Pesanan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pesanan hanya bisa dibatalkan sebelum perawat berangkat. Tuliskan alasan pembatalan agar pesanan dapat diproses dengan benar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: HCColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: HCColors.bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: HCColors.danger.withAlpha(60),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 3,
                  style: const TextStyle(
                    fontSize: 15,
                    color: HCColors.textDark,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Contoh: Jadwal berubah, pasien sudah membaik, atau tidak jadi menggunakan layanan.',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: HCColors.textMuted.withAlpha(200),
                      height: 1.5,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: HCColors.textMuted.withAlpha(60),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          color: HCColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HCColors.danger,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final alasan = _controller.text.trim();
                              if (alasan.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Alasan pembatalan wajib diisi'),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isSubmitting = true);
                              Navigator.pop(context);
                              await widget.onConfirm(alasan);
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Batalkan Pesanan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

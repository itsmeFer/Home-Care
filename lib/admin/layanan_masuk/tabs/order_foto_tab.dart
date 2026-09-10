import 'package:flutter/material.dart';
import 'package:home_care/admin/layanan_masuk/models/order_detail_admin_model.dart';
import 'package:home_care/admin/layanan_masuk/widgets/order_image_preview_dialog.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class OrderFotoTab extends StatelessWidget {
  final OrderLayananDetailAdmin order;

  const OrderFotoTab({super.key, required this.order});

  static const Color _primary = AppColors.primary;
  static const Color _lightTeal = AppColors.lightTeal;
  static const Color _textMuted = AppColors.textMuted;

  @override
  Widget build(BuildContext context) {
    final paymentInfo = order.paymentInfo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _fotoPreview(
          context,
          'Kondisi Pasien',
          OrderLayananDetailAdmin.resolveMediaUrl(order.kondisiPasien),
        ),
        _fotoPreview(
          context,
          'Foto Hadir',
          OrderLayananDetailAdmin.resolveMediaUrl(order.fotoHadir),
        ),
        _fotoPreview(
          context,
          'Foto Selesai',
          OrderLayananDetailAdmin.resolveMediaUrl(order.fotoSelesai),
        ),
        _fotoPreview(
          context,
          'Bukti Pembayaran',
          OrderLayananDetailAdmin.resolveMediaUrl(paymentInfo?.buktiPembayaran),
        ),
      ],
    );
  }

  Widget _fotoPreview(BuildContext context, String label, String? url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, size: 16, color: _primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (url == null)
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: _lightTeal.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withValues(alpha: 0.2)),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      color: _textMuted,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada foto',
                      style: TextStyle(color: _textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => OrderImagePreviewDialog.show(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    AppCachedImage(
                      imageUrl: url,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Tap untuk perbesar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

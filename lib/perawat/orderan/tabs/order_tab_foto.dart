import 'package:flutter/material.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class OrderTabFoto extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTabFoto({super.key, required this.order});

  String? _mediaUrl(String? path) => ApiConstants.resolveMediaUrl(path);

  Widget _fotoPreview(BuildContext context, String label, String? url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (url == null)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: HCColor.lightTeal.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.image_not_supported, color: HCColor.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada foto',
                      style: TextStyle(color: HCColor.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: InteractiveViewer(
                          child: AppCachedImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppCachedImage(
                  imageUrl: url,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
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
        _fotoPreview(context, 'Kondisi Pasien', _mediaUrl(order['kondisi_pasien'])),
        _fotoPreview(context, 'Foto Hadir', _mediaUrl(order['foto_hadir'])),
        _fotoPreview(context, 'Foto Selesai', _mediaUrl(order['foto_selesai'])),
        _fotoPreview(
          context,
          'Bukti Pembayaran',
          _mediaUrl(paymentInfo?['bukti_pembayaran']),
        ),
      ],
    );
  }
}

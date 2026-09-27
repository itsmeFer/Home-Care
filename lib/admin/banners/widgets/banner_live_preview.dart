import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';

/// Live interactive preview banner untuk admin sebelum disimpan.
class BannerLivePreview extends StatelessWidget {
  final String tipeCard;
  final String judul;
  final String subtitle;
  final String tipeDiskon;
  final String teksDiskon;
  final String kodePromo;
  final LayananModel? selectedLayanan;
  final double hargaDiskon;
  final Uint8List? webBytes;
  final String? existingImageUrl;
  final VoidCallback onPickImage;

  const BannerLivePreview({
    super.key,
    required this.tipeCard,
    required this.judul,
    required this.subtitle,
    required this.tipeDiskon,
    required this.teksDiskon,
    required this.kodePromo,
    this.selectedLayanan,
    required this.hargaDiskon,
    this.webBytes,
    this.existingImageUrl,
    required this.onPickImage,
  });

  bool get _hasGambarBaru => webBytes != null;
  bool get _hasGambarLama => existingImageUrl != null && existingImageUrl!.isNotEmpty;
  bool get _hasGambar => _hasGambarBaru || _hasGambarLama;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.visibility_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Pratinjau Langsung (Live Preview)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primary,
              ),
              onPressed: onPickImage,
              icon: const Icon(Icons.add_a_photo_outlined, size: 16),
              label: Text(_hasGambar ? 'Ganti Foto' : 'Pilih Foto', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildPreviewContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewContent() {
    switch (tipeCard) {
      case 'full_width':
        return _buildFullWidthPreview();
      case 'square':
        return AspectRatio(aspectRatio: 1.0, child: _buildOverlayCardPreview());
      case 'landscape':
      default:
        return AspectRatio(aspectRatio: 5 / 2.2, child: _buildOverlayCardPreview());
    }
  }

  Widget _buildFullWidthPreview() {
    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImageBackground(),
              if (tipeDiskon != 'none' && teksDiskon.trim().isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      teksDiskon,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul.trim().isEmpty ? 'Judul Banner Promo' : judul,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                if (selectedLayanan != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tipeDiskon != 'none')
                            Text(
                              formatRupiah(selectedLayanan!.hargaFix),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            tipeDiskon != 'none' ? formatRupiah(hargaDiskon) : formatRupiah(selectedLayanan!.hargaFix),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: tipeDiskon != 'none' ? AppColors.success : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (kodePromo.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.confirmation_number_outlined, size: 10, color: Colors.orange.shade800),
                              const SizedBox(width: 3),
                              Text(
                                kodePromo,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.orange.shade800),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayCardPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImageBackground(),
        if (_hasGambar)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        if (tipeDiskon != 'none' && teksDiskon.trim().isNotEmpty)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                teksDiskon,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        Positioned(
          bottom: 12,
          left: 14,
          right: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                judul.trim().isEmpty ? 'Judul Banner Promo' : judul,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (selectedLayanan != null || kodePromo.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (selectedLayanan != null)
                      Text(
                        tipeDiskon != 'none' ? formatRupiah(hargaDiskon) : formatRupiah(selectedLayanan!.hargaFix),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (kodePromo.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          kodePromo,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageBackground() {
    if (_hasGambarBaru) {
      return Image.memory(webBytes!, fit: BoxFit.cover);
    }
    if (_hasGambarLama) {
      return AppCachedImage(
        imageUrl: existingImageUrl,
        fit: BoxFit.cover,
        errorWidget: _emptyPlaceholder(),
      );
    }
    return _emptyPlaceholder();
  }

  Widget _emptyPlaceholder() {
    return Container(
      color: const Color(0xFFE6FAFA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 6),
            Text(
              'Sentuh untuk memilih foto banner',
              style: TextStyle(fontSize: 12, color: AppColors.primary.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

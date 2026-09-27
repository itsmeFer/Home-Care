import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';

class BannerFormLayananSection extends StatelessWidget {
  final LayananModel? selectedLayanan;
  final VoidCallback onTap;

  const BannerFormLayananSection({
    super.key,
    required this.selectedLayanan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Tautan Layanan (Opsional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: selectedLayanan == null
                      ? Text(
                          'Pilih layanan untuk menghubungkan banner promo ini...',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        )
                      : Row(
                          children: [
                            if (selectedLayanan!.gambarUrl != null && selectedLayanan!.gambarUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppCachedImage(
                                  imageUrl: selectedLayanan!.gambarUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorWidget: const Icon(Icons.medical_services, size: 24),
                                ),
                              )
                            else
                              const Icon(Icons.medical_services, size: 30, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedLayanan!.namaLayanan,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    formatRupiah(selectedLayanan!.hargaFix),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                Icon(
                  selectedLayanan == null ? Icons.chevron_right : Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

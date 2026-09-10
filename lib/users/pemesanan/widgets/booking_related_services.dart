import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

class BookingRelatedServicesSection extends StatelessWidget {
  final List<Layanan> relatedLayanan;
  final ValueChanged<Layanan> onSelectLayanan;
  final VoidCallback onSeeAll;

  const BookingRelatedServicesSection({
    super.key,
    required this.relatedLayanan,
    required this.onSelectLayanan,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (relatedLayanan.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Layanan Terkait',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HCColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 145,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: relatedLayanan.length,
            itemBuilder: (context, index) {
              final rel = relatedLayanan[index];
              return GestureDetector(
                onTap: () => onSelectLayanan(rel),
                child: Container(
                  width: 125,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 125,
                          height: 90,
                          color: const Color(0xFFE8F6F6),
                          child:
                              rel.gambarUrl != null
                                  ? AppCachedImage(
                                    imageUrl: rel.gambarUrl,
                                    width: 125,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  )
                                  : const Center(
                                    child: Icon(
                                      IconlyLight.activity,
                                      size: 32,
                                      color: HCColor.primary,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rel.namaLayanan,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AppFormatters.currency(rel.hargaFix),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HCColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

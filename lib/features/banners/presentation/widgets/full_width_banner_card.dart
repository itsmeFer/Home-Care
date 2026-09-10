import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';
import 'package:home_care/features/banners/presentation/widgets/banner_card_badges.dart';
import 'package:home_care/utils/app_cached_image.dart';

class FullWidthBannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FullWidthBannerCard({
    super.key,
    required this.banner,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      color: const Color(0xFFE6FAFA),
                      child: banner.gambarUrl != null
                          ? AppCachedImage(
                              imageUrl: banner.gambarUrl,
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              placeholder: const BannerPlaceholder(height: 140, width: 140),
                              errorWidget: const BannerPlaceholder(height: 140, width: 140),
                            )
                          : const BannerPlaceholder(height: 140, width: 140),
                    ),
                    if (banner.tipeDiskon != 'none' && banner.teksDiskon != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: BannerDiscountBadge(text: banner.teksDiskon!, small: true),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.judul ?? 'Tanpa Judul',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF1E3A5F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          banner.subtitle!,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          BannerOrderBadge(order: banner.urutan, small: true),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: onToggle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: banner.aktif ? const Color(0xFFE6FAFA) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: banner.aktif ? AppColors.primary : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                banner.aktif ? 'Aktif' : 'Nonaktif',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: banner.aktif ? AppColors.primary : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          if (banner.layananId != null) ...[
                            const SizedBox(width: 6),
                            const BannerLinkedBadge(small: true),
                          ],
                          const Spacer(),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: onEdit,
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                ),
                              ),
                              GestureDetector(
                                onTap: onDelete,
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (banner.kodePromo != null && banner.kodePromo!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.discount, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Kode: ${banner.kodePromo}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

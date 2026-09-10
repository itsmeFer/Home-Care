import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';
import 'package:home_care/features/banners/presentation/widgets/banner_card_badges.dart';
import 'package:home_care/utils/app_cached_image.dart';

class SquareBannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SquareBannerCard({
    super.key,
    required this.banner,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  banner.gambarUrl != null
                      ? AppCachedImage(
                          imageUrl: banner.gambarUrl,
                          fit: BoxFit.cover,
                          placeholder: const BannerPlaceholder(),
                          errorWidget: const BannerPlaceholder(),
                        )
                      : const BannerPlaceholder(),
                  if (banner.tipeDiskon != 'none' && banner.teksDiskon != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: BannerDiscountBadge(text: banner.teksDiskon!, small: true),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: BannerOrderBadge(order: banner.urutan, small: true),
                  ),
                  if (banner.layananId != null)
                    const Positioned(
                      bottom: 8,
                      right: 8,
                      child: BannerLinkedBadge(small: true),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.judul ?? 'Tanpa Judul',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFF1E3A5F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    banner.subtitle!,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (banner.kodePromo != null && banner.kodePromo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.discount, size: 9, color: Colors.orange.shade700),
                        const SizedBox(width: 3),
                        Text(
                          banner.kodePromo!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
        ],
      ),
    );
  }
}

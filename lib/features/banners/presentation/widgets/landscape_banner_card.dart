import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';
import 'package:home_care/features/banners/presentation/widgets/banner_card_badges.dart';
import 'package:home_care/utils/app_cached_image.dart';

class LandscapeBannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LandscapeBannerCard({
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: banner.gambarUrl != null
                      ? AppCachedImage(
                          imageUrl: banner.gambarUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: const BannerPlaceholder(height: 160),
                          errorWidget: const BannerPlaceholder(height: 160),
                        )
                      : const BannerPlaceholder(height: 160),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.60),
                          Colors.black.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
                if (banner.judul != null && banner.judul!.isNotEmpty)
                  Positioned(
                    left: 14,
                    right: 60,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.judul!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (banner.subtitle != null && banner.subtitle!.isNotEmpty)
                          Text(
                            banner.subtitle!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: BannerOrderBadge(order: banner.urutan),
                ),
                if (banner.tipeDiskon != 'none' && banner.teksDiskon != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: BannerDiscountBadge(text: banner.teksDiskon!),
                  ),
                if (banner.layananId != null)
                  const Positioned(
                    bottom: 10,
                    right: 10,
                    child: BannerLinkedBadge(),
                  ),
              ],
            ),
          ),
          _buildCardActions(),
        ],
      ),
    );
  }

  Widget _buildCardActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: banner.aktif ? const Color(0xFFE6FAFA) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: banner.aktif ? AppColors.primary : Colors.grey.shade400,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    banner.aktif ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: banner.aktif ? AppColors.primary : Colors.grey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    banner.aktif ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: banner.aktif ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (banner.kodePromo != null && banner.kodePromo!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.discount, size: 12, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    banner.kodePromo!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

/// Parallax Hero AppBar for Booking Detail screen.
class BookingHeroAppBar extends StatelessWidget {
  final Layanan layanan;
  final ScrollController scrollController;
  final double expandedHeroHeight;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onClose;

  const BookingHeroAppBar({
    super.key,
    required this.layanan,
    required this.scrollController,
    required this.expandedHeroHeight,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeroHeight,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 76,
      toolbarHeight: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 18, top: 10, bottom: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: onClose,
              child: const Center(
                child: Icon(
                  Icons.close_rounded,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18, top: 10, bottom: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onToggleFavorite,
                child: Center(
                  child: Icon(
                    isFavorite ? IconlyBold.heart : IconlyLight.heart,
                    color: isFavorite
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF0F172A),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      title: AnimatedBuilder(
        animation: scrollController,
        builder: (context, _) {
          double offset = 0;
          if (scrollController.hasClients) {
            offset = scrollController.offset;
          }
          final double opacity = ((offset - 130) / 80).clamp(0.0, 1.0);

          return Opacity(
            opacity: opacity,
            child: Text(
              layanan.namaLayanan,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFF8FAFC)),
            if (layanan.gambarUrl != null)
              AppCachedImage(
                imageUrl: layanan.gambarUrl,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: const Color(0xFFE6F5F5),
                child: const Center(
                  child: Icon(
                    IconlyLight.activity,
                    size: 80,
                    color: HCColor.primary,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              height: 38,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(38),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

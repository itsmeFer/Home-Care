import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import '../home_page.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class PromoFullWidthSection extends StatefulWidget {
  const PromoFullWidthSection({super.key});

  @override
  State<PromoFullWidthSection> createState() => _PromoFullWidthSectionState();
}

class _PromoFullWidthSectionState extends State<PromoFullWidthSection> {
  late Future<List<BannerItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = BannerService.fetchFullWidthBanners();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PromoFullWidthLoading();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final banners = snapshot.data ?? [];
        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final cardWidth = (screenWidth * 0.85).clamp(300.0, 380.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Promo spesial untuk Anda',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontFamilyFallback: const ['Jakarta Sans', 'Poppins'],
                            fontSize: screenWidth > 600
                                ? 19.0
                                : (screenWidth < 360 ? 14.5 : 16.0),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat semua',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: const Color(0xFF0BA5A7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth < 360 ? 11.8 : 12.8,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  IconlyLight.arrowRight2,
                                  size: 13,
                                  color: Color(0xFF0BA5A7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: banners.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder:
                        (_, i) => _PromoFullWidthCard(
                          item: banners[i],
                          width: cardWidth,
                        ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PromoFullWidthCard extends StatelessWidget {
  final BannerItem item;
  final double width;

  const _PromoFullWidthCard({required this.item, required this.width});

  @override
  Widget build(BuildContext context) {
    final title =
        item.judul?.trim().isNotEmpty == true
            ? item.judul!.trim()
            : (item.layanan?['nama_layanan']?.toString() ?? 'Promo');

    final subtitle = item.subtitle?.trim() ?? '';
    final teksDiskon = item.teksDiskon?.trim() ?? '';
    final hargaAsli = item.layanan?['harga_fix'];
    final hargaDiskon = item.layanan?['harga_diskon'];

    return Container(
      width: width,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child:
                    (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
                        ? AppCachedImage(
                          imageUrl: item.gambarUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorWidget: _fallback(),
                        )
                        : _fallback(),
              ),
              if (teksDiskon.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      teksDiskon,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
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
                      if (item.minTransaksi > 0)
                        Text(
                          'Minimal transaksi ${formatRupiah(item.minTransaksi)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: width > 260 ? 15 : 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      if (hargaDiskon != null && hargaAsli != null) ...[
                        Text(
                          formatRupiah(hargaDiskon),
                          style: TextStyle(
                            fontSize: width > 260 ? 15 : 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatRupiah(hargaAsli),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.4),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else if (hargaAsli != null) ...[
                        Text(
                          formatRupiah(hargaAsli),
                          style: TextStyle(
                            fontSize: width > 260 ? 15 : 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE0F7F7),
            AppColors.primary.withValues(alpha: 0.15),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        IconlyLight.discount,
        color: AppColors.primary.withValues(alpha: 0.45),
        size: 32,
      ),
    );
  }
}

class _PromoFullWidthLoading extends StatelessWidget {
  const _PromoFullWidthLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppSkeleton(width: 180, height: 18, borderRadius: 6),
              AppSkeleton(width: 70, height: 14, borderRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => const _PromoFullWidthSkeletonCard(),
          ),
        ),
      ],
    );
  }
}

class _PromoFullWidthSkeletonCard extends StatelessWidget {
  const _PromoFullWidthSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left thumbnail skeleton
          const AppSkeleton(
            width: 120,
            height: 120,
            borderRadius: 14,
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
                    children: const [
                      AppSkeleton(width: 75, height: 10, borderRadius: 4),
                      SizedBox(height: 8),
                      AppSkeleton(width: double.infinity, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      AppSkeleton(width: 110, height: 11, borderRadius: 4),
                    ],
                  ),
                  Row(
                    children: const [
                      AppSkeleton(width: 70, height: 16, borderRadius: 4),
                      SizedBox(width: 8),
                      AppSkeleton(width: 50, height: 12, borderRadius: 4),
                    ],
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


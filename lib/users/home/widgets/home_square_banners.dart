import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import '../home_page.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class SquareBannerSection extends StatefulWidget {
  const SquareBannerSection({super.key});

  @override
  State<SquareBannerSection> createState() => _SquareBannerSectionState();
}

class _SquareBannerSectionState extends State<SquareBannerSection> {
  late Future<List<BannerItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = BannerService.fetchSquareBanners();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SquareBannerLoading();
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
            final cardWidth = (screenWidth * 0.42).clamp(145.0, 185.0);
            final cardHeight = (cardWidth * 2.18).clamp(300.0, 380.0);

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
                          'Pilihan favorit untuk Anda',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontFamilyFallback: const [
                              'Jakarta Sans',
                              'Poppins',
                            ],
                            fontSize:
                                screenWidth > 600
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
                          onTap: () {
                            HomePage.switchTab(context, 1);
                          },
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
                const SizedBox(height: 16),
                SizedBox(
                  height: cardHeight,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: banners.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder:
                        (_, i) => _SquareBannerCard(
                          item: banners[i],
                          width: cardWidth,
                          height: cardHeight,
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

class _SquareBannerCard extends StatelessWidget {
  final BannerItem item;
  final double width;
  final double height;

  const _SquareBannerCard({
    required this.item,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        (item.judul != null && item.judul!.trim().isNotEmpty)
            ? item.judul!.trim()
            : (item.layanan?['nama_layanan']?.toString() ?? 'Layanan');

    final subtitle = item.subtitle?.trim() ?? '';
    final teksDiskon = item.teksDiskon?.trim() ?? '';
    final kodePromo = item.kodePromo?.trim() ?? '';

    final hargaAsli = item.layanan?['harga_fix'];
    final hargaDiskon = item.layanan?['harga_diskon'];
    final selisih = item.layanan?['selisih'];

    final imageHeight = width * 0.95;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child:
                      (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
                          ? AppCachedImage(
                            imageUrl: item.gambarUrl!,
                            fit: BoxFit.cover,
                            errorWidget: _fallbackImage(),
                          )
                          : _fallbackImage(),
                ),
              ),
              if (teksDiskon.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4F),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        teksDiskon,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: width > 160 ? 15 : 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.black.withValues(alpha: 0.58),
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (hargaDiskon != null && hargaAsli != null) ...[
                    Text(
                      formatRupiah(hargaDiskon),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: HCColor.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(hargaAsli),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.black.withValues(alpha: 0.35),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ] else if (hargaAsli != null) ...[
                    Text(
                      formatRupiah(hargaAsli),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: HCColor.primary,
                      ),
                    ),
                  ],
                  if (selisih != null &&
                      (selisih is num ? selisih > 0 : true)) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Lebih hemat ${formatRupiah(selisih)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (kodePromo.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Kode promo: $kodePromo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  if (item.minTransaksi > 0) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Minimal transaksi ${formatRupiah(item.minTransaksi)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.black.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
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
        IconlyLight.activity,
        size: 36,
        color: AppColors.primary.withValues(alpha: 0.45),
      ),
    );
  }
}

class _SquareBannerLoading extends StatelessWidget {
  const _SquareBannerLoading();

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
              AppSkeleton(width: 170, height: 18, borderRadius: 6),
              AppSkeleton(width: 70, height: 14, borderRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 330,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => const _SquareBannerSkeletonCard(),
          ),
        ),
      ],
    );
  }
}

class _SquareBannerSkeletonCard extends StatelessWidget {
  const _SquareBannerSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      height: 330,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Image Skeleton
          const AppSkeleton(
            width: double.infinity,
            height: 155,
            borderRadius: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeleton(width: 65, height: 16, borderRadius: 99),
                SizedBox(height: 10),
                AppSkeleton(width: double.infinity, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                AppSkeleton(width: 100, height: 11, borderRadius: 4),
                SizedBox(height: 12),
                AppSkeleton(width: 85, height: 16, borderRadius: 4),
                SizedBox(height: 4),
                AppSkeleton(width: 55, height: 11, borderRadius: 4),
                SizedBox(height: 12),
                AppSkeleton(width: double.infinity, height: 20, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

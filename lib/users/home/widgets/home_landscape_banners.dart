import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/users/home_page.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class LandscapeBannerSection extends StatefulWidget {
  const LandscapeBannerSection({super.key});

  @override
  State<LandscapeBannerSection> createState() => _LandscapeBannerSectionState();
}

class _LandscapeBannerSectionState extends State<LandscapeBannerSection> {
  late Future<List<BannerItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = BannerService.fetchLandscapeBanners();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LandscapeBannerLoading();
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
            final cardWidth = (screenWidth * 0.72).clamp(250.0, 320.0);
            final cardHeight = cardWidth * 0.62;

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
                          'Paket perawatan pilihan',
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
                        (_, i) => _LandscapeBannerCard(
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

class _LandscapeBannerCard extends StatelessWidget {
  final BannerItem item;
  final double width;

  const _LandscapeBannerCard({required this.item, required this.width});

  @override
  Widget build(BuildContext context) {
    final title =
        item.judul?.trim().isNotEmpty == true
            ? item.judul!.trim()
            : (item.layanan?['nama_layanan']?.toString() ?? 'Paket Perawatan');

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
              AppCachedImage(
                imageUrl: item.gambarUrl!,
                fit: BoxFit.cover,
                errorWidget: _fallback(),
              )
            else
              _fallback(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width > 280 ? 18 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0BA5A7),
            Color(0xFF075E64),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        IconlyLight.activity,
        color: Colors.white.withValues(alpha: 0.25),
        size: 48,
      ),
    );
  }
}

class _LandscapeBannerLoading extends StatelessWidget {
  const _LandscapeBannerLoading();

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
              AppSkeleton(width: 175, height: 18, borderRadius: 6),
              AppSkeleton(width: 70, height: 14, borderRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => const _LandscapeBannerSkeletonCard(),
          ),
        ),
      ],
    );
  }
}

class _LandscapeBannerSkeletonCard extends StatelessWidget {
  const _LandscapeBannerSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 3),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            const AppSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 16,
            ),
            Positioned(
              left: 16,
              right: 24,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppSkeleton(width: 160, height: 16, borderRadius: 4),
                  SizedBox(height: 6),
                  AppSkeleton(width: 100, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

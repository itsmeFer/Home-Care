import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/users/home_page.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class CategoryIconsSection extends StatefulWidget {
  const CategoryIconsSection({super.key});

  @override
  State<CategoryIconsSection> createState() => _CategoryIconsState();
}

class _CategoryIconsState extends State<CategoryIconsSection> {
  late Future<List<LayananCategory>> _futureKategori;

  @override
  void initState() {
    super.initState();
    _futureKategori = KategoriLayananService.fetchKategori();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Elegant portrait aspect ratio matching user reference image
    final cardWidth = (screenWidth * 0.32).clamp(118.0, 136.0);
    final cardHeight = (cardWidth * 1.34).clamp(158.0, 180.0);

    return FutureBuilder<List<LayananCategory>>(
      future: _futureKategori,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading(context);
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayedCategories = categories.take(8).toList();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Layanan untuk Anda',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontFamilyFallback: ['Jakarta Sans', 'Poppins'],
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HomePage.switchTab(context, 1);
                    },
                    child: const Text(
                      'Lihat semua',
                      style: TextStyle(
                        color: Color(0xFF0BA5A7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      displayedCategories
                          .map(
                            (cat) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _DynamicCategoryIconWidget(
                                category: cat,
                                width: cardWidth,
                                height: cardHeight,
                                screenWidth: screenWidth,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.32).clamp(118.0, 136.0);
    final cardHeight = (cardWidth * 1.34).clamp(158.0, 180.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Layanan untuk Anda',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontFamilyFallback: ['Jakarta Sans', 'Poppins'],
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                'Lihat semua',
                style: TextStyle(
                  color: Color(0xFF0BA5A7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _CategoryLoadingItem(
                    width: cardWidth,
                    height: cardHeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicCategoryIconWidget extends StatelessWidget {
  final LayananCategory category;
  final double width;
  final double height;
  final double screenWidth;

  const _DynamicCategoryIconWidget({
    required this.category,
    required this.width,
    required this.height,
    required this.screenWidth,
  });

  String _formatCategoryTitle(String rawTitle) {
    var title = rawTitle.trim().replaceAll(RegExp(r'[:;,]+$'), '').trim();
    if (title.length > 15) {
      title = title.replaceAll(RegExp(r'\s+dan\s+', caseSensitive: false), ' & ');
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _formatCategoryTitle(category.namaKategori);
    final subtitleText = category.jumlahLayanan > 0
        ? '${category.jumlahLayanan} Layanan'
        : 'Layanan';
    final isSmall = screenWidth < 360;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        PilihLayananPage(kategori: category.namaKategori),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Category Full Background Image
                (category.gambarUrl != null &&
                        category.gambarUrl!.trim().isNotEmpty)
                    ? AppCachedImage(
                      imageUrl: category.gambarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: _buildFallback(),
                    )
                    : _buildFallback(),

                // 2. Smooth Dark Gradient from Mid to Bottom (allows photo to shine on top)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.90),
                      ],
                      stops: const [0.35, 0.55, 0.82, 1.0],
                    ),
                  ),
                ),

                // 3. Subtle Glass Border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 1.0,
                    ),
                  ),
                ),

                // 4. Bottom-Left Typography (Title + Subtitle Badge)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontFamilyFallback: const ['Jakarta Sans', 'Poppins'],
                          fontSize: isSmall ? 13.0 : 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.2,
                          shadows: const [
                            Shadow(
                              color: Color(0x80000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontFamilyFallback: const ['Jakarta Sans', 'Poppins'],
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0BA5A7), Color(0xFF065E64)],
        ),
      ),
      child: Center(
        child: Icon(
          IconlyLight.activity,
          color: Colors.white.withValues(alpha: 0.18),
          size: 44,
        ),
      ),
    );
  }
}

class _CategoryLoadingItem extends StatelessWidget {
  final double width;
  final double height;

  const _CategoryLoadingItem({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: AppSkeleton(
        width: width,
        height: height,
        borderRadius: 20,
      ),
    );
  }
}


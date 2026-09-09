import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/users/home_page.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/utils/app_cached_image.dart';

class CategoryIconsSection extends StatefulWidget {
  const CategoryIconsSection();

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
    return FutureBuilder<List<LayananCategory>>(
      future: _futureKategori,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
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
              const SizedBox(height: 6),
              Text(
                'Pilih layanan yang paling cocok untuk kebutuhan Anda di rumah.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.black.withOpacity(0.58),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      displayedCategories
                          .map(
                            (cat) => Padding(
                              padding: const EdgeInsets.only(right: 18),
                              child: _DynamicCategoryIconWidget(category: cat),
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

  Widget _buildLoading() {
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
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E2323),
                  ),
                ),
              ),
              Text(
                'Lihat semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB7A9A9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(right: 18),
                  child: _CategoryLoadingItem(),
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

  const _DynamicCategoryIconWidget({required this.category});

  String _formatLabel(String text) {
    if (text.trim().isEmpty) return '-';

    final words = text.trim().split(' ');
    if (words.length == 1) return words.first;

    if (text.length <= 12) return text;

    if (words.length >= 2) {
      final first = words.first;
      final second = words.skip(1).join(' ');
      return '$first\n$second';
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PilihLayananPage(kategori: category.namaKategori),
          ),
        );
      },
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE0F7F7),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    (category.gambarUrl != null &&
                            category.gambarUrl!.trim().isNotEmpty)
                        ? AppCachedImage(
                          imageUrl: category.gambarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: const Color(0xFFE0F7F7),
                            alignment: Alignment.center,
                            child: const Icon(
                              IconlyLight.activity,
                              color: Color(0xFF0BA5A7),
                              size: 30,
                            ),
                          ),
                        )
                        : Container(
                          color: const Color(0xFFE0F7F7),
                          alignment: Alignment.center,
                          child: const Icon(
                            IconlyLight.activity,
                            color: Color(0xFF0BA5A7),
                            size: 30,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formatLabel(category.namaKategori),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E2323),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryLoadingItem extends StatelessWidget {
  const _CategoryLoadingItem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        children: const [
          AppSkeleton.circle(size: 74),
          SizedBox(height: 10),
          AppSkeleton(width: 56, height: 12, borderRadius: 6),
        ],
      ),
    );
  }
}


import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/users/home_page.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/notifikasi_page.dart';
import 'package:home_care/users/profile.dart';
import 'package:home_care/users/search_page.dart';
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
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
            child: const Text(
              'Kategori layanan belum bisa ditampilkan saat ini',
              style: TextStyle(
                fontSize: 13,
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayedCategories = categories.take(8).toList();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Layanan untuk Anda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E2323),
                        height: 1.1,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PilihLayananPage(),
                        ),
                      );
                    },
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fitur lihat semua tips akan segera hadir',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(
                          color: Color(0xFF0BA5A7),
                          fontWeight: FontWeight.w600,
                        ),
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
    final iconData = KategoriLayananService.mapKategoriToIcon(category);

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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1E6E6),
              ),
              child: ClipOval(
                child:
                    (category.gambarUrl != null &&
                            category.gambarUrl!.trim().isNotEmpty)
                        ? AppCachedImage(
                          imageUrl: category.gambarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: const Color(0xFFF1E6E6),
                            alignment: Alignment.center,
                            child: Icon(
                              iconData,
                              color: const Color(0xFF9C7B7B),
                              size: 30,
                            ),
                          ),
                        )
                        : Container(
                          color: const Color(0xFFF1E6E6),
                          alignment: Alignment.center,
                          child: Icon(
                            iconData,
                            color: const Color(0xFF9C7B7B),
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


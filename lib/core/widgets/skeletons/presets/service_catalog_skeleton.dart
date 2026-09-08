import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

/// Preset Skeleton untuk halaman Katalog Layanan (layanan_page.dart & search_page.dart)
class ServiceCatalogSkeleton extends StatelessWidget {
  final int itemCount;
  final bool showCategoryChips;

  const ServiceCatalogSkeleton({
    super.key,
    this.itemCount = 6,
    this.showCategoryChips = true,
  });

  @override
  Widget build(BuildContext context) {
    final grid = GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSkeleton(
                width: double.infinity,
                height: 120,
                borderRadius: 18,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AppSkeleton(
                      width: 70,
                      height: 18,
                      borderRadius: 10,
                    ),
                    SizedBox(height: 8),
                    AppSkeleton(
                      width: double.infinity,
                      height: 14,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 6),
                    AppSkeleton(
                      width: 100,
                      height: 12,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 12),
                    AppSkeleton(
                      width: 85,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!showCategoryChips) {
      return grid;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Horizontal Category Chips Shimmer
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: List.generate(5, (index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: AppSkeleton(
                  width: index == 0 ? 70 : 100,
                  height: 36,
                  borderRadius: 20,
                ),
              );
            }),
          ),
        ),

        // 2. Service Cards Grid / List Shimmer
        Expanded(child: grid),
      ],
    );
  }
}

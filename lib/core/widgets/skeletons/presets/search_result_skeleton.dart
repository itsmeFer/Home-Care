import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

/// Preset Skeleton untuk halaman Pencarian Layanan (search_page.dart)
class SearchResultSkeleton extends StatelessWidget {
  final int itemCount;

  const SearchResultSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                offset: const Offset(0, 2),
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ],
          ),
          child: Row(
            children: [
              // Gambar layanan skeleton
              const AppSkeleton(
                width: 80,
                height: 80,
                borderRadius: 10,
              ),
              const SizedBox(width: 14),
              // Detail teks skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AppSkeleton(width: double.infinity, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    AppSkeleton(width: 110, height: 12, borderRadius: 4),
                    SizedBox(height: 12),
                    AppSkeleton(width: 90, height: 16, borderRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const AppSkeleton(width: 16, height: 16, borderRadius: 8),
            ],
          ),
        );
      },
    );
  }
}

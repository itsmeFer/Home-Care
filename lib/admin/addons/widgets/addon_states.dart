import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

class AddonSkeletonList extends StatelessWidget {
  const AddonSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            AppSkeleton(width: 72, height: 72, borderRadius: 12),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton.text(width: 140, height: 16),
                  SizedBox(height: 8),
                  AppSkeleton.text(width: 90, height: 13),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      AppSkeleton(width: 60, height: 20, borderRadius: 6),
                      SizedBox(width: 8),
                      AppSkeleton(width: 50, height: 20, borderRadius: 6),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddonEmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onResetFilter;
  final String title;
  final String message;

  const AddonEmptyState({
    super.key,
    required this.hasFilter,
    required this.onResetFilter,
    this.title = 'Tidak Ada Add-on',
    this.message = 'Belum ada data add-on yang tersedia saat ini.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.extension_off_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'Data Tidak Ditemukan' : title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Tidak ada add-on yang cocok dengan filter atau kata kunci Anda.'
                  : message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onResetFilter,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Reset Filter'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AddonErrorState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const AddonErrorState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage ?? 'Terjadi kendala saat mengambil data dari server.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

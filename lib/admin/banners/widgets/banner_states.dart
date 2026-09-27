import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class BannerEmptyState extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onResetFilter;
  final VoidCallback onAddBanner;

  const BannerEmptyState({
    super.key,
    required this.hasFilter,
    required this.onResetFilter,
    required this.onAddBanner,
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
                Icons.image_not_supported_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'Banner Tidak Ditemukan' : 'Belum Ada Banner',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Tidak ada banner promo yang cocok dengan kriteria pencarian atau filter Anda.'
                  : 'Tambahkan banner promosi atau edukasi untuk ditampilkan pada beranda aplikasi pasien.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (hasFilter)
              OutlinedButton.icon(
                onPressed: onResetFilter,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Reset Filter'),
              )
            else
              ElevatedButton.icon(
                onPressed: onAddBanner,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Banner Pertama'),
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

class BannerErrorState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const BannerErrorState({
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
              'Gagal Memuat Banner',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage ?? 'Terjadi kendala saat mengambil data banner dari server.',
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

import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

/// Preset Skeleton untuk halaman Daftar Histori Pemesanan (lihat_histori_pemesanan.dart)
class OrderListSkeleton extends StatelessWidget {
  final int count;

  const OrderListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: No Order & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  AppSkeleton.text(width: 110, height: 14),
                  AppSkeleton(width: 80, height: 26, borderRadius: 20),
                ],
              ),
              const SizedBox(height: 14),

              // Content: Thumbnail icon, nama layanan, jadwal visit
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AppSkeleton(width: 52, height: 52, borderRadius: 14),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AppSkeleton.text(width: 170, height: 16),
                        SizedBox(height: 8),
                        AppSkeleton.text(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),

              // Footer: Total Bayar & Tombol aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeleton.text(width: 60, height: 11),
                      SizedBox(height: 4),
                      AppSkeleton.text(width: 110, height: 16),
                    ],
                  ),
                  AppSkeleton(width: 100, height: 36, borderRadius: 12),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

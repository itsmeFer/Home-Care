import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

/// Preset Skeleton untuk halaman Detail Histori Pemesanan (lihat_detail_histori_pemesanan.dart)
class OrderDetailSkeleton extends StatelessWidget {
  const OrderDetailSkeleton({super.key});

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(12),
          child: AppSkeleton.circle(size: 32),
        ),
        title: const AppSkeleton.text(width: 140, height: 16),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Status Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      AppSkeleton.text(width: 120, height: 14),
                      AppSkeleton(width: 90, height: 26, borderRadius: 20),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const AppSkeleton.text(width: 180, height: 18),
                  const SizedBox(height: 8),
                  const AppSkeleton.text(width: 240, height: 13),
                ],
              ),
            ),

            // 2. Timeline Tracker Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSkeleton.text(width: 130, height: 16),
                  const SizedBox(height: 18),
                  ...List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          const AppSkeleton.circle(size: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                AppSkeleton.text(width: 140, height: 14),
                                SizedBox(height: 4),
                                AppSkeleton.text(width: 90, height: 11),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // 3. Service & Nakes Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSkeleton.text(width: 120, height: 16),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const AppSkeleton(width: 56, height: 56, borderRadius: 14),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            AppSkeleton.text(width: 160, height: 15),
                            SizedBox(height: 6),
                            AppSkeleton.text(width: 100, height: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. Payment Breakdown Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSkeleton.text(width: 140, height: 16),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      AppSkeleton.text(width: 100, height: 13),
                      AppSkeleton.text(width: 80, height: 13),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      AppSkeleton.text(width: 80, height: 13),
                      AppSkeleton.text(width: 60, height: 13),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      AppSkeleton.text(width: 90, height: 15),
                      AppSkeleton.text(width: 120, height: 18),
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

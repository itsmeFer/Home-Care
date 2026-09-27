import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

class DetailLayananSkeleton extends StatelessWidget {
  const DetailLayananSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Card Skeleton
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSkeleton(
                    height: 180,
                    width: double.infinity,
                    borderRadius: 12,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const AppSkeleton.circle(size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            AppSkeleton(
                              height: 18,
                              width: 160,
                              borderRadius: 4,
                            ),
                            SizedBox(height: 6),
                            AppSkeleton(
                              height: 12,
                              width: 100,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const AppSkeleton(
                    height: 14,
                    width: double.infinity,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  const AppSkeleton(
                    height: 14,
                    width: 220,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  const AppSkeleton(
                    height: 14,
                    width: 180,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Koordinator Card Skeleton
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppSkeleton(
                    height: 20,
                    width: 200,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 14),
                  AppSkeleton(
                    height: 64,
                    width: double.infinity,
                    borderRadius: 12,
                  ),
                  SizedBox(height: 10),
                  AppSkeleton(
                    height: 64,
                    width: double.infinity,
                    borderRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

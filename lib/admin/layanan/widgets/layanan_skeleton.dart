import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

class LayananListSkeleton extends StatelessWidget {
  final int itemCount;

  const LayananListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      itemBuilder: (_, __) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeleton.circle(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppSkeleton(
                        height: 16,
                        width: 180,
                        borderRadius: 4,
                      ),
                      SizedBox(height: 6),
                      AppSkeleton(
                        height: 12,
                        width: 120,
                        borderRadius: 4,
                      ),
                      SizedBox(height: 6),
                      AppSkeleton(
                        height: 12,
                        width: 200,
                        borderRadius: 4,
                      ),
                      SizedBox(height: 6),
                      AppSkeleton(
                        height: 12,
                        width: 140,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const AppSkeleton(
                  height: 28,
                  width: 48,
                  borderRadius: 14,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

class KategoriSkeleton extends StatelessWidget {
  const KategoriSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton(
                width: 72,
                height: 72,
                borderRadius: 12,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton.text(width: 140, height: 16),
                    SizedBox(height: 8),
                    AppSkeleton.text(width: 100, height: 12),
                    SizedBox(height: 8),
                    AppSkeleton.text(width: 200, height: 12),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        AppSkeleton(width: 50, height: 22, borderRadius: 12),
                        SizedBox(width: 8),
                        AppSkeleton(width: 70, height: 22, borderRadius: 12),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              AppSkeleton(width: 36, height: 20, borderRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}

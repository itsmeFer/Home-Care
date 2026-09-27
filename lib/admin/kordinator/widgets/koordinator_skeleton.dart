import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

class KoordinatorSkeleton extends StatelessWidget {
  const KoordinatorSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 6,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
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
              AppSkeleton.circle(size: 44),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton.text(width: 150, height: 16),
                    SizedBox(height: 6),
                    AppSkeleton.text(width: 180, height: 12),
                    SizedBox(height: 6),
                    AppSkeleton.text(width: 110, height: 12),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        AppSkeleton(width: 80, height: 20, borderRadius: 10),
                        SizedBox(width: 6),
                        AppSkeleton(width: 60, height: 20, borderRadius: 10),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                children: [
                  AppSkeleton(width: 38, height: 22, borderRadius: 12),
                  SizedBox(height: 12),
                  AppSkeleton(width: 48, height: 20, borderRadius: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

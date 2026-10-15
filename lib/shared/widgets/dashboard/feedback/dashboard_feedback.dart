import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';
import '../cards/x_card.dart';

class LoadingCard extends StatelessWidget {
  final String title;
  const LoadingCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return XCard(
      title: title,
      subtitle: 'Mengambil data...',
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton.text(width: double.infinity, height: 16),
          SizedBox(height: 10),
          AppSkeleton.text(width: 220, height: 14),
          SizedBox(height: 10),
          AppSkeleton.text(width: 140, height: 14),
        ],
      ),
    );
  }
}

class ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  const ErrorCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return XCard(
      title: title,
      subtitle: 'Gagal memuat',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                color: const Color(0xFFF8FAFC),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

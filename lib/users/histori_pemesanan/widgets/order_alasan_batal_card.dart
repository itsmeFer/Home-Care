import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';

/// Card to display cancellation reason and timestamp in order details.
class OrderAlasanBatalCard extends StatelessWidget {
  final String alasan;
  final String? dibatalkanAt;

  const OrderAlasanBatalCard({
    super.key,
    required this.alasan,
    this.dibatalkanAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HCColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HCColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(IconlyLight.dangerCircle, color: HCColors.danger, size: 18),
              SizedBox(width: 8),
              Text(
                'Alasan Pembatalan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alasan.isEmpty ? '-' : alasan,
            style: const TextStyle(
              fontSize: 14,
              color: HCColors.textDark,
              height: 1.5,
            ),
          ),
          if (dibatalkanAt != null && dibatalkanAt!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Dibatalkan pada: ${AppFormatters.dateTime(dibatalkanAt!)}',
              style: const TextStyle(fontSize: 12, color: HCColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

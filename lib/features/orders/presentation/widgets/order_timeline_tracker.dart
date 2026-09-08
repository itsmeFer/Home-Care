import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/orders/domain/order_models.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

/// Kartu status ringkas untuk bagian atas detail order.
class OrderStatusHeaderCard extends StatelessWidget {
  final String status;
  final String statusPayment;

  const OrderStatusHeaderCard({
    super.key,
    required this.status,
    required this.statusPayment,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = OrderStatusHelper.color(status);
    final statusLabel = OrderStatusHelper.label(status);
    final paymentLabel = OrderStatusHelper.paymentLabel(statusPayment);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              status == 'selesai'
                  ? IconlyBold.shieldDone
                  : status == 'dibatalkan'
                      ? IconlyBold.danger
                      : IconlyLight.timeCircle,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pembayaran: $paymentLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    color: HCColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Visualisasi timeline progres kunjungan perawat.
class OrderTimelineTracker extends StatelessWidget {
  final String statusOrder;
  final Map<String, dynamic>? timestamps;

  const OrderTimelineTracker({
    super.key,
    required this.statusOrder,
    this.timestamps,
  });

  @override
  Widget build(BuildContext context) {
    final steps = OrderTrackingHelper.getTrackingSteps(
      statusOrder,
      timestamps: timestamps,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                IconlyLight.activity,
                color: HCColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Status Kunjungan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;

              final Color stepColor = step.isActive
                  ? HCColors.primary
                  : step.isCompleted
                      ? HCColors.success
                      : HCColors.textMuted.withAlpha(80);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: step.isActive
                              ? HCColors.primary.withAlpha(30)
                              : step.isCompleted
                                  ? HCColors.success.withAlpha(25)
                                  : HCColors.bg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: stepColor,
                            width: step.isActive ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          step.icon,
                          size: 16,
                          color: stepColor,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 36,
                          color: step.isCompleted
                              ? HCColors.success.withAlpha(80)
                              : HCColors.textMuted.withAlpha(40),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: step.isActive
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: step.isActive
                                  ? HCColors.primary
                                  : step.isCompleted
                                      ? HCColors.textDark
                                      : HCColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: HCColors.textMuted.withAlpha(200),
                            ),
                          ),
                          if (step.timestamp != null &&
                              step.timestamp!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              step.timestamp!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: HCColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

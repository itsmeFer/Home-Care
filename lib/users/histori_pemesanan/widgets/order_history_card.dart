import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/features/orders/domain/order_models.dart';
import 'package:home_care/users/histori_pemesanan/widgets/order_history_status_helper.dart';
import 'package:intl/intl.dart';

class OrderHistoryCard extends StatelessWidget {
  final OrderHistory order;
  final bool isUnpaid;
  final bool isHistory;
  final VoidCallback onTap;
  final VoidCallback onPayDraft;
  final VoidCallback onConfirmCod;
  final VoidCallback onRate;

  const OrderHistoryCard({
    super.key,
    required this.order,
    this.isUnpaid = false,
    this.isHistory = false,
    required this.onTap,
    required this.onPayDraft,
    required this.onConfirmCod,
    required this.onRate,
  });

  bool _isDraftExpired(OrderHistory o) {
    if (!o.isDraft) return false;
    final paymentStatus = o.statusPembayaran.toLowerCase().trim();
    final orderStatus = o.statusOrder.toLowerCase().trim();
    if (paymentStatus == 'expired' || orderStatus == 'expired') return true;
    if (o.expiredAt == null || o.expiredAt!.isEmpty) return false;
    try {
      final exp = DateTime.parse(o.expiredAt!).toLocal();
      return DateTime.now().isAfter(exp);
    } catch (_) {
      return false;
    }
  }

  Widget _buildExpiredInfo(OrderHistory order) {
    if (!order.isDraft || order.expiredAt == null || order.expiredAt!.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final exp = DateTime.parse(order.expiredAt!).toLocal();
      final text = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(exp);
      final expired = _isDraftExpired(order);

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: (expired ? HCColors.danger : HCColors.warning).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              expired ? IconlyLight.dangerCircle : IconlyLight.timeCircle,
              size: 14,
              color: expired ? HCColors.danger : HCColors.warning,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                expired
                    ? 'Draft kadaluarsa pada $text'
                    : 'Selesaikan pembayaran sebelum $text',
                style: TextStyle(
                  fontSize: 11,
                  color: expired ? HCColors.danger : HCColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildRatingPrompt() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HCColors.accent.withValues(alpha: 0.08),
            HCColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HCColors.accent.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              IconlyBold.star,
              color: Color.fromARGB(255, 248, 179, 76),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bagaimana pengalaman Anda?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HCColors.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bantu kami meningkatkan layanan',
                  style: TextStyle(
                    fontSize: 11,
                    color: HCColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onRate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 252, 177, 17),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Beri Rating',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tgl = AppFormatters.date(order.tanggalMulai);
    final jam = AppFormatters.time(order.jamMulai);
    final isCod =
        order.metodePembayaran?.toLowerCase() == 'cod' ||
        order.metodePembayaran?.toLowerCase() == 'cash';
    final isSelesai = order.statusOrder.toLowerCase() == 'selesai';
    final needsRating = isHistory && isSelesai && !order.hasRating;
    final isDraftExpired = _isDraftExpired(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(12),
        border: isUnpaid
            ? Border.all(
                color: HCColors.danger.withValues(alpha: 0.3),
                width: 1.5,
              )
            : needsRating
                ? Border.all(
                    color: HCColors.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isUnpaid
                            ? HCColors.danger.withValues(alpha: 0.08)
                            : needsRating
                                ? HCColors.accent.withValues(alpha: 0.08)
                                : HCColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: order.gambarLayanan != null && order.gambarLayanan!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                order.gambarLayanan!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  IconlyLight.activity,
                                  color: isUnpaid
                                      ? HCColors.danger
                                      : needsRating
                                          ? HCColors.accent
                                          : HCColors.primary,
                                  size: 24,
                                ),
                              ),
                            )
                          : Icon(
                              IconlyLight.activity,
                              color: isUnpaid
                                  ? HCColors.danger
                                  : needsRating
                                      ? HCColors.accent
                                      : HCColors.primary,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.kodeOrder,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: HCColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: OrderHistoryStatusHelper.paymentStatusColor(
                                    order.statusPembayaran,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  OrderHistoryStatusHelper.paymentStatusLabel(
                                    order.statusPembayaran,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: OrderHistoryStatusHelper.paymentStatusColor(
                                      order.statusPembayaran,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: OrderHistoryStatusHelper.statusColor(
                                    order.statusOrder,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  OrderHistoryStatusHelper.statusLabel(
                                    order.statusOrder,
                                  ),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: OrderHistoryStatusHelper.statusColor(
                                      order.statusOrder,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),
                Text(
                  order.namaLayanan,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: HCColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (order.tipeLayanan != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: HCColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.tipeLayanan!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: HCColors.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      'Qty: ${order.qty ?? 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: HCColors.textMuted.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      IconlyLight.calendar,
                      size: 14,
                      color: HCColors.textMuted.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tgl,
                      style: TextStyle(
                        fontSize: 12,
                        color: HCColors.textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      IconlyLight.timeCircle,
                      size: 14,
                      color: HCColors.textMuted.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      jam,
                      style: TextStyle(
                        fontSize: 12,
                        color: HCColors.textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                _buildExpiredInfo(order),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Bayar',
                          style: TextStyle(
                            fontSize: 11,
                            color: HCColors.textMuted.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.currency(order.totalBayar),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: isUnpaid ? HCColors.danger : HCColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (order.isDraft && !isDraftExpired)
                      ElevatedButton(
                        onPressed: onPayDraft,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HCColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Bayar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (order.isDraft && isDraftExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: HCColors.textMuted.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Draft Expired',
                          style: TextStyle(
                            color: HCColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else if (isUnpaid && isCod)
                      ElevatedButton(
                        onPressed: onConfirmCod,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HCColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Konfirmasi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (isUnpaid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: HCColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Bayar Manual',
                          style: TextStyle(
                            color: HCColors.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      Icon(
                        IconlyLight.arrowRight2,
                        size: 16,
                        color: HCColors.textMuted.withValues(alpha: 0.5),
                      ),
                  ],
                ),
                if (needsRating) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 12),
                  _buildRatingPrompt(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

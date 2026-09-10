import 'package:flutter/material.dart';
import 'package:home_care/admin/layanan_masuk/models/order_detail_admin_model.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';

class OrderAddonsTab extends StatelessWidget {
  final OrderLayananDetailAdmin order;

  const OrderAddonsTab({super.key, required this.order});

  static const Color _primary = AppColors.primary;
  static const Color _lightTeal = AppColors.lightTeal;
  static const Color _textMuted = AppColors.textMuted;

  String _fmtUang(dynamic val) => AppFormatters.currency(val);

  @override
  Widget build(BuildContext context) {
    final addons = order.addons;

    if (addons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: _textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada addon',
              style: TextStyle(fontSize: 14, color: _textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: addons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final addon = addons[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _lightTeal.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart,
                      color: _primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon.namaAddon,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (addon.deskripsi != null &&
                            addon.deskripsi!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            addon.deskripsi!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Harga Satuan',
                        style: TextStyle(fontSize: 12, color: _textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtUang(addon.hargaSatuan),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Qty',
                        style: TextStyle(fontSize: 12, color: _textMuted),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'x${addon.qty}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(fontSize: 12, color: _textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtUang(addon.subtotal),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

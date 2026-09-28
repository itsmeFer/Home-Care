import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';

class OrderTabAddons extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTabAddons({super.key, required this.order});

  String _fmtUang(dynamic val) => AppFormatters.currency(val);

  @override
  Widget build(BuildContext context) {
    final addons = (order['addons'] is List) ? order['addons'] as List : [];

    if (addons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: HCColor.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada addon untuk order ini.',
              style: TextStyle(color: HCColor.textMuted, fontSize: 13),
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
        final addon = addons[index] as Map<String, dynamic>;
        final addonDetail = addon['addon'] as Map<String, dynamic>?;

        final namaAddon =
            addon['nama_addon']?.toString() ??
            addonDetail?['nama_addon']?.toString() ??
            '-';
        final hargaSatuan = addon['harga_satuan'];
        final qty = addon['qty'] ?? 1;
        final subtotal = addon['subtotal'];
        final deskripsi = addonDetail?['deskripsi']?.toString();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HCColor.lightTeal.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HCColor.primary.withValues(alpha: 0.2),
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
                      color: HCColor.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart,
                      color: HCColor.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaAddon,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (deskripsi != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            deskripsi,
                            style: const TextStyle(
                              fontSize: 12,
                              color: HCColor.textMuted,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColor.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtUang(hargaSatuan),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColor.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: HCColor.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: HCColor.primary,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColor.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtUang(subtotal),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: HCColor.primary,
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

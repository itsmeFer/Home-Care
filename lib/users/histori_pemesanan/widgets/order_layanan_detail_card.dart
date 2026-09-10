import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';

class OrderLayananDetailCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderLayananDetailCard({super.key, required this.order});

  List<Map<String, dynamic>> _getOrderAddons() {
    final raw = order['order_addons'] ?? order['addons'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HCColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HCColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: HCColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: HCColors.textMuted.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: HCColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: HCColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final addons = _getOrderAddons();
    final durasi = order['durasi_menit_per_visit'] ?? order['durasi_menit'] ?? '-';
    final visit = order['jumlah_visit_dipesan'] ?? order['jumlah_visit'] ?? '-';

    return Column(
      children: [
        // Layanan Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HCColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                  Icon(IconlyLight.activity, color: HCColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Layanan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: HCColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order['nama_layanan']?.toString() ?? '-',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: HCColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    'Tipe: ${order['tipe_layanan'] ?? '-'}',
                    IconlyLight.bag2,
                  ),
                  _buildInfoChip(
                    'Durasi: $durasi menit',
                    IconlyLight.timeCircle,
                  ),
                  _buildInfoChip('Qty: ${order['qty'] ?? 1}', IconlyLight.buy),
                  _buildInfoChip(
                    'Visit: ${visit}x',
                    IconlyLight.swap,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Addons Card
        if (addons.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HCColors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                    Icon(IconlyLight.plus, color: HCColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add-ons',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: HCColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(addons.length, (index) {
                  final addon = addons[index];
                  final namaAddon = addon['nama_addon']?.toString() ?? '-';
                  final qty = int.tryParse(addon['qty']?.toString() ?? '0') ?? 0;
                  final hargaSatuan =
                      num.tryParse(addon['harga_satuan']?.toString() ?? '0') ?? 0;
                  final subtotal =
                      num.tryParse(addon['subtotal']?.toString() ?? '0') ?? 0;

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: index == addons.length - 1 ? 0 : 12,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: HCColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: HCColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaAddon,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: HCColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Qty',
                              style: TextStyle(
                                fontSize: 12,
                                color: HCColors.textMuted,
                              ),
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: HCColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Harga satuan',
                              style: TextStyle(
                                fontSize: 12,
                                color: HCColors.textMuted,
                              ),
                            ),
                            Text(
                              AppFormatters.currency(hargaSatuan),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: HCColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 12,
                                color: HCColors.textMuted,
                              ),
                            ),
                            Text(
                              AppFormatters.currency(subtotal),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: HCColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // Jadwal & Lokasi Card
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HCColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                  Icon(IconlyLight.calendar, color: HCColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Jadwal & Lokasi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: HCColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                IconlyLight.calendar,
                'Tanggal',
                AppFormatters.date(order['tanggal_mulai']?.toString()),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                IconlyLight.timeCircle,
                'Jam',
                AppFormatters.time(order['jam_mulai']?.toString()),
              ),
              const Divider(height: 24),
              _buildDetailRow(
                IconlyLight.location,
                'Alamat',
                order['alamat_lengkap']?.toString() ?? '-',
              ),
              const SizedBox(height: 8),
              Text(
                [order['kecamatan'], order['kota']]
                    .where((e) => e != null && e.toString().isNotEmpty)
                    .join(', '),
                style: const TextStyle(fontSize: 13, color: HCColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

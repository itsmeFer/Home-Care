import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/orders/domain/addon_model.dart';

class BookingSummaryStep extends StatelessWidget {
  final String namaLayanan;
  final double hargaLayanan;
  final String tanggal;
  final String jam;
  final String lokasi;
  final int qty;
  final List<Addon> selectedAddons;
  final double total;
  final String Function(double) formatRupiah;

  const BookingSummaryStep({
    super.key,
    required this.namaLayanan,
    required this.hargaLayanan,
    required this.tanggal,
    required this.jam,
    required this.lokasi,
    required this.qty,
    required this.selectedAddons,
    required this.total,
    required this.formatRupiah,
  });

  Widget _buildCardSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: HCColor.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.width < 380;

    return _buildCardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Layanan', namaLayanan),
          _buildSummaryRow('Tanggal', tanggal),
          _buildSummaryRow('Jam', jam),
          _buildSummaryRow('Lokasi', lokasi),
          const Divider(height: 24),
          _buildSummaryRow('Harga layanan', formatRupiah(hargaLayanan)),
          _buildSummaryRow('Qty', '${qty}x'),
          if (selectedAddons.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...selectedAddons.map(
              (addon) => _buildSummaryRow(
                addon.namaAddon,
                formatRupiah(addon.hargaFix),
              ),
            ),
          ],
          const Divider(height: 24),
          small
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Bayar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatRupiah(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: HCColor.primary,
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total Bayar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      formatRupiah(total),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: HCColor.primary,
                      ),
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/admin/fee/models/fee_models.dart';

class UserFeeDistributionChart extends StatelessWidget {
  final List<FeeByLayanan> byLayanan;

  const UserFeeDistributionChart({super.key, required this.byLayanan});

  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _textSub = AppColors.textSecondary;

  static const List<Color> _palette = [
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  static Color colorForLayanan(int layananId) {
    if (layananId <= 0) return _palette[0];
    return _palette[layananId % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final totalAll = byLayanan.fold<double>(
      0,
      (prev, item) => prev + item.totalFee,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Fee per Layanan',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Komposisi fee yang diterima user berdasarkan layanan.',
            style: TextStyle(color: _textSub, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (byLayanan.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Belum ada data fee per layanan.',
                  style: TextStyle(color: _textSub, fontSize: 12),
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildPieSections(totalAll),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: byLayanan.map((l) {
                        final percentage = totalAll == 0
                            ? 0.0
                            : (l.totalFee / totalAll * 100);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colorForLayanan(l.layananId),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  l.layananNama,
                                  style: const TextStyle(
                                    color: _text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: _textSub,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(double total) {
    final list = <PieChartSectionData>[];

    for (final item in byLayanan) {
      final value = item.totalFee;
      if (value <= 0) continue;

      final percentage = total == 0 ? 0.0 : (value / total * 100);
      list.add(
        PieChartSectionData(
          value: value,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          color: colorForLayanan(item.layananId),
        ),
      );
    }

    if (list.isEmpty) {
      list.add(
        PieChartSectionData(
          value: 1,
          title: '0%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          color: _border,
        ),
      );
    }

    return list;
  }
}

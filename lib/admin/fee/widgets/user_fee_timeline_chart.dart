import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';

class UserFeeTimelineChart extends StatelessWidget {
  final List<FeeTimelinePoint> timeline;

  const UserFeeTimelineChart({super.key, required this.timeline});

  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _textSub = AppColors.textSecondary;
  static const Color _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
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
            'Pergerakan Fee (Timeline)',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Grafik fee diterima per tanggal selesai order.',
            style: TextStyle(color: _textSub, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: timeline.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data timeline.',
                      style: TextStyle(color: _textSub, fontSize: 12),
                    ),
                  )
                : LineChart(_buildLineChartData()),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final spots = <FlSpot>[];
    timeline.asMap().forEach((index, point) {
      spots.add(FlSpot(index.toDouble(), point.amount));
    });

    double maxY = 0;
    for (final s in spots) {
      if (s.y > maxY) maxY = s.y;
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        horizontalInterval: maxY == 0 ? 1 : maxY / 4,
        drawVerticalLine: false,
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (timeline.length / 4).clamp(1, 999).toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= timeline.length) {
                return const SizedBox.shrink();
              }
              final date = timeline[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${date.day}/${date.month}',
                  style: const TextStyle(color: _textSub, fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: (value, meta) {
              if (value <= 0) return const SizedBox.shrink();
              return Text(
                '${(value / 1000).toStringAsFixed(0)}k',
                style: const TextStyle(color: _textSub, fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: _border)),
      minX: 0,
      maxX: spots.isEmpty ? 0 : spots.length.toDouble() - 1,
      minY: 0,
      maxY: maxY == 0 ? 1 : maxY * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _primary,
          barWidth: 2.8,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _primary.withValues(alpha: 0.25),
                _primary.withValues(alpha: 0.03),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}

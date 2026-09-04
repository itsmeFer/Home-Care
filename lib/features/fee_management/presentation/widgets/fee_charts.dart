import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';
import 'package:home_care/features/fee_management/presentation/widgets/fee_ui_components.dart';

enum FeeChartType { bar, pie, area }

typedef _ChartType = FeeChartType;
class FeeChartSwitcher extends StatelessWidget {
  final List<FeeSimItem> items;
  final num totalNominal;
  final FeeChartType chartType;
  final bool isGlobal;

  const FeeChartSwitcher({
    required this.items,
    required this.totalNominal,
    required this.chartType,
    required this.isGlobal,
  });

  @override
  Widget build(BuildContext context) {
    Widget chart;
    switch (chartType) {
      case FeeChartType.bar:
        chart = FeeBarChart(items: items, totalNominal: totalNominal);
        break;
      case FeeChartType.pie:
        chart = FeePieChart(items: items, totalNominal: totalNominal);
        break;
      case FeeChartType.area:
        chart = FeeAreaChart(items: items, totalNominal: totalNominal);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isGlobal
              ? 'Grafik Distribusi Fee Global'
              : 'Grafik Distribusi Fee per Penerima',
          style: const TextStyle(
            color: kText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: chart),
      ],
    );
  }
}

class FeeBarChart extends StatelessWidget {
  final List<FeeSimItem> items;
  final num totalNominal;

  const FeeBarChart({required this.items, required this.totalNominal});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    num maxNominal = 0;
    for (final i in items) {
      if (i.nominal > maxNominal) maxNominal = i.nominal;
    }
    if (maxNominal <= 0) maxNominal = 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barMaxWidth = constraints.maxWidth - 80;

        return SingleChildScrollView(
          child: Column(
            children:
                items.map((e) {
                  final ratio =
                      e.nominal <= 0
                          ? 0.0
                          : (e.nominal / maxNominal).clamp(0, 1).toDouble();
                  final barWidth =
                      (barMaxWidth * ratio).clamp(10, barMaxWidth).toDouble();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.nama,
                                style: const TextStyle(
                                  color: kText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${e.percent.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                color: kTextSub,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: kBorder,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    height: 12,
                                    width: barWidth,
                                    decoration: BoxDecoration(
                                      color: kPrimary.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatRupiah(e.nominal),
                              style: const TextStyle(
                                color: kTextSub,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }
}

class FeePieChart extends StatelessWidget {
  final List<FeeSimItem> items;
  final num totalNominal;

  const FeePieChart({required this.items, required this.totalNominal});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty || totalNominal <= 0) {
      return const Center(
        child: Text(
          'Tidak ada data untuk pie chart.',
          style: TextStyle(color: kTextSub),
        ),
      );
    }

    final sections =
        items.map((e) {
          final value = e.nominal.toDouble();
          return PieChartSectionData(
            value: value,
            title: '${e.percent.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          );
        }).toList();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 1,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  items.map((e) {
                    final persen =
                        e.nominal <= 0 || totalNominal <= 0
                            ? 0.0
                            : (e.nominal / totalNominal * 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.nama,
                              style: const TextStyle(
                                color: kText,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${persen.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: kTextSub,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
    );
  }
}

class FeeAreaChart extends StatelessWidget {
  final List<FeeSimItem> items;
  final num totalNominal;

  const FeeAreaChart({required this.items, required this.totalNominal});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data untuk grafik gunung.',
          style: TextStyle(color: kTextSub),
        ),
      );
    }

    double maxY = 0;
    for (final i in items) {
      if (i.nominal > maxY) maxY = i.nominal.toDouble();
    }
    if (maxY <= 0) maxY = 1;

    final spots = <FlSpot>[];
    for (int i = 0; i < items.length; i++) {
      spots.add(FlSpot(i.toDouble(), items[i].nominal.toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0, left: 2),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (items.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= items.length)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(color: kTextSub, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 40,
                showTitles: true,
                interval: maxY / 4,
                getTitlesWidget:
                    (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: kTextSub, fontSize: 10),
                    ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    kPrimary.withOpacity(0.35),
                    kPrimary.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

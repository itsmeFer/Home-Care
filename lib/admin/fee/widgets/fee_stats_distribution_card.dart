import 'package:flutter/material.dart';
import 'package:home_care/admin/fee/models/fee_models.dart';
import 'package:home_care/admin/fee/widgets/fee_chart_section.dart';
import 'package:home_care/admin/fee/widgets/fee_charts.dart';
import 'package:home_care/admin/fee/widgets/fee_ui_components.dart';

enum FeeSimMode { perItem, semuaItem }

class FeeStatsDistributionCard extends StatelessWidget {
  final String itemLabel;
  final FeeSimMode mode;
  final FeeChartType chartType;
  final ValueChanged<FeeSimMode> onModeChanged;
  final ValueChanged<FeeChartType> onChartTypeChanged;
  final bool loading;
  final String? error;
  final List<FeeSimItem> items;
  final num totalNominal;
  final bool globalLoading;
  final String? globalError;
  final List<FeeSimItem> globalItems;
  final num globalTotalNominal;

  const FeeStatsDistributionCard({
    super.key,
    required this.itemLabel,
    required this.mode,
    required this.chartType,
    required this.onModeChanged,
    required this.onChartTypeChanged,
    required this.loading,
    required this.error,
    required this.items,
    required this.totalNominal,
    required this.globalLoading,
    required this.globalError,
    required this.globalItems,
    required this.globalTotalNominal,
  });

  @override
  Widget build(BuildContext context) {
    return MiniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Distribusi Fee',
            style: TextStyle(
              color: kText,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('Per ${itemLabel.toUpperCase()}'),
                selected: mode == FeeSimMode.perItem,
                onSelected: (v) {
                  if (!v) return;
                  onModeChanged(FeeSimMode.perItem);
                },
              ),
              ChoiceChip(
                label: Text('Semua ${itemLabel.toUpperCase()} (Leaderboard)'),
                selected: mode == FeeSimMode.semuaItem,
                onSelected: (v) {
                  if (!v) return;
                  onModeChanged(FeeSimMode.semuaItem);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Bar'),
                selected: chartType == FeeChartType.bar,
                onSelected: (v) {
                  if (!v) return;
                  onChartTypeChanged(FeeChartType.bar);
                },
              ),
              ChoiceChip(
                label: const Text('Pie'),
                selected: chartType == FeeChartType.pie,
                onSelected: (v) {
                  if (!v) return;
                  onChartTypeChanged(FeeChartType.pie);
                },
              ),
              ChoiceChip(
                label: const Text('Gunung'),
                selected: chartType == FeeChartType.area,
                onSelected: (v) {
                  if (!v) return;
                  onChartTypeChanged(FeeChartType.area);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (mode == FeeSimMode.perItem)
            FeeChartSection(
              loading: loading,
              error: error,
              items: items,
              totalNominal: totalNominal,
              isGlobal: false,
              chartType: chartType,
            )
          else
            FeeChartSection(
              loading: globalLoading,
              error: globalError,
              items: globalItems,
              totalNominal: globalTotalNominal,
              isGlobal: true,
              chartType: chartType,
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';
import 'package:home_care/features/fee_management/presentation/widgets/fee_charts.dart';
import 'package:home_care/features/fee_management/presentation/widgets/fee_ui_components.dart';

class FeeChartSection extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<FeeSimItem> items;
  final num totalNominal;
  final bool isGlobal;
  final FeeChartType chartType;

  const FeeChartSection({
    super.key,
    required this.loading,
    required this.error,
    required this.items,
    required this.totalNominal,
    required this.isGlobal,
    required this.chartType,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (error != null) {
      return ErrorBox(message: error!);
    }
    if (items.isEmpty) {
      return HintBox(
        text:
            isGlobal
                ? 'Belum ada data fee global untuk ditampilkan.'
                : 'Belum ada penerima fee aktif.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MiniChip(
              text: 'Total dibagi: ${formatRupiah(totalNominal)}',
              icon: Icons.summarize_outlined,
            ),
            MiniChip(
              text: 'Penerima: ${items.length}',
              icon: Icons.people_alt_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: FeeChartSwitcher(
            items: items,
            totalNominal: totalNominal,
            chartType: chartType,
            isGlobal: isGlobal,
          ),
        ),
      ],
    );
  }
}

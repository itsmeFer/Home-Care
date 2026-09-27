import 'package:flutter/material.dart';
import 'package:home_care/admin/fee/models/fee_models.dart';
import 'package:home_care/admin/fee/widgets/fee_leaderboard_card.dart';
import 'package:home_care/admin/fee/widgets/fee_recipient_card.dart';
import 'package:home_care/admin/fee/widgets/fee_stats_distribution_card.dart';
import 'package:home_care/admin/fee/widgets/fee_ui_components.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

class FeeRecipientListSection extends StatelessWidget {
  final FeeSimMode mode;
  final String itemLabel;
  final bool loading;
  final String? error;
  final List<FeeRule> rules;
  final dynamic selectedItem;
  final void Function(FeeRule) onEditRule;
  final void Function(FeeRule) onDeleteRule;

  final bool globalLoading;
  final String? globalError;
  final List<FeeSimItem> globalItems;

  const FeeRecipientListSection({
    super.key,
    required this.mode,
    required this.itemLabel,
    required this.loading,
    required this.error,
    required this.rules,
    required this.selectedItem,
    required this.onEditRule,
    required this.onDeleteRule,
    required this.globalLoading,
    required this.globalError,
    required this.globalItems,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == FeeSimMode.perItem) {
      if (loading) {
        return Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: AppSkeleton(
                height: 80,
                width: double.infinity,
                borderRadius: 16,
              ),
            ),
          ),
        );
      }
      if (error != null) {
        return ErrorBox(message: error!);
      }
      if (rules.isEmpty) {
        return HintBox(
          text:
              'Belum ada penerima fee untuk $itemLabel ini. Klik "Tambah Penerima".',
        );
      }
      return Column(
        children: rules
            .map(
              (r) => FeeRecipientCard(
                rule: r,
                itemHargaFix: selectedItem?.hargaFix ?? 0,
                onEdit: () => onEditRule(r),
                onDelete: () => onDeleteRule(r),
              ),
            )
            .toList(),
      );
    }

    // Global Mode
    if (globalLoading) {
      return Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: AppSkeleton(
              height: 72,
              width: double.infinity,
              borderRadius: 16,
            ),
          ),
        ),
      );
    }
      if (globalError != null) {
      return ErrorBox(message: globalError!);
    }
    if (globalItems.isEmpty) {
      return const HintBox(text: 'Belum ada data leaderboard.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leaderboard Penerima Fee (semua $itemLabel)',
          style: const TextStyle(
            color: kText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(globalItems.length, (i) {
          final x = globalItems[i];
          return FeeLeaderboardCard(item: x, rank: i + 1);
        }),
      ],
    );
  }
}

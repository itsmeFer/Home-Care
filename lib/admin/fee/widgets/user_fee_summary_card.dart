import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';

class UserFeeSummaryCard extends StatelessWidget {
  final FeeByLayanan? selectedLayanan;
  final double totalSemuaLayanan;

  const UserFeeSummaryCard({
    super.key,
    required this.selectedLayanan,
    required this.totalSemuaLayanan,
  });

  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _textSub = AppColors.textSecondary;
  static const Color _success = AppColors.success;

  @override
  Widget build(BuildContext context) {
    final selected = selectedLayanan;
    final totalSelected = selected?.totalFee ?? totalSemuaLayanan;

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
          Text(
            selected == null
                ? 'Total Fee Diterima (Semua Layanan)'
                : 'Total Fee Diterima dari ${selected.layananNama}',
            style: const TextStyle(color: _textSub, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.formatRupiah(totalSelected),
            style: const TextStyle(
              color: _text,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: _success, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  selected == null
                      ? 'Akumulasi semua fee yang diterima user pada periode & status ini.'
                      : 'Akumulasi fee hanya dari layanan ini pada periode & status ini.',
                  style: const TextStyle(color: _textSub, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

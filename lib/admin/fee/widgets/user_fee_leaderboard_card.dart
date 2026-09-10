import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';

class UserFeeLeaderboardCard extends StatelessWidget {
  final List<LeaderboardItem> leaderboard;
  final SimpleUserOption? selectedUser;

  const UserFeeLeaderboardCard({
    super.key,
    required this.leaderboard,
    required this.selectedUser,
  });

  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _textSub = AppColors.textSecondary;
  static const Color _primary = Color(0xFF2563EB);
  static const Color _bg = AppColors.background;

  @override
  Widget build(BuildContext context) {
    if (leaderboard.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: const Text(
          'Belum ada leaderboard penerima fee pada filter ini.',
          style: TextStyle(color: _textSub, fontSize: 12),
        ),
      );
    }

    final top3 = leaderboard.take(3).toList();

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
            'Leaderboard Penerima Fee (Global)',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Top penerima fee terbesar pada periode & filter yang sama.',
            style: TextStyle(color: _textSub, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...top3.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isCurrent =
                selectedUser != null && selectedUser!.id == item.userId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isCurrent ? _primary.withValues(alpha: 0.07) : _bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? _primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  _buildRankBadge(index + 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.nama,
                      style: TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppFormatters.formatRupiah(item.totalFee),
                    style: const TextStyle(
                      color: _text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bg;
    Color textColor = Colors.white;

    switch (rank) {
      case 1:
        bg = const Color(0xFFFACC15);
        break;
      case 2:
        bg = const Color(0xFFE5E7EB);
        textColor = _text;
        break;
      case 3:
        bg = const Color(0xFF9CA3AF);
        break;
      default:
        bg = _border;
        textColor = _text;
    }

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        '$rank',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

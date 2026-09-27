import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class AddonPaginationBar extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final int totalItems;
  final int currentItemsCount;
  final ValueChanged<int> onPageChanged;

  const AddonPaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.totalItems,
    required this.currentItemsCount,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Menampilkan $currentItemsCount dari $totalItems data",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$currentPage / $lastPage",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: currentPage < lastPage ? () => onPageChanged(currentPage + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

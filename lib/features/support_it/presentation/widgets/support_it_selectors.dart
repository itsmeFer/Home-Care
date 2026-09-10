import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/support_it/domain/support_it_models.dart';

class SupportItCategorySelector extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const SupportItCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _primary = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    final categories = TicketCategoryItem.defaultCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori Masalah *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: _text,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories.map((cat) {
            final isSelected = selectedCategory == cat.value;
            return InkWell(
              onTap: () => onSelected(cat.value),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? _primary.withValues(alpha: 0.1) : _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _primary : _border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 18,
                      color: isSelected ? _primary : _muted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? _primary : _text,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class SupportItPrioritySelector extends StatelessWidget {
  final String selectedPriority;
  final ValueChanged<String> onSelected;

  const SupportItPrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onSelected,
  });

  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final priorities = TicketPriorityItem.defaultPriorities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prioritas *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: _text,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: priorities.map((p) {
            final isSelected = selectedPriority == p.value;
            final color = p.color;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onSelected(p.value),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.1) : _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : _border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          p.icon,
                          size: 18,
                          color: isSelected ? color : _muted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? color : _text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

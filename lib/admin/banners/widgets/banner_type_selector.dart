import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

/// Selector tipe tampilan kartu banner (Landscape 5:2, Square 1:1, Full Width 16:9).
class BannerTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const BannerTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard_customize_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Tipe Format Banner *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTypeOption(
              type: 'landscape',
              title: 'Landscape',
              ratio: '5:2',
              icon: Icons.view_day_outlined,
            ),
            const SizedBox(width: 10),
            _buildTypeOption(
              type: 'square',
              title: 'Square',
              ratio: '1:1',
              icon: Icons.grid_view_rounded,
            ),
            const SizedBox(width: 10),
            _buildTypeOption(
              type: 'full_width',
              title: 'Full Width',
              ratio: 'Card List',
              icon: Icons.view_carousel_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required String type,
    required String title,
    required String ratio,
    required IconData icon,
  }) {
    final isSelected = selectedType == type;
    const lightColor = Color(0xFFE6FAFA);

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? lightColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isSelected ? AppColors.primary : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isSelected ? AppColors.primary : Colors.grey.shade800,
                ),
              ),
              Text(
                ratio,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

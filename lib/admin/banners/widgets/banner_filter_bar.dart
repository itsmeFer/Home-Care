import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class BannerFilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String query;
  final String? selectedType;
  final int? filterActive;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<int?> onActiveChanged;
  final VoidCallback onReset;

  const BannerFilterBar({
    super.key,
    required this.searchCtrl,
    required this.query,
    required this.selectedType,
    required this.filterActive,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onTypeChanged,
    required this.onActiveChanged,
    required this.onReset,
  });

  bool get hasActiveFilter =>
      query.isNotEmpty || selectedType != null || filterActive != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Cari judul, subjudul, promo banner...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClearQuery,
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Semua Tipe',
                  isSelected: selectedType == null,
                  onTap: () => onTypeChanged(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Landscape (5:2)',
                  isSelected: selectedType == 'landscape',
                  onTap: () => onTypeChanged('landscape'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Square (1:1)',
                  isSelected: selectedType == 'square',
                  onTap: () => onTypeChanged('square'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Full Width',
                  isSelected: selectedType == 'full_width',
                  onTap: () => onTypeChanged('full_width'),
                ),
                const SizedBox(width: 12),
                Container(height: 18, width: 1, color: Colors.grey.shade300),
                const SizedBox(width: 12),
                _buildFilterChip(
                  label: 'Aktif',
                  isSelected: filterActive == 1,
                  accentColor: AppColors.success,
                  onTap: () => onActiveChanged(filterActive == 1 ? null : 1),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Nonaktif',
                  isSelected: filterActive == 0,
                  accentColor: AppColors.error,
                  onTap: () => onActiveChanged(filterActive == 0 ? null : 0),
                ),
                if (hasActiveFilter) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: onReset,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? accentColor,
    required VoidCallback onTap,
  }) {
    final effectiveAccent = accentColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? effectiveAccent.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? effectiveAccent : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? effectiveAccent : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

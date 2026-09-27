import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class CategoryFilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String query;
  final int? isActive;
  final bool reorderMode;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<int?> onStatusChanged;
  final VoidCallback onToggleReorderMode;
  final VoidCallback onReset;

  const CategoryFilterBar({
    super.key,
    required this.searchCtrl,
    required this.query,
    required this.isActive,
    required this.reorderMode,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onStatusChanged,
    required this.onToggleReorderMode,
    required this.onReset,
  });

  bool get hasActiveFilter => query.isNotEmpty || isActive != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            enabled: !reorderMode,
            decoration: InputDecoration(
              hintText: "Cari nama atau deskripsi kategori...",
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClearQuery,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
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
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey("cat_status_$isActive"),
                  isExpanded: true,
                  initialValue: isActive,
                  decoration: InputDecoration(
                    labelText: "Status",
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text("Semua status"),
                    ),
                    DropdownMenuItem<int?>(
                      value: 1,
                      child: Text("Aktif"),
                    ),
                    DropdownMenuItem<int?>(
                      value: 0,
                      child: Text("Nonaktif"),
                    ),
                  ],
                  onChanged: reorderMode ? null : onStatusChanged,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: reorderMode ? AppColors.primary.withValues(alpha: 0.1) : null,
                  side: BorderSide(color: reorderMode ? AppColors.primary : Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onPressed: onToggleReorderMode,
                icon: Icon(
                  reorderMode ? Icons.close : Icons.swap_vert_rounded,
                  size: 18,
                  color: reorderMode ? AppColors.primary : Colors.grey.shade700,
                ),
                label: Text(
                  reorderMode ? "Batal" : "Atur Urutan",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: reorderMode ? AppColors.primary : Colors.grey.shade700,
                  ),
                ),
              ),
              if (hasActiveFilter && !reorderMode) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: "Reset filter",
                  onPressed: onReset,
                  icon: const Icon(Icons.filter_alt_off_outlined, color: Colors.grey),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

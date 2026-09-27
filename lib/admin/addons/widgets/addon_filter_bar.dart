import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/models/addon_admin_model.dart';
import 'package:home_care/core/theme/app_colors.dart';

class AddonFilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String query;
  final int? selectedCategoryId;
  final int? filterActive;
  final List<AddonCategoryItem> categoriesDropdown;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int?> onStatusChanged;
  final VoidCallback onReset;

  const AddonFilterBar({
    super.key,
    required this.searchCtrl,
    required this.query,
    required this.selectedCategoryId,
    required this.filterActive,
    required this.categoriesDropdown,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onReset,
  });

  bool get hasActiveFilter =>
      query.isNotEmpty || selectedCategoryId != null || filterActive != null;

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
            decoration: InputDecoration(
              hintText: "Cari nama, kode, atau deskripsi add-on...",
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              final categoryField = DropdownButtonFormField<int?>(
                key: ValueKey("cat_filter_$selectedCategoryId"),
                isExpanded: true,
                initialValue: selectedCategoryId,
                decoration: InputDecoration(
                  labelText: "Kategori",
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text("Semua kategori", overflow: TextOverflow.ellipsis),
                  ),
                  ...categoriesDropdown.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: onCategoryChanged,
              );

              final statusField = DropdownButtonFormField<int?>(
                key: ValueKey("status_filter_$filterActive"),
                isExpanded: true,
                initialValue: filterActive,
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
                onChanged: onStatusChanged,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    categoryField,
                    const SizedBox(height: 8),
                    statusField,
                    if (hasActiveFilter) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onReset,
                          icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                          label: const Text("Reset Filter", style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: categoryField),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: statusField),
                  if (hasActiveFilter) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: "Reset filter",
                      onPressed: onReset,
                      icon: const Icon(Icons.filter_alt_off_outlined, color: Colors.grey),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

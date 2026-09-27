import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class KategoriFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool? filterAktif;
  final ValueChanged<bool?> onFilterChanged;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final VoidCallback? onReorder;

  const KategoriFilterBar({
    super.key,
    required this.searchController,
    required this.filterAktif,
    required this.onFilterChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onRefresh,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final filterValue = filterAktif == null
        ? 'semua'
        : (filterAktif == true ? 'aktif' : 'nonaktif');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari nama kategori atau slug...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClearSearch,
                    ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: HCColor.primary, width: 1.5),
              ),
            ),
            onSubmitted: (_) => onSearchSubmitted(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Filter Status',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filterValue,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'semua', child: Text('Semua Status')),
                        DropdownMenuItem(value: 'aktif', child: Text('Aktif Saja')),
                        DropdownMenuItem(
                          value: 'nonaktif',
                          child: Text('Nonaktif Saja'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == 'aktif') {
                          onFilterChanged(true);
                        } else if (val == 'nonaktif') {
                          onFilterChanged(false);
                        } else {
                          onFilterChanged(null);
                        }
                      },
                    ),
                  ),
                ),
              ),
              if (onReorder != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onReorder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HCColor.primary,
                    side: const BorderSide(color: HCColor.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.swap_vert_rounded, size: 20),
                  label: const Text('Urutan'),
                ),
              ],
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

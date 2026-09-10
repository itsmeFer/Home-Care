import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class KategoriFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final bool? filterAktif;
  final ValueChanged<bool?> onFilterChanged;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;

  const KategoriFilterBar({
    super.key,
    required this.searchController,
    required this.filterAktif,
    required this.onFilterChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final filterValue = filterAktif == null
        ? 'semua'
        : (filterAktif == true ? 'aktif' : 'nonaktif');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama kategori atau slug...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearSearch,
                    ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
                        horizontal: 14, vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filterValue,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'semua', child: Text('Semua')),
                        DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                        DropdownMenuItem(
                            value: 'nonaktif', child: Text('Nonaktif')),
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
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Muat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

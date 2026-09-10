import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class PerawatFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String? filterStatus;
  final int? filterActive;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int?> onActiveChanged;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onClearSearch;
  final VoidCallback onApply;

  const PerawatFilterBar({
    super.key,
    required this.searchController,
    required this.filterStatus,
    required this.filterActive,
    required this.onStatusChanged,
    required this.onActiveChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Cari perawat (nama / kode / hp / koordinator)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.trim().isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: onClearSearch,
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        child: DropdownButton<String?>(
                          value: filterStatus,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Semua Status'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'verified',
                              child: Text('Verified'),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'rejected',
                              child: Text('Rejected'),
                            ),
                          ],
                          onChanged: onStatusChanged,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Filter Keaktifan',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: filterActive,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Semua'),
                            ),
                            DropdownMenuItem<int?>(
                              value: 1,
                              child: Text('Aktif'),
                            ),
                            DropdownMenuItem<int?>(
                              value: 0,
                              child: Text('Nonaktif'),
                            ),
                          ],
                          onChanged: onActiveChanged,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Terapkan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HCColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

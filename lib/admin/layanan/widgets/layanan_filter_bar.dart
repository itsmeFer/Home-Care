import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

class LayananFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final List<KategoriLayananItem> kategoriList;
  final String? selectedKategori;
  final bool? selectedAktif;
  final VoidCallback onSearchSubmitted;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onKategoriChanged;
  final ValueChanged<bool?> onAktifChanged;
  final VoidCallback onRefresh;

  const LayananFilterBar({
    super.key,
    required this.searchController,
    required this.kategoriList,
    required this.selectedKategori,
    required this.selectedAktif,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onKategoriChanged,
    required this.onAktifChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final statusValue = selectedAktif == null
        ? 'semua'
        : (selectedAktif == true ? 'aktif' : 'nonaktif');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari nama layanan atau deskripsi...',
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
                flex: 3,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
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
                    child: DropdownButton<String?>(
                      value: selectedKategori,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Semua Kategori'),
                        ),
                        ...kategoriList.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e.slug,
                            child: Text(
                              e.namaKategori,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: onKategoriChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
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
                      value: statusValue,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'semua',
                          child: Text('Semua'),
                        ),
                        DropdownMenuItem(
                          value: 'aktif',
                          child: Text('Aktif'),
                        ),
                        DropdownMenuItem(
                          value: 'nonaktif',
                          child: Text('Nonaktif'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == 'aktif') {
                          onAktifChanged(true);
                        } else if (val == 'nonaktif') {
                          onAktifChanged(false);
                        } else {
                          onAktifChanged(null);
                        }
                      },
                    ),
                  ),
                ),
              ),
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

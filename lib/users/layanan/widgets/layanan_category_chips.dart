import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

class LayananCategoryChips extends StatelessWidget {
  final bool isLoading;
  final List<KategoriLayananItem> kategoriList;
  final KategoriLayananItem? selectedKategori;
  final ValueChanged<KategoriLayananItem?> onSelect;

  const LayananCategoryChips({
    super.key,
    required this.isLoading,
    required this.kategoriList,
    required this.selectedKategori,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder:
                (_, index) => AppSkeleton(
                  width: index == 0 ? 70 : 100,
                  height: 36,
                  borderRadius: 20,
                ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: 'Semua',
                isSelected: selectedKategori == null,
                onTap: () => onSelect(null),
              ),
            ),
            ...kategoriList.map((kategori) {
              final isSelected =
                  selectedKategori?.id == kategori.id ||
                  (selectedKategori != null &&
                      selectedKategori!.namaKategori.toLowerCase() ==
                          kategori.namaKategori.toLowerCase());

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(
                  label: kategori.namaKategori,
                  isSelected: isSelected,
                  onTap: () => onSelect(kategori),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? HCColor.primary : HCColor.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? HCColor.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

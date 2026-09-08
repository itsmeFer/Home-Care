import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/features/orders/domain/addon_model.dart';

class BookingAddonsStep extends StatelessWidget {
  final bool isLoadingAddons;
  final List<Addon> availableAddons;
  final List<Addon> selectedAddons;
  final ValueChanged<Addon> onToggleAddon;
  final String Function(double) formatRupiah;

  const BookingAddonsStep({
    super.key,
    required this.isLoadingAddons,
    required this.availableAddons,
    required this.selectedAddons,
    required this.onToggleAddon,
    required this.formatRupiah,
  });

  Widget _buildCardSection({required BuildContext context, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCardSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambahan (Opsional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (isLoadingAddons)
            Column(
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: AppSkeleton(
                    width: double.infinity,
                    height: 52,
                    borderRadius: 12,
                  ),
                ),
              ),
            )
          else if (availableAddons.isEmpty)
            const Text(
              'Tidak ada add-ons tersedia',
              style: TextStyle(color: HCColor.textMuted),
            )
          else
            ...availableAddons.map((addon) {
              final isSelected = selectedAddons.contains(addon);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => onToggleAddon(addon),
                title: Text(
                  addon.namaAddon,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  formatRupiah(addon.hargaFix),
                  style: const TextStyle(
                    fontSize: 12,
                    color: HCColor.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                activeColor: HCColor.primary,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/features/orders/domain/addon_model.dart';

class BookingAddonsStep extends StatelessWidget {
  final bool isLoadingAddons;
  final List<Addon> availableAddons;
  final List<Addon> selectedAddons;
  final ValueChanged<Addon> onToggleAddon;
  final ValueChanged<Addon>? onIncrementAddon;
  final ValueChanged<Addon>? onDecrementAddon;
  final String Function(double) formatRupiah;

  const BookingAddonsStep({
    super.key,
    required this.isLoadingAddons,
    required this.availableAddons,
    required this.selectedAddons,
    required this.onToggleAddon,
    this.onIncrementAddon,
    this.onDecrementAddon,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Layanan Tambahan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              if (availableAddons.isNotEmpty)
                Text(
                  '${availableAddons.length} Item',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih alat medis atau tindakan pendukung sesuai kebutuhan',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoadingAddons)
            Column(
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: AppSkeleton(
                    width: double.infinity,
                    height: 68,
                    borderRadius: 16,
                  ),
                ),
              ),
            )
          else if (availableAddons.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(IconlyLight.infoSquare, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada add-ons tersedia untuk layanan ini',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            ...availableAddons.map((addon) {
              final isSelected = selectedAddons.contains(addon);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF7FCFC) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? HCColor.primary.withValues(alpha: 0.35)
                        : const Color(0xFFEEF2F6),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Squircle icon container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? HCColor.lightTeal : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSelected ? IconlyBold.activity : IconlyLight.activity,
                        color: isSelected ? HCColor.primary : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Addon Name & Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            addon.namaAddon,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            formatRupiah(addon.hargaFix),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: HCColor.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Stepper or Selection Button
                    if (isSelected)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Minus
                          InkWell(
                            onTap: () {
                              if (onDecrementAddon != null) {
                                onDecrementAddon!(addon);
                              } else {
                                onToggleAddon(addon);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HCColor.primary.withValues(alpha: 0.4),
                                ),
                                color: Colors.white,
                              ),
                              child: const Center(
                                child: Icon(Icons.remove, size: 14, color: HCColor.primary),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${addon.qty}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Plus
                          InkWell(
                            onTap: () {
                              if (onIncrementAddon != null) {
                                onIncrementAddon!(addon);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: HCColor.primary,
                              ),
                              child: const Center(
                                child: Icon(IconlyLight.plus, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: () => onToggleAddon(addon),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                            color: const Color(0xFFF8FAFC),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(IconlyLight.plus, size: 14, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Tambah',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

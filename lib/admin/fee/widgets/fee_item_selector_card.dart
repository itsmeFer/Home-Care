import 'package:flutter/material.dart';
import 'package:home_care/admin/fee/widgets/fee_ui_components.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class FeeItemSelectorCard extends StatelessWidget {
  final bool isAddon;
  final List<dynamic> items;
  final int? selectedId;
  final dynamic selectedItem;
  final bool loading;
  final int activeCount;
  final num sumPercent;
  final ValueChanged<int?> onItemSelected;
  final VoidCallback onRecalc;
  final VoidCallback onAddRecipient;

  const FeeItemSelectorCard({
    super.key,
    required this.isAddon,
    required this.items,
    required this.selectedId,
    required this.selectedItem,
    required this.loading,
    required this.activeCount,
    required this.sumPercent,
    required this.onItemSelected,
    required this.onRecalc,
    required this.onAddRecipient,
  });

  @override
  Widget build(BuildContext context) {
    final itemLabel = isAddon ? 'add-on' : 'layanan';
    final itemIcon =
        isAddon ? Icons.extension_outlined : Icons.medical_services_outlined;
    final itemColor = isAddon ? kAddon : kPrimary;

    return MiniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih $itemLabel untuk mengatur penerima fee:',
            style: const TextStyle(
              color: kTextSub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          InputDecorator(
            decoration: fieldDeco(
              hint: 'Pilih $itemLabel',
              prefixIcon: Icon(itemIcon),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedId,
                isExpanded: true,
                isDense: true,
                dropdownColor: Colors.white,
                items:
                    items.map((i) {
                      return DropdownMenuItem<int>(
                        value: i.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if ((i.gambarUrl ?? '').isNotEmpty) ...[
                              AppCachedImage(
                                imageUrl: i.gambarUrl,
                                width: 28,
                                height: 28,
                                borderRadius: BorderRadius.circular(8),
                                fit: BoxFit.cover,
                                errorWidget: const SizedBox(
                                  width: 28,
                                  height: 28,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ] else ...[
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: itemColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  itemIcon,
                                  size: 16,
                                  color: itemColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Text(
                                '${i.nama} â€¢ ${formatRupiah(i.hargaFix)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: kText),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                selectedItemBuilder: (context) {
                  return items.map<Widget>((i) {
                    return Row(
                      children: [
                        if ((i.gambarUrl ?? '').isNotEmpty) ...[
                          AppCachedImage(
                            imageUrl: i.gambarUrl,
                            width: 24,
                            height: 24,
                            borderRadius: BorderRadius.circular(8),
                            fit: BoxFit.cover,
                            errorWidget: Icon(
                              itemIcon,
                              size: 16,
                              color: itemColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          Icon(itemIcon, size: 18, color: itemColor),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            i.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
                onChanged: loading ? null : onItemSelected,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MiniChip(
                text: 'Aktif: $activeCount orang',
                icon: Icons.people_alt_outlined,
                color: itemColor,
              ),
              MiniChip(
                text: 'Total %: ${sumPercent.toStringAsFixed(2)}%',
                icon: Icons.percent,
                color: itemColor,
              ),
              if (selectedItem != null)
                MiniChip(
                  text: 'Harga: ${formatRupiah(selectedItem.hargaFix)}',
                  icon: Icons.payments_outlined,
                  color: itemColor,
                ),
            ],
          ),

          const SizedBox(height: 12),

          if (R.isPhone(context)) ...[
            RBtn(
              filled: false,
              onPressed: loading ? null : onRecalc,
              icon: Icons.calculate,
              color: itemColor,
              child: const Text('Bagi Ulang %'),
            ),
            const SizedBox(height: 10),
            RBtn(
              filled: true,
              onPressed: loading ? null : onAddRecipient,
              icon: Icons.add,
              color: itemColor,
              child: const Text('Tambah Penerima'),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: RBtn(
                    filled: false,
                    onPressed: loading ? null : onRecalc,
                    icon: Icons.calculate,
                    color: itemColor,
                    child: const Text('Bagi Ulang %'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RBtn(
                    filled: true,
                    onPressed: loading ? null : onAddRecipient,
                    icon: Icons.add,
                    color: itemColor,
                    child: const Text('Tambah Penerima'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

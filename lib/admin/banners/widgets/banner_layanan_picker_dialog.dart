import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';

/// Modal dialog untuk mencari dan memilih layanan yang ditautkan ke banner promo.
class BannerLayananPickerDialog extends StatefulWidget {
  final List<LayananModel> layananList;
  final LayananModel? initialSelected;

  const BannerLayananPickerDialog({
    super.key,
    required this.layananList,
    this.initialSelected,
  });

  static Future<LayananModel?> show({
    required BuildContext context,
    required List<LayananModel> layananList,
    LayananModel? currentSelected,
  }) {
    return showDialog<LayananModel?>(
      context: context,
      builder: (_) => BannerLayananPickerDialog(
        layananList: layananList,
        initialSelected: currentSelected,
      ),
    );
  }

  @override
  State<BannerLayananPickerDialog> createState() => _BannerLayananPickerDialogState();
}

class _BannerLayananPickerDialogState extends State<BannerLayananPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<LayananModel> _filteredList;
  LayananModel? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected;
    _filteredList = List.from(widget.layananList);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterLayanan(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredList = List.from(widget.layananList);
      } else {
        final q = query.toLowerCase().trim();
        _filteredList = widget.layananList.where((l) {
          final name = l.namaLayanan.toLowerCase();
          final code = l.kodeLayanan.toLowerCase();
          return name.contains(q) || code.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 480),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pilih Layanan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kode layanan...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filterLayanan('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFE6FAFA).withValues(alpha: 0.5),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: _filterLayanan,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.block, color: Colors.grey),
                    ),
                    title: const Text(
                      'Tidak ada layanan',
                      style: TextStyle(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Banner promosi umum tanpa link layanan',
                      style: TextStyle(fontSize: 11),
                    ),
                    tileColor: _selected == null ? const Color(0xFFE6FAFA) : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: _selected == null ? AppColors.primary : Colors.grey.shade200,
                        width: _selected == null ? 1.5 : 1,
                      ),
                    ),
                    trailing: _selected == null
                        ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(context, null);
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_filteredList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Layanan tidak ditemukan',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._filteredList.map((l) {
                      final isSelected = _selected?.id == l.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: l.gambarUrl != null && l.gambarUrl!.isNotEmpty
                                  ? AppCachedImage(
                                      imageUrl: l.gambarUrl!,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 100,
                                      memCacheHeight: 100,
                                      errorWidget: const Icon(Icons.medical_services_outlined, size: 24),
                                    )
                                  : Container(
                                      color: Colors.grey.shade100,
                                      child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 24),
                                    ),
                            ),
                          ),
                          title: Text(
                            l.namaLayanan,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${l.kodeLayanan} • ${formatRupiah(l.hargaFix)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          tileColor: isSelected ? const Color(0xFFE6FAFA) : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                              : null,
                          onTap: () {
                            Navigator.pop(context, l);
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

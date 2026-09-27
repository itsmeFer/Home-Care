import 'package:flutter/material.dart';
import 'package:home_care/admin/kategori/models/kategori_layanan_model.dart';
import 'package:home_care/admin/kategori/services/kategori_admin_service.dart';
import 'package:home_care/admin/kategori/widgets/kategori_card.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class KategoriReorderSheet extends StatefulWidget {
  final List<KategoriLayanan> initialItems;

  const KategoriReorderSheet({super.key, required this.initialItems});

  static Future<bool?> show({
    required BuildContext context,
    required List<KategoriLayanan> items,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => KategoriReorderSheet(initialItems: items),
    );
  }

  @override
  State<KategoriReorderSheet> createState() => _KategoriReorderSheetState();
}

class _KategoriReorderSheetState extends State<KategoriReorderSheet> {
  late List<KategoriLayanan> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  Future<void> _simpan() async {
    setState(() => _isSaving = true);
    try {
      final ids = _items.map((e) => e.id ?? 0).where((id) => id > 0).toList();
      await KategoriAdminService.aturUrutan(ids);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan urutan: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HCColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    color: HCColor.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atur Urutan Kategori',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tahan dan geser item untuk mengubah prioritas tampil',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('Tidak ada kategori untuk diatur'))
                  : ReorderableListView.builder(
                      itemCount: _items.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _items.removeAt(oldIndex);
                          _items.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (ctx, index) {
                        final item = _items[index];
                        final color = KategoriCard.parseHexColor(item.warna);

                        return Container(
                          key: ValueKey(item.id ?? index),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: HCColor.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: HCColor.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (item.gambarUrl != null &&
                                  item.gambarUrl!.isNotEmpty)
                                AppCachedImage(
                                  imageUrl: item.gambarUrl,
                                  width: 44,
                                  height: 44,
                                  borderRadius: BorderRadius.circular(8),
                                  fit: BoxFit.cover,
                                )
                              else
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    KategoriCard.mapIcon(item.icon),
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.namaKategori ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Slug: ${item.slug ?? '-'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.drag_handle_rounded,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Simpan Urutan Baru',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

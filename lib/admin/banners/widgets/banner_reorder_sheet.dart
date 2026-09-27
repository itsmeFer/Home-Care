import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';
import 'package:home_care/features/banners/data/banner_service.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';

class BannerReorderSheet extends StatefulWidget {
  final List<BannerModel> initialBanners;

  const BannerReorderSheet({super.key, required this.initialBanners});

  static Future<bool?> show({
    required BuildContext context,
    required List<BannerModel> banners,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BannerReorderSheet(initialBanners: banners),
    );
  }

  @override
  State<BannerReorderSheet> createState() => _BannerReorderSheetState();
}

class _BannerReorderSheetState extends State<BannerReorderSheet> {
  late List<BannerModel> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialBanners);
  }

  Future<void> _simpan() async {
    setState(() => _saving = true);
    try {
      final ids = _items.map((b) => b.id).toList();
      await BannerService.aturUrutan(ids);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan urutan: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Handle bar
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

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atur Urutan Banner',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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

            // List
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('Tidak ada banner untuk diatur'))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ReorderableListView.builder(
                        itemCount: _items.length,
                        onReorderItem: (oldIndex, newIndex) {
                          setState(() {
                            final item = _items.removeAt(oldIndex);
                            _items.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final b = _items[index];
                          return Container(
                            key: ValueKey(b.id),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 50,
                                  height: 36,
                                  child: b.gambarUrl != null && b.gambarUrl!.isNotEmpty
                                      ? AppCachedImage(
                                          imageUrl: b.gambarUrl,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 100,
                                          memCacheHeight: 72,
                                        )
                                      : Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image, size: 20, color: Colors.grey),
                                        ),
                                ),
                              ),
                              title: Text(
                                b.judul ?? 'Tanpa Judul',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      b.tipeCard.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Posisi: #${index + 1}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _simpan,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Urutan Baru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/admin/detail_layanan/services/detail_layanan_service.dart';
import 'package:home_care/admin/detail_layanan/widgets/detail_layanan_info_card.dart';
import 'package:home_care/admin/detail_layanan/widgets/detail_layanan_koordinator_card.dart';
import 'package:home_care/admin/detail_layanan/widgets/koordinator_multiselect_dialog.dart';
import 'package:home_care/admin/detail_layanan/widgets/layanan_edit_form_dialog.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/utils/app_image_compressor.dart';
import 'package:image_picker/image_picker.dart';

class DetailLayananPage extends StatefulWidget {
  final int layananId;

  const DetailLayananPage({super.key, required this.layananId});

  @override
  State<DetailLayananPage> createState() => _DetailLayananPageState();
}

class _DetailLayananPageState extends State<DetailLayananPage> {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  LayananDetail? _layanan;
  bool _isUploadingImage = false;
  bool _hasChanged = false;

  List<KoordinatorItem> _koordinatorLayanan = [];
  List<KoordinatorItem> _allKoordinator = [];
  bool _isLoadingKoordinator = false;
  bool _isSavingKoordinator = false;

  List<KategoriLayananItem> _kategoriList = [];

  @override
  void initState() {
    super.initState();
    _fetchKategori();
    _fetchDetail();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll('Exception: ', '')),
        backgroundColor: isError ? Colors.red : HCColor.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _kategoriLabel(String? slug) {
    if (slug == null || slug.trim().isEmpty) return '-';
    for (final item in _kategoriList) {
      if (item.slug == slug) return item.namaKategori;
    }
    return slug;
  }

  Future<void> _fetchKategori() async {
    try {
      final list = await DetailLayananService.fetchKategori();
      if (mounted) setState(() => _kategoriList = list);
    } catch (_) {}
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final data = await DetailLayananService.fetchDetail(widget.layananId);
      if (mounted) {
        setState(() => _layanan = data);
        await _fetchKoordinatorLayanan();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchKoordinatorLayanan() async {
    if (_layanan == null) return;
    try {
      setState(() => _isLoadingKoordinator = true);
      final list =
          await DetailLayananService.fetchKoordinatorLayanan(_layanan!.id);
      if (mounted) setState(() => _koordinatorLayanan = list);
    } catch (e) {
      _snack('Gagal mengambil koordinator layanan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingKoordinator = false);
    }
  }

  Future<void> _openKelolaKoordinatorDialog() async {
    if (_layanan == null) return;

    try {
      setState(() => _isSavingKoordinator = true);
      final all = await DetailLayananService.fetchAllKoordinator();
      _allKoordinator = all;
      final selectedIds = _koordinatorLayanan.map((e) => e.id).toSet();
      setState(() => _isSavingKoordinator = false);

      if (!mounted) return;
      final result = await showDialog<List<int>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => KoordinatorMultiSelectDialog(
          allKoordinator: _allKoordinator,
          selectedIds: selectedIds,
        ),
      );

      if (result == null) return;

      setState(() => _isSavingKoordinator = true);
      await DetailLayananService.syncKoordinator(_layanan!.id, result);
      _snack('Koordinator layanan berhasil diupdate');
      await _fetchKoordinatorLayanan();
    } catch (e) {
      _snack('Gagal menyimpan koordinator: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingKoordinator = false);
    }
  }

  Future<void> _updateKoordinatorPivot(
      int koordinatorId, bool aktif, String? catatan) async {
    if (_layanan == null) return;
    try {
      await DetailLayananService.updateKoordinatorPivot(
        layananId: _layanan!.id,
        koordinatorId: koordinatorId,
        aktif: aktif,
        catatan: catatan,
      );
      _snack('Status koordinator berhasil diupdate');
      await _fetchKoordinatorLayanan();
    } catch (e) {
      _snack('Gagal update status koordinator: $e', isError: true);
    }
  }

  Future<void> _updateLayanan(Map<String, dynamic> payload) async {
    if (_layanan == null) return;
    try {
      await DetailLayananService.updateLayanan(_layanan!.id, payload);
      _hasChanged = true;
      _snack('Layanan berhasil diupdate');
      await _fetchDetail();
    } catch (e) {
      _snack('Gagal mengupdate layanan: $e', isError: true);
    }
  }

  Future<void> _deleteLayanan() async {
    if (_layanan == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Layanan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Yakin ingin menghapus layanan "${_layanan!.namaLayanan}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DetailLayananService.deleteLayanan(_layanan!.id);
      _snack('Layanan berhasil dihapus');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack('Gagal menghapus layanan: $e', isError: true);
    }
  }

  Future<void> _openEditForm() async {
    if (_layanan == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LayananEditFormDialog(
        layanan: _layanan!,
        kategoriList: _kategoriList,
      ),
    );

    if (result == null) return;
    await _updateLayanan(result);
  }

  Future<void> _pickAndUploadImage() async {
    if (_layanan == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (picked == null) return;

      setState(() => _isUploadingImage = true);

      final compressedBytes = await AppImageCompressor.compressXFile(
        picked,
        maxDimension: 800,
        quality: 75,
      );

      final filename =
          'layanan_${_layanan!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await DetailLayananService.uploadGambarLayanan(
        layananId: _layanan!.id,
        compressedBytes: compressedBytes,
        filename: filename,
      );

      _hasChanged = true;
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      _snack('Gambar layanan berhasil diupdate');
      await _fetchDetail();
    } catch (e) {
      _snack('Gagal mengupload gambar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_hasChanged);
        }
      },
      child: Scaffold(
        backgroundColor: HCColor.bg,
        appBar: AppBar(
          backgroundColor: HCColor.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_hasChanged),
          ),
          title: const Text(
            'Detail Layanan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();
                await _fetchKategori();
                await _fetchDetail();
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: HCColor.primary))
            : _isError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage ?? 'Terjadi kesalahan',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : _layanan == null
                    ? const Center(child: Text('Data layanan tidak ditemukan'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DetailLayananInfoCard(
                              layanan: _layanan!,
                              kategoriLabel: _kategoriLabel(_layanan!.kategori),
                              onToggleActive: (val) {
                                _updateLayanan({'aktif': val});
                              },
                            ),
                            const SizedBox(height: 16),
                            DetailLayananKoordinatorCard(
                              koordinatorLayanan: _koordinatorLayanan,
                              isLoading: _isLoadingKoordinator,
                              isSaving: _isSavingKoordinator,
                              onManageKoordinator: _openKelolaKoordinatorDialog,
                              onTogglePivot: _updateKoordinatorPivot,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _deleteLayanan,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Hapus'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openEditForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HCColor.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed:
                                  _isUploadingImage ? null : _pickAndUploadImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HCColor.primaryDark,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: _isUploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.image),
                              label: Text(
                                _isUploadingImage
                                    ? 'Mengupload...'
                                    : 'Ubah Gambar Layanan',
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}

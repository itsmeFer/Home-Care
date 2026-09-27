import 'package:flutter/material.dart';
import 'package:home_care/admin/kategori/models/kategori_layanan_model.dart';
import 'package:home_care/admin/kategori/services/kategori_admin_service.dart';
import 'package:home_care/admin/kategori/widgets/kategori_card.dart';
import 'package:home_care/admin/kategori/widgets/kategori_filter_bar.dart';
import 'package:home_care/admin/kategori/widgets/kategori_form_dialog.dart';
import 'package:home_care/admin/kategori/widgets/kategori_reorder_sheet.dart';
import 'package:home_care/admin/kategori/widgets/kategori_skeleton.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_image_compressor.dart';
import 'package:image_picker/image_picker.dart';

class CrudKategoriPage extends StatefulWidget {
  const CrudKategoriPage({super.key});

  @override
  State<CrudKategoriPage> createState() => _CrudKategoriPageState();
}

class _CrudKategoriPageState extends State<CrudKategoriPage> {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  final TextEditingController _searchC = TextEditingController();
  List<KategoriLayanan> _kategoriList = [];
  bool? _filterAktif;

  @override
  void initState() {
    super.initState();
    _fetchKategori();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
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

  Future<void> _fetchKategori() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final list = await KategoriAdminService.fetchKategori(
        search: _searchC.text.trim(),
        aktif: _filterAktif,
      );
      if (mounted) setState(() => _kategoriList = list);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleKategori(KategoriLayanan item) async {
    if (item.id == null) return;
    try {
      await KategoriAdminService.toggleKategori(item.id!);
      _snack(
        item.aktif == true
            ? 'Kategori dinonaktifkan'
            : 'Kategori berhasil diaktifkan',
      );
      _fetchKategori();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _deleteKategori(KategoriLayanan item) async {
    if (item.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Kategori',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('Yakin ingin menghapus kategori "${item.namaKategori}"?'),
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
      await KategoriAdminService.deleteKategori(item.id!);
      _snack('Kategori berhasil dihapus');
      _fetchKategori();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _hapusGambarKategori(KategoriLayanan item) async {
    if (item.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Gambar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Yakin ingin menghapus gambar kategori "${item.namaKategori}"?',
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
      await KategoriAdminService.deleteGambar(item.id!);
      _snack('Gambar kategori berhasil dihapus');
      _fetchKategori();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _pickAndUploadImage(KategoriLayanan item) async {
    if (item.id == null) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      final bytes = await AppImageCompressor.compressXFile(picked);
      await KategoriAdminService.uploadGambar(
        kategoriId: item.id!,
        imageBytes: bytes,
        fileName: picked.name,
      );
      _snack('Gambar kategori berhasil diupload');
      _fetchKategori();
    } catch (e) {
      _snack('Gagal upload gambar: $e', isError: true);
    }
  }

  Future<void> _openReorderSheet() async {
    final updated = await KategoriReorderSheet.show(
      context: context,
      items: _kategoriList,
    );
    if (updated == true) {
      _snack('Urutan kategori berhasil diperbarui');
      _fetchKategori();
    }
  }

  Future<void> _openForm({KategoriLayanan? item}) async {
    final result = await showDialog<KategoriFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => KategoriFormDialog(item: item),
    );

    if (result == null) return;

    try {
      if (item == null) {
        final created = await KategoriAdminService.createKategori(result.payload);
        _snack('Kategori berhasil dibuat');

        if (result.imageBytes != null && created.id != null) {
          await KategoriAdminService.uploadGambar(
            kategoriId: created.id!,
            imageBytes: result.imageBytes!,
            fileName: result.imageName,
          );
        }
      } else {
        await KategoriAdminService.updateKategori(item.id!, result.payload);
        _snack('Kategori berhasil diupdate');

        if (result.imageBytes != null) {
          await KategoriAdminService.uploadGambar(
            kategoriId: item.id!,
            imageBytes: result.imageBytes!,
            fileName: result.imageName,
          );
        }
      }
      _fetchKategori();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const KategoriSkeleton();
    }

    if (_isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal Memuat Kategori',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Terjadi kesalahan saat menghubungi server',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchKategori,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_kategoriList.isEmpty) {
      final isFiltering =
          _searchC.text.trim().isNotEmpty || _filterAktif != null;

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HCColor.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.category_outlined,
                  size: 48,
                  color: HCColor.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isFiltering
                    ? 'Kategori Tidak Ditemukan'
                    : 'Belum Ada Kategori Layanan',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isFiltering
                    ? 'Tidak ada kategori yang cocok dengan pencarian atau filter yang dipilih.'
                    : 'Tambahkan kategori baru untuk mulai mengelompokkan layanan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (isFiltering)
                OutlinedButton.icon(
                  onPressed: () {
                    _searchC.clear();
                    setState(() => _filterAktif = null);
                    _fetchKategori();
                  },
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                  label: const Text('Reset Filter'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _openForm(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HCColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Kategori'),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchKategori,
      color: HCColor.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 80),
        itemCount: _kategoriList.length,
        itemBuilder: (_, i) => KategoriCard(
          item: _kategoriList[i],
          onToggle: (_) => _toggleKategori(_kategoriList[i]),
          onEdit: () => _openForm(item: _kategoriList[i]),
          onUpload: () => _pickAndUploadImage(_kategoriList[i]),
          onDelete: () => _deleteKategori(_kategoriList[i]),
          onDeleteImage: () => _hapusGambarKategori(_kategoriList[i]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        elevation: 0,
        title: const Text(
          'Kelola Kategori Layanan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_kategoriList.isNotEmpty)
            IconButton(
              tooltip: 'Atur Urutan Kategori',
              icon: const Icon(Icons.swap_vert_rounded),
              onPressed: _openReorderSheet,
            ),
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh),
            onPressed: _fetchKategori,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Kategori',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          KategoriFilterBar(
            searchController: _searchC,
            filterAktif: _filterAktif,
            onFilterChanged: (val) {
              setState(() => _filterAktif = val);
              _fetchKategori();
            },
            onSearchSubmitted: _fetchKategori,
            onClearSearch: () {
              _searchC.clear();
              _fetchKategori();
            },
            onRefresh: _fetchKategori,
            onReorder: _kategoriList.isNotEmpty ? _openReorderSheet : null,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

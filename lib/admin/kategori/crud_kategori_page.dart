import 'package:flutter/material.dart';
import 'package:home_care/admin/kategori/models/kategori_layanan_model.dart';
import 'package:home_care/admin/kategori/services/kategori_admin_service.dart';
import 'package:home_care/admin/kategori/widgets/kategori_card.dart';
import 'package:home_care/admin/kategori/widgets/kategori_filter_bar.dart';
import 'package:home_care/admin/kategori/widgets/kategori_form_dialog.dart';
import 'package:home_care/core/theme/app_colors.dart';
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
          _errorMessage = e.toString();
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
      _snack(item.aktif == true
          ? 'Kategori dinonaktifkan'
          : 'Kategori diaktifkan');
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
        title: const Text('Hapus Kategori',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            Text('Yakin ingin menghapus kategori "${item.namaKategori}"?'),
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
        title: const Text('Hapus Gambar',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Yakin ingin menghapus gambar kategori "${item.namaKategori}"?'),
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
        imageQuality: 80,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      await KategoriAdminService.uploadGambar(
        kategoriId: item.id!,
        imageBytes: bytes,
        fileName: picked.name,
      );
      _snack('Gambar kategori berhasil diupload');
      _fetchKategori();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
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
        await KategoriAdminService.createKategori(result.payload);
        _snack('Kategori berhasil dibuat');

        if (result.imageFile != null || result.imageBytes != null) {
          final list = await KategoriAdminService.fetchKategori();
          final slug = (result.payload['slug'] ?? '').toString();
          KategoriLayanan? created;
          for (final k in list) {
            if ((k.slug ?? '') == slug) {
              created = k;
              break;
            }
          }
          if (created?.id != null) {
            await KategoriAdminService.uploadGambar(
              kategoriId: created!.id!,
              imageFile: result.imageFile,
              imageBytes: result.imageBytes,
              fileName: result.imageName,
            );
          }
        }
      } else {
        await KategoriAdminService.updateKategori(item.id!, result.payload);
        _snack('Kategori berhasil diupdate');

        if (result.imageFile != null || result.imageBytes != null) {
          await KategoriAdminService.uploadGambar(
            kategoriId: item.id!,
            imageFile: result.imageFile,
            imageBytes: result.imageBytes,
            fileName: result.imageName,
          );
        }
      }
      _fetchKategori();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
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
          IconButton(
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
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: HCColor.primary))
                : _isError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _errorMessage ?? 'Terjadi kesalahan',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : _kategoriList.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada kategori layanan',
                              style: TextStyle(fontSize: 15),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchKategori,
                            color: HCColor.primary,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 6, bottom: 80),
                              itemCount: _kategoriList.length,
                              itemBuilder: (_, i) => KategoriCard(
                                item: _kategoriList[i],
                                onToggle: (_) =>
                                    _toggleKategori(_kategoriList[i]),
                                onEdit: () =>
                                    _openForm(item: _kategoriList[i]),
                                onUpload: () =>
                                    _pickAndUploadImage(_kategoriList[i]),
                                onDelete: () =>
                                    _deleteKategori(_kategoriList[i]),
                                onDeleteImage: () =>
                                    _hapusGambarKategori(_kategoriList[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

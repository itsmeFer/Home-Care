import 'package:flutter/material.dart';
import 'package:home_care/admin/detail_layanan.dart';
import 'package:home_care/admin/layanan/services/layanan_admin_service.dart';
import 'package:home_care/admin/layanan/widgets/layanan_card.dart';
import 'package:home_care/admin/layanan/widgets/layanan_form_dialog.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

class KelolaLayananPage extends StatefulWidget {
  const KelolaLayananPage({super.key});

  @override
  State<KelolaLayananPage> createState() => _KelolaLayananPageState();
}

class _KelolaLayananPageState extends State<KelolaLayananPage> {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  List<Layanan> _layananList = [];
  List<KategoriLayananItem> _kategoriList = [];
  bool _isLoadingKategori = false;

  @override
  void initState() {
    super.initState();
    _fetchKategori();
    _fetchLayanan();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
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
      setState(() => _isLoadingKategori = true);
      final list = await LayananAdminService.fetchKategori();
      if (mounted) {
        setState(() {
          _kategoriList = list;
        });
      }
    } catch (e) {
      _showSnack('Gagal mengambil kategori: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingKategori = false);
      }
    }
  }

  Future<void> _fetchLayanan() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final list = await LayananAdminService.fetchLayanan();
      if (mounted) {
        setState(() {
          _layananList = list;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createLayanan(Map<String, dynamic> payload) async {
    try {
      await LayananAdminService.createLayanan(payload);
      _showSnack('Layanan berhasil dibuat');
      await _fetchLayanan();
    } catch (e) {
      _showSnack('Gagal membuat layanan: $e', isError: true);
    }
  }

  Future<void> _updateLayanan(int id, Map<String, dynamic> payload) async {
    try {
      await LayananAdminService.updateLayanan(id, payload);
      _showSnack('Layanan berhasil diupdate');
      await _fetchLayanan();
    } catch (e) {
      _showSnack('Gagal mengupdate layanan: $e', isError: true);
    }
  }

  Future<void> _deleteLayanan(Layanan layanan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hapus Layanan'),
            content: Text(
              'Yakin ingin menghapus layanan "${layanan.namaLayanan}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await LayananAdminService.deleteLayanan(layanan.id);
      _showSnack('Layanan berhasil dihapus');
      if (mounted) {
        setState(() {
          _layananList.removeWhere((e) => e.id == layanan.id);
        });
      }
    } catch (e) {
      _showSnack('Gagal menghapus layanan: $e', isError: true);
    }
  }

  Future<void> _openForm({Layanan? layanan}) async {
    if (_isLoadingKategori) {
      _showSnack(
        'Kategori masih dimuat, coba sebentar lagi',
        isError: true,
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => LayananFormDialog(
            layanan: layanan,
            kategoriList: _kategoriList,
          ),
    );

    if (result == null) return;

    if (layanan == null) {
      await _createLayanan(result);
    } else {
      await _updateLayanan(layanan.id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        title: const Text(
          'Kelola Layanan Home Care',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () async {
              await _fetchKategori();
              await _fetchLayanan();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Layanan'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
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
              : _layananList.isEmpty
              ? const Center(child: Text('Belum ada layanan, tambahkan dulu.'))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _layananList.length,
                itemBuilder: (_, i) {
                  final l = _layananList[i];
                  return LayananCard(
                    layanan: l,
                    kategoriLabel: _kategoriLabel(l.kategori),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailLayananPage(layananId: l.id),
                        ),
                      );
                      await _fetchLayanan();
                    },
                    onToggleActive: (val) {
                      _updateLayanan(l.id, {'aktif': val});
                    },
                    onEdit: () => _openForm(layanan: l),
                    onDelete: () => _deleteLayanan(l),
                  );
                },
              ),
    );
  }
}

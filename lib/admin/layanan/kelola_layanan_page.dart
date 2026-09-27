import 'package:flutter/material.dart';
import 'package:home_care/admin/detail_layanan/detail_layanan_page.dart';
import 'package:home_care/admin/layanan/services/layanan_admin_service.dart';
import 'package:home_care/admin/layanan/widgets/layanan_card.dart';
import 'package:home_care/admin/layanan/widgets/layanan_filter_bar.dart';
import 'package:home_care/admin/layanan/widgets/layanan_form_dialog.dart';
import 'package:home_care/admin/layanan/widgets/layanan_skeleton.dart';
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

  final TextEditingController _searchC = TextEditingController();
  List<Layanan> _layananList = [];
  List<KategoriLayananItem> _kategoriList = [];
  bool _isLoadingKategori = false;

  String? _selectedKategori;
  bool? _selectedAktif;

  @override
  void initState() {
    super.initState();
    _fetchKategori();
    _fetchLayanan();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
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
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Layanan> get _filteredLayanan {
    return _layananList.where((l) {
      if (_selectedAktif != null && l.aktif != _selectedAktif) {
        return false;
      }
      if (_selectedKategori != null && _selectedKategori!.isNotEmpty) {
        if ((l.kategori ?? '') != _selectedKategori) {
          return false;
        }
      }
      if (_searchC.text.trim().isNotEmpty) {
        final query = _searchC.text.trim().toLowerCase();
        final matchNama = l.namaLayanan.toLowerCase().contains(query);
        final matchDesc = (l.deskripsi ?? '').toLowerCase().contains(query);
        final matchKode = l.kodeLayanan.toLowerCase().contains(query);
        if (!matchNama && !matchDesc && !matchKode) {
          return false;
        }
      }
      return true;
    }).toList();
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

  Future<void> _toggleActive(Layanan l, bool val) async {
    final oldState = l.aktif;
    setState(() {
      final index = _layananList.indexWhere((e) => e.id == l.id);
      if (index != -1) {
        _layananList[index] = _layananList[index].copyWith(aktif: val);
      }
    });

    try {
      await LayananAdminService.updateLayanan(l.id, {'aktif': val});
      _showSnack(val ? 'Layanan diaktifkan' : 'Layanan dinonaktifkan');
    } catch (e) {
      if (mounted) {
        setState(() {
          final index = _layananList.indexWhere((e) => e.id == l.id);
          if (index != -1) {
            _layananList[index] = _layananList[index].copyWith(aktif: oldState);
          }
        });
      }
      _showSnack('Gagal mengubah status: $e', isError: true);
    }
  }

  Future<void> _deleteLayanan(Layanan layanan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Layanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
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
      _showSnack('Kategori masih dimuat, tunggu sebentar...', isError: true);
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LayananFormDialog(
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

  Widget _buildBody() {
    if (_isLoading) {
      return const LayananListSkeleton();
    }

    if (_isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                'Gagal Memuat Layanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Terjadi kesalahan saat memuat data layanan',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await _fetchKategori();
                  await _fetchLayanan();
                },
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

    final list = _filteredLayanan;

    if (list.isEmpty) {
      final isFiltering = _searchC.text.trim().isNotEmpty ||
          _selectedKategori != null ||
          _selectedAktif != null;

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HCColor.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  size: 48,
                  color: HCColor.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isFiltering
                    ? 'Layanan Tidak Ditemukan'
                    : 'Belum Ada Layanan Tersedia',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isFiltering
                    ? 'Tidak ada layanan yang cocok dengan kata kunci atau filter yang dipilih.'
                    : 'Tekan tombol Tambah Layanan untuk membuat layanan kesehatan baru.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (isFiltering)
                OutlinedButton.icon(
                  onPressed: () {
                    _searchC.clear();
                    setState(() {
                      _selectedKategori = null;
                      _selectedAktif = null;
                    });
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
                  label: const Text('Tambah Layanan Baru'),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: HCColor.primary,
      onRefresh: () async {
        await _fetchKategori();
        await _fetchLayanan();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 80),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final l = list[i];
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
            onToggleActive: (val) => _toggleActive(l, val),
            onEdit: () => _openForm(layanan: l),
            onDelete: () => _deleteLayanan(l),
          );
        },
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
          'Kelola Layanan Home Care',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () async {
              await _fetchKategori();
              await _fetchLayanan();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Layanan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          LayananFilterBar(
            searchController: _searchC,
            kategoriList: _kategoriList,
            selectedKategori: _selectedKategori,
            selectedAktif: _selectedAktif,
            onSearchSubmitted: () => setState(() {}),
            onClearSearch: () {
              _searchC.clear();
              setState(() {});
            },
            onKategoriChanged: (val) {
              setState(() => _selectedKategori = val);
            },
            onAktifChanged: (val) {
              setState(() => _selectedAktif = val);
            },
            onRefresh: () async {
              await _fetchKategori();
              await _fetchLayanan();
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

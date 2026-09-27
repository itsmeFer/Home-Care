import 'package:flutter/material.dart';
import 'package:home_care/admin/kordinator/models/koordinator_admin_model.dart';
import 'package:home_care/admin/kordinator/services/koordinator_admin_service.dart';
import 'package:home_care/admin/kordinator/widgets/koordinator_card.dart';
import 'package:home_care/admin/kordinator/widgets/koordinator_filter_bar.dart';
import 'package:home_care/admin/kordinator/widgets/koordinator_form_dialog.dart';
import 'package:home_care/admin/kordinator/widgets/koordinator_skeleton.dart';
import 'package:home_care/core/theme/app_colors.dart';

class CrudKordinatorPage extends StatefulWidget {
  const CrudKordinatorPage({super.key});

  @override
  State<CrudKordinatorPage> createState() => _CrudKordinatorPageState();
}

class _CrudKordinatorPageState extends State<CrudKordinatorPage> {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  final TextEditingController _searchC = TextEditingController();
  List<Koordinator> _rawList = [];
  bool? _filterAktif;

  @override
  void initState() {
    super.initState();
    _fetchKoordinator();
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

  Future<void> _fetchKoordinator() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final list = await KoordinatorAdminService.fetchKoordinator(
        search: _searchC.text.trim(),
      );
      if (mounted) {
        setState(() {
          _rawList = list;
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

  List<Koordinator> get _filteredList {
    if (_filterAktif == null) return _rawList;
    return _rawList.where((k) => (k.isActive ?? true) == _filterAktif).toList();
  }

  Future<void> _createKoordinator(Map<String, dynamic> payload) async {
    try {
      await KoordinatorAdminService.createKoordinator(payload);
      _showSnack('Koordinator berhasil ditambahkan');
      await _fetchKoordinator();
    } catch (e) {
      _showSnack('Gagal menambah koordinator: $e', isError: true);
    }
  }

  Future<void> _updateKoordinator(int id, Map<String, dynamic> payload) async {
    try {
      await KoordinatorAdminService.updateKoordinator(id, payload);
      _showSnack('Koordinator berhasil diupdate');
      await _fetchKoordinator();
    } catch (e) {
      _showSnack('Gagal mengupdate koordinator: $e', isError: true);
    }
  }

  Future<void> _toggleActive(Koordinator k, bool val) async {
    if (k.id == null) return;
    final oldState = k.isActive;

    setState(() {
      final index = _rawList.indexWhere((e) => e.id == k.id);
      if (index != -1) {
        _rawList[index] = _rawList[index].copyWith(isActive: val);
      }
    });

    try {
      await KoordinatorAdminService.updateKoordinator(k.id!, {'is_active': val});
      _showSnack(val ? 'Koordinator diaktifkan' : 'Koordinator dinonaktifkan');
    } catch (e) {
      if (mounted) {
        setState(() {
          final index = _rawList.indexWhere((e) => e.id == k.id);
          if (index != -1) {
            _rawList[index] = _rawList[index].copyWith(isActive: oldState);
          }
        });
      }
      _showSnack('Gagal mengubah status: $e', isError: true);
    }
  }

  Future<void> _deleteKoordinator(Koordinator k) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Koordinator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Yakin ingin menghapus koordinator "${k.namaLengkap ?? '-'}"?',
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

    if (confirm != true || k.id == null) return;

    try {
      await KoordinatorAdminService.deleteKoordinator(k.id!);
      _showSnack('Koordinator berhasil dihapus');
      if (mounted) {
        setState(() {
          _rawList.removeWhere((e) => e.id == k.id);
        });
      }
    } catch (e) {
      _showSnack('Gagal menghapus koordinator: $e', isError: true);
    }
  }

  Future<void> _openForm({Koordinator? koordinator}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => KoordinatorFormDialog(koordinator: koordinator),
    );

    if (result == null) return;

    if (koordinator == null) {
      await _createKoordinator(result);
    } else if (koordinator.id != null) {
      await _updateKoordinator(koordinator.id!, result);
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const KoordinatorSkeleton();
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
                'Gagal Memuat Koordinator',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Terjadi kesalahan saat memuat data',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchKoordinator,
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

    final list = _filteredList;

    if (list.isEmpty) {
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
                  Icons.person_search_outlined,
                  size: 48,
                  color: HCColor.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isFiltering
                    ? 'Koordinator Tidak Ditemukan'
                    : 'Belum Ada Akun Koordinator',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isFiltering
                    ? 'Tidak ada koordinator yang cocok dengan kriteria pencarian.'
                    : 'Tambahkan koordinator untuk mengelola penugasan layanan medis.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (isFiltering)
                OutlinedButton.icon(
                  onPressed: () {
                    _searchC.clear();
                    setState(() => _filterAktif = null);
                    _fetchKoordinator();
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
                  label: const Text('Tambah Koordinator'),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchKoordinator,
      color: HCColor.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 80),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final k = list[i];
          return KoordinatorCard(
            koordinator: k,
            onToggleActive: (val) => _toggleActive(k, val),
            onEdit: () => _openForm(koordinator: k),
            onDelete: () => _deleteKoordinator(k),
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
          'Kelola Koordinator',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _fetchKoordinator,
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
          'Tambah Koordinator',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          KoordinatorFilterBar(
            searchController: _searchC,
            filterAktif: _filterAktif,
            onFilterChanged: (val) {
              setState(() => _filterAktif = val);
            },
            onSearchSubmitted: _fetchKoordinator,
            onClearSearch: () {
              _searchC.clear();
              _fetchKoordinator();
            },
            onRefresh: _fetchKoordinator,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/admin/kordinator/models/koordinator_admin_model.dart';
import 'package:home_care/admin/kordinator/services/koordinator_admin_service.dart';
import 'package:home_care/admin/kordinator/widgets/koordinator_card.dart';
import 'package:home_care/admin/kordinator/widgets/koordinator_form_dialog.dart';
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

  List<Koordinator> _list = [];

  @override
  void initState() {
    super.initState();
    _fetchKoordinator();
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

  Future<void> _fetchKoordinator() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final list = await KoordinatorAdminService.fetchKoordinator();
      if (mounted) {
        setState(() {
          _list = list;
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

  Future<void> _deleteKoordinator(Koordinator k) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hapus Koordinator'),
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
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
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
          _list.removeWhere((e) => e.id == k.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        title: const Text(
          'Kelola Koordinator',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _fetchKoordinator,
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
        label: const Text('Tambah Koordinator'),
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
              : _list.isEmpty
              ? const Center(
                child: Text('Belum ada koordinator, tambahkan dulu.'),
              )
              : RefreshIndicator(
                onRefresh: _fetchKoordinator,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _list.length,
                  itemBuilder: (_, i) {
                    final k = _list[i];
                    return KoordinatorCard(
                      koordinator: k,
                      onToggleActive: (val) {
                        if (k.id != null) {
                          _updateKoordinator(k.id!, {'is_active': val});
                        }
                      },
                      onEdit: () => _openForm(koordinator: k),
                      onDelete: () => _deleteKoordinator(k),
                    );
                  },
                ),
              ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/admin/perawat/models/perawat_admin_models.dart';
import 'package:home_care/admin/perawat/services/perawat_admin_service.dart';
import 'package:home_care/admin/perawat/widgets/assign_koordinator_dialog.dart';
import 'package:home_care/admin/perawat/widgets/perawat_card.dart';
import 'package:home_care/admin/perawat/widgets/perawat_filter_bar.dart';
import 'package:home_care/admin/perawat/widgets/perawat_form_dialog.dart';
import 'package:home_care/admin/perawat/widgets/perawat_kpi_bar.dart';
import 'package:home_care/admin/perawat/widgets/set_password_dialog.dart';
import 'package:home_care/admin/perawat/widgets/verifikasi_perawat_dialog.dart';
import 'package:home_care/core/theme/app_colors.dart';

class CrudPerawatPage extends StatefulWidget {
  const CrudPerawatPage({super.key});

  @override
  State<CrudPerawatPage> createState() => _CrudPerawatPageState();
}

class _CrudPerawatPageState extends State<CrudPerawatPage> {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  List<PerawatModel> _list = [];

  final TextEditingController _searchC = TextEditingController();
  String? _filterStatus;
  int? _filterActive;

  @override
  void initState() {
    super.initState();
    _fetchPerawat();
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

  Future<void> _fetchPerawat() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final items = await PerawatAdminService.fetchPerawat(
        search: _searchC.text.trim(),
        filterStatus: _filterStatus,
        filterActive: _filterActive,
      );
      if (mounted) setState(() => _list = items);
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

  Future<void> _savePerawat({PerawatModel? perawat}) async {
    try {
      PerawatDetailModel? detail;
      if (perawat != null) {
        detail = await PerawatAdminService.fetchPerawatDetail(perawat.id);
      }

      if (!mounted) return;

      final payload = await showDialog<PerawatFormResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PerawatFormDialog(
          perawat: detail?.perawat ?? perawat,
          koordinatorOptions: detail?.koordinatorOptions ?? const [],
        ),
      );

      if (payload == null) return;

      final targetId = await PerawatAdminService.savePerawat(
        body: payload.toPayloadWithoutKoordinator(),
        perawatId: perawat?.id,
      );

      if (targetId != 0) {
        await PerawatAdminService.assignKoordinatorDirect(
          perawatId: targetId,
          koordinatorId: payload.koordinatorId,
        );
      }

      _snack(perawat != null
          ? 'Perawat berhasil diupdate'
          : 'Perawat berhasil ditambahkan');
      _fetchPerawat();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _assignKoordinator(PerawatModel p) async {
    try {
      final detail = await PerawatAdminService.fetchPerawatDetail(p.id);
      if (!mounted) return;

      final selected = await showDialog<int?>(
        context: context,
        builder: (_) => AssignKoordinatorDialog(
          currentKoordinatorId: detail.perawat.koordinatorId,
          coordinators: detail.koordinatorOptions,
          perawatName: detail.perawat.namaLengkap,
        ),
      );

      if (!mounted) return;
      if (selected == null && detail.perawat.koordinatorId == null) return;

      await PerawatAdminService.assignKoordinatorDirect(
        perawatId: p.id,
        koordinatorId: selected,
      );

      _snack('Koordinator berhasil diassign');
      _fetchPerawat();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _deletePerawat(PerawatModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Perawat',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menghapus perawat "${p.namaLengkap}"?'),
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
      await PerawatAdminService.deletePerawat(p.id);
      _snack('Perawat berhasil dihapus');
      setState(() {
        _list.removeWhere((e) => e.id == p.id);
      });
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _setPassword(PerawatModel p) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SetPasswordDialog(),
    );

    if (password == null) return;

    try {
      final emailLogin = await PerawatAdminService.setPassword(
        perawatId: p.id,
        password: password,
      );

      _snack('Password berhasil di-set. Email login: $emailLogin');
      _fetchPerawat();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _verifikasi(PerawatModel p) async {
    final result = await showDialog<PerawatVerifyResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VerifikasiPerawatDialog(
        initial: p.statusVerifikasi,
        initialNote: p.catatanVerifikasi,
      ),
    );

    if (result == null) return;

    try {
      await PerawatAdminService.updateVerifikasi(
        perawatId: p.id,
        status: result.status,
        note: result.note,
      );

      _snack('Status verifikasi berhasil diupdate');
      _fetchPerawat();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _list.length;
    final verified =
        _list.where((x) => x.statusVerifikasi == 'verified').length;
    final pending = _list.where((x) => x.statusVerifikasi == 'pending').length;
    final rejected =
        _list.where((x) => x.statusVerifikasi == 'rejected').length;
    final active = _list.where((x) => x.isActive).length;

    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        elevation: 0,
        title: const Text(
          'Kelola Data Perawat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: _fetchPerawat, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        onPressed: () => _savePerawat(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Perawat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          PerawatKpiBar(
            total: total,
            active: active,
            pending: pending,
            verified: verified,
            rejected: rejected,
          ),
          PerawatFilterBar(
            searchController: _searchC,
            filterStatus: _filterStatus,
            filterActive: _filterActive,
            onStatusChanged: (v) {
              setState(() => _filterStatus = v);
              _fetchPerawat();
            },
            onActiveChanged: (v) {
              setState(() => _filterActive = v);
              _fetchPerawat();
            },
            onSearchSubmitted: _fetchPerawat,
            onClearSearch: () {
              setState(() => _searchC.clear());
              _fetchPerawat();
            },
            onApply: _fetchPerawat,
          ),
          Expanded(
            child: _isLoading
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
                    : _list.isEmpty
                        ? const Center(child: Text('Belum ada perawat.'))
                        : RefreshIndicator(
                            onRefresh: _fetchPerawat,
                            color: HCColor.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                              itemCount: _list.length,
                              itemBuilder: (_, i) {
                                final p = _list[i];
                                return PerawatCard(
                                  perawat: p,
                                  onEdit: () => _savePerawat(perawat: p),
                                  onAssignKoordinator: () =>
                                      _assignKoordinator(p),
                                  onSetPassword: () => _setPassword(p),
                                  onVerifikasi: () => _verifikasi(p),
                                  onDelete: () => _deletePerawat(p),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

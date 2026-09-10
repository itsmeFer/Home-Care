import 'package:flutter/material.dart';
import 'package:home_care/admin/role/models/role_admin_models.dart';
import 'package:home_care/admin/role/services/role_admin_service.dart';
import 'package:home_care/admin/role/widgets/assign_role_sheet.dart';
import 'package:home_care/admin/role/widgets/role_card.dart';
import 'package:home_care/admin/role/widgets/role_form_dialog.dart';
import 'package:home_care/core/theme/app_colors.dart';

class CrudRolePage extends StatefulWidget {
  const CrudRolePage({super.key});

  @override
  State<CrudRolePage> createState() => _CrudRolePageState();
}

class _CrudRolePageState extends State<CrudRolePage> {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  AssignFormData? _assignData;
  List<RoleModel> _list = [];

  @override
  void initState() {
    super.initState();
    _fetchRoles();
    _fetchAssignFormData();
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

  Future<void> _fetchRoles() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final list = await RoleAdminService.fetchRoles();
      if (mounted) setState(() => _list = list);
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

  Future<void> _fetchAssignFormData() async {
    try {
      final data = await RoleAdminService.fetchAssignFormData();
      if (mounted) setState(() => _assignData = data);
    } catch (_) {}
  }

  Future<void> _createRole(Map<String, dynamic> payload) async {
    try {
      await RoleAdminService.createRole(payload);
      _snack('Role berhasil ditambahkan');
      _fetchRoles();
      _fetchAssignFormData();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _updateRole(int id, Map<String, dynamic> payload) async {
    try {
      await RoleAdminService.updateRole(id, payload);
      _snack('Role berhasil diupdate');
      _fetchRoles();
      _fetchAssignFormData();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _deleteRole(RoleModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Role',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Yakin ingin menghapus role "${r.name}"?\n'
          'Role tidak bisa dihapus jika masih dipakai user.',
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
      await RoleAdminService.deleteRole(r.id);
      _snack('Role berhasil dihapus');
      setState(() {
        _list.removeWhere((e) => e.id == r.id);
      });
      _fetchAssignFormData();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _openForm({RoleModel? role}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RoleFormDialog(role: role),
    );

    if (result == null) return;

    if (role == null) {
      await _createRole(result);
    } else {
      await _updateRole(role.id, result);
    }
  }

  Future<void> _assignRoleToUser(int userId, int roleId) async {
    try {
      await RoleAdminService.assignRoleToUser(userId: userId, roleId: roleId);
      _snack('Role user berhasil di-set');
      await _fetchAssignFormData();
      await _fetchRoles();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _showAssignSheet(RoleModel role) async {
    if (_assignData == null) {
      await _fetchAssignFormData();
    }
    if (_assignData == null || !mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AssignRoleSheet(
        role: role,
        assignData: _assignData!,
        onAssign: _assignRoleToUser,
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
          'Kelola Role',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: _fetchRoles, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Role',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
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
              : _list.isEmpty
                  ? const Center(child: Text('Belum ada role, tambahkan dulu.'))
                  : RefreshIndicator(
                      onRefresh: _fetchRoles,
                      color: HCColor.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                        itemCount: _list.length,
                        itemBuilder: (_, i) {
                          final r = _list[i];
                          final assignedUsers = _assignData?.users
                                  .where((u) => u.roleId == r.id)
                                  .toList() ??
                              [];

                          return RoleCard(
                            role: r,
                            assignedUsers: assignedUsers,
                            onAssign: () => _showAssignSheet(r),
                            onEdit: () => _openForm(role: r),
                            onDelete: () => _deleteRole(r),
                          );
                        },
                      ),
                    ),
    );
  }
}

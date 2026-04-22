import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Biar bisa pakai HCColor dari HomePage
import 'package:home_care/users/HomePage.dart';

class CrudRolePage extends StatefulWidget {
  const CrudRolePage({super.key});

  @override
  State<CrudRolePage> createState() => _CrudRolePageState();
}

class _CrudRolePageState extends State<CrudRolePage> {
  static const String baseUrl = 'http://192.168.1.5:8000/api';

  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  // untuk assign
  bool _assignLoading = false;
  AssignFormData? _assignData;

  List<RoleModel> _list = [];

  @override
  void initState() {
    super.initState();
    _fetchRoles();
    _fetchAssignFormData(); // load list user + role di awal
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // =========================
  // HELPER: dapatkan nama role dari role_id
  // =========================
  String _getRoleNameById(int? roleId) {
    if (roleId == null || _assignData == null) return '-';
    for (final r in _assignData!.roles) {
      if (r.id == roleId) return r.name;
    }
    return '-';
  }

  // =========================
  // GET LIST ROLE
  // =========================
  Future<void> _fetchRoles() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _isError = true;
          _errorMessage = 'Token tidak ditemukan, silakan login ulang.';
        });
        return;
      }

      final url = Uri.parse('$baseUrl/admin/roles');
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        setState(() {
          _isError = true;
          _errorMessage =
              'Gagal mengambil data role (kode ${res.statusCode})';
        });
        return;
      }

      final body = json.decode(res.body);
      // dari controller: return ['data' => $roles]; // $roles = paginate
      if (body is Map && body['data'] != null) {
        final paginated = body['data'];
        if (paginated is Map && paginated['data'] != null) {
          final List<dynamic> data = paginated['data'];
          final list = data
              .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
              .toList();
          setState(() {
            _list = list;
          });
        } else {
          setState(() {
            _isError = true;
            _errorMessage = 'Format response tidak sesuai (paginate).';
          });
        }
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'Gagal mengambil data role dari server.';
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================
  // CREATE ROLE
  // =========================
  Future<void> _createRole(Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/admin/roles');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (res.statusCode != 201 && res.statusCode != 200) {
        String msg = 'Gagal menambah role (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map) {
            if (body['errors'] != null) {
              // gabung semua pesan error jadi satu string
              final errors = body['errors'] as Map<String, dynamic>;
              final buffer = StringBuffer();
              errors.forEach((key, value) {
                if (value is List && value.isNotEmpty) {
                  buffer.writeln('$key: ${value.first}');
                }
              });
              if (buffer.isNotEmpty) {
                msg = buffer.toString();
              }
            } else if (body['message'] != null) {
              msg = body['message'];
            }
          }
        } catch (_) {}
        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchRoles();
      await _fetchAssignFormData(); // refresh mapping user-role
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambah role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // UPDATE ROLE
  // =========================
  Future<void> _updateRole(int id, Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/admin/roles/$id');
      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (res.statusCode != 200) {
        String msg = 'Gagal mengupdate role (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchRoles();
      await _fetchAssignFormData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupdate role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // DELETE ROLE
  // =========================
  Future<void> _deleteRole(RoleModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Role'),
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
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/admin/roles/${r.id}');
      final res = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        String msg = 'Gagal menghapus role (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _list.removeWhere((e) => e.id == r.id);
      });

      await _fetchAssignFormData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openForm({RoleModel? role}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RoleFormDialog(role: role),
    );

    if (result == null) return;

    if (role == null) {
      await _createRole(result);
    } else {
      await _updateRole(role.id, result);
    }
  }

  // =========================
  // ASSIGN ROLE → USER
  // =========================

  Future<void> _fetchAssignFormData() async {
    setState(() {
      _assignLoading = true;
    });

    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/admin/roles/assign-form-data');
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        String msg =
            'Gagal mengambil data user & role (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        throw msg;
      }

      final decoded = json.decode(res.body);
      if (decoded is! Map) throw 'Format response tidak sesuai.';

      final Map<String, dynamic> body = Map<String, dynamic>.from(
        decoded as Map,
      );

      setState(() {
        _assignData = AssignFormData.fromJson(body);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal load data assign: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _assignLoading = false);
      }
    }
  }

  Future<void> _assignRoleToUser(int userId, int roleId) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/admin/roles/assign');
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'user_id': userId, 'role_id': roleId}),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        String msg = 'Gagal meng-assign role (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role user berhasil di-set'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchAssignFormData();
      await _fetchRoles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal meng-assign role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showAssignSheet(RoleModel role) async {
    // kalau belum ada data, fetch dulu
    if (_assignData == null) {
      await _fetchAssignFormData();
    }
    if (_assignData == null) return;

    UserSummary? selectedUser;
    String searchQuery = '';
    List<UserSummary> filteredUsers =
        List<UserSummary>.from(_assignData!.users);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.7;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                      maxWidth: 700, // biar rapi di tablet/web juga
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Role: ${role.name}',
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pilih user, role sekarangnya akan diganti menjadi: ${role.name}',
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),

                          if (_assignLoading)
                            const Expanded(
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else ...[
                            // FIELD SEARCH
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Cari user (nama / email)',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setModalState(() {
                                            searchQuery = '';
                                            filteredUsers =
                                                List<UserSummary>.from(
                                                    _assignData!.users);
                                            selectedUser = null;
                                          });
                                        },
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (v) {
                                setModalState(() {
                                  searchQuery = v;
                                  final lower = v.toLowerCase();
                                  filteredUsers = _assignData!.users.where((u) {
                                    return u.name
                                            .toLowerCase()
                                            .contains(lower) ||
                                        u.email
                                            .toLowerCase()
                                            .contains(lower);
                                  }).toList();
                                });
                              },
                            ),
                            const SizedBox(height: 12),

                            // LIST USER DI DALAM SHEET (BUKAN DROPDOWN)
                            Expanded(
                              child: filteredUsers.isEmpty
                                  ? const Center(
                                      child: Text('User tidak ditemukan'),
                                    )
                                  : ListView.separated(
                                      itemCount: filteredUsers.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (_, index) {
                                        final u = filteredUsers[index];
                                        final currentRoleName =
                                            _getRoleNameById(u.roleId);
                                        final isSameRole = u.roleId == role.id;
                                        final isSelected =
                                            selectedUser?.id == u.id;

                                        return InkWell(
                                          onTap: () {
                                            setModalState(() {
                                              selectedUser = u;
                                            });
                                          },
                                          child: Container(
                                            color: isSelected
                                                ? HCColor.primary
                                                    .withOpacity(0.06)
                                                : null,
                                            padding:
                                                const EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 4,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        u.name,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isSelected)
                                                      const Icon(
                                                        Icons.check_circle,
                                                        size: 18,
                                                      ),
                                                  ],
                                                ),
                                                Text(
                                                  u.email,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Role sekarang: $currentRoleName',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isSameRole
                                                        ? Colors.green
                                                        : Colors
                                                            .grey.shade700,
                                                    fontStyle:
                                                        FontStyle.italic,
                                                  ),
                                                ),
                                                Text(
                                                  'Akan di-set menjadi: ${role.name}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        HCColor.primaryDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],

                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Simpan'),
                              onPressed: () async {
                                if (selectedUser == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Pilih user terlebih dahulu'),
                                    ),
                                  );
                                  return;
                                }

                                await _assignRoleToUser(
                                    selectedUser!.id, role.id);
                                if (context.mounted) {
                                  Navigator.of(ctx).pop();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        title:
            const Text('Kelola Role', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: _fetchRoles, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Role'),
      ),
      body: _isLoading
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
                  ? const Center(child: Text('Belum ada role, tambahkan dulu.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _list.length,
                      itemBuilder: (_, i) {
                        final r = _list[i];

                        // user yang punya role ini
                        final List<UserSummary> assignedUsers =
                            _assignData?.users
                                    .where((u) => u.roleId == r.id)
                                    .toList() ??
                                [];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      HCColor.primary.withOpacity(.1),
                                  child: Text(
                                    r.inisial,
                                    style: TextStyle(
                                      color: HCColor.primaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              r.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          if (r.isDefault)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'Default',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Slug: ${r.slug}',
                                        style:
                                            const TextStyle(fontSize: 12),
                                      ),
                                      if (r.description != null &&
                                          r.description!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          r.description!,
                                          style: const TextStyle(
                                              fontSize: 12),
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        'Dipakai user: ${r.usersCount}',
                                        style:
                                            const TextStyle(fontSize: 12),
                                      ),
                                      if (_assignData != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          assignedUsers.isEmpty
                                              ? 'User: -'
                                              : 'User: ${assignedUsers.map((u) => u.name).join(', ')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Assign ke user',
                                          icon: const Icon(Icons.person_add),
                                          onPressed: () =>
                                              _showAssignSheet(r),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              size: 20),
                                          onPressed: () =>
                                              _openForm(role: r),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => _deleteRole(r),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

// =======================
// MODEL ROLE
// =======================

class RoleModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final bool isDefault;
  final int usersCount;

  RoleModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.isDefault,
    required this.usersCount,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      isDefault: (json['is_default'] ?? 0) == 1,
      usersCount: (json['users_count'] ?? 0) as int,
    );
  }

  String get inisial {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// =======================
// MODEL UNTUK ASSIGN
// =======================

class AssignFormData {
  final List<RoleModel> roles;
  final List<UserSummary> users;

  AssignFormData({required this.roles, required this.users});

  factory AssignFormData.fromJson(Map<String, dynamic> json) {
    final rolesJson = (json['roles'] ?? []) as List<dynamic>;
    final usersJson = (json['users'] ?? []) as List<dynamic>;

    return AssignFormData(
      roles: rolesJson
          .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      users: usersJson
          .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserSummary {
  final int id;
  final String name;
  final String email;
  final int? roleId;

  UserSummary({
    required this.id,
    required this.name,
    required this.email,
    this.roleId,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roleId: json['role_id'] as int?,
    );
  }
}

// =======================
// FORM DIALOG ROLE
// =======================

class _RoleFormDialog extends StatefulWidget {
  final RoleModel? role;

  const _RoleFormDialog({this.role});

  @override
  State<_RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends State<_RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameC;
  late TextEditingController _slugC;
  late TextEditingController _descC;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final r = widget.role;
    _nameC = TextEditingController(text: r?.name ?? '');
    _slugC = TextEditingController(text: r?.slug ?? '');
    _descC = TextEditingController(text: r?.description ?? '');
    _isDefault = r?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _slugC.dispose();
    _descC.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameC.text.trim();
    final slugText = _slugC.text.trim();
    final descText = _descC.text.trim();

    final payload = <String, dynamic>{
      'name': name,
      'slug': slugText.isEmpty ? null : slugText,
      'description': descText.isEmpty ? null : descText,
      'is_default': _isDefault,
    };

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.role != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Role' : 'Tambah Role'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Role',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama role wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _slugC,
                  decoration: const InputDecoration(
                    labelText:
                        'Slug (boleh kosong, auto dari nama di backend)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descC,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _isDefault,
                  title: const Text('Jadikan default untuk user baru'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() => _isDefault = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: HCColor.primary),
          child: Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

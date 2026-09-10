import 'package:flutter/material.dart';
import 'package:home_care/admin/role/models/role_admin_models.dart';
import 'package:home_care/core/theme/app_colors.dart';

class AssignRoleSheet extends StatefulWidget {
  final RoleModel role;
  final AssignFormData assignData;
  final Future<void> Function(int userId, int roleId) onAssign;

  const AssignRoleSheet({
    super.key,
    required this.role,
    required this.assignData,
    required this.onAssign,
  });

  @override
  State<AssignRoleSheet> createState() => _AssignRoleSheetState();
}

class _AssignRoleSheetState extends State<AssignRoleSheet> {
  final TextEditingController _searchC = TextEditingController();
  UserSummary? _selectedUser;
  late List<UserSummary> _filteredUsers;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _filteredUsers = List<UserSummary>.from(widget.assignData.users);
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  String _getRoleNameById(int? roleId) {
    if (roleId == null) return '-';
    for (final r in widget.assignData.roles) {
      if (r.id == roleId) return r.name;
    }
    return '-';
  }

  void _filterUsers(String query) {
    final lower = query.toLowerCase().trim();
    setState(() {
      if (lower.isEmpty) {
        _filteredUsers = List<UserSummary>.from(widget.assignData.users);
      } else {
        _filteredUsers = widget.assignData.users.where((u) {
          return u.name.toLowerCase().contains(lower) ||
              u.email.toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih user terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onAssign(_selectedUser!.id, widget.role.id);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: maxHeight,
              maxWidth: 700,
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Role: ${widget.role.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih user, role sekarangnya akan diganti menjadi: ${widget.role.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchC,
                    decoration: InputDecoration(
                      labelText: 'Cari user (nama / email)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchC.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchC.clear();
                                _filterUsers('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: _filterUsers,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _filteredUsers.isEmpty
                        ? const Center(child: Text('User tidak ditemukan'))
                        : ListView.separated(
                            itemCount: _filteredUsers.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final u = _filteredUsers[index];
                              final currentRoleName =
                                  _getRoleNameById(u.roleId);
                              final isSameRole = u.roleId == widget.role.id;
                              final isSelected = _selectedUser?.id == u.id;

                              return InkWell(
                                onTap: () =>
                                    setState(() => _selectedUser = u),
                                child: Container(
                                  color: isSelected
                                      ? HCColor.primary.withValues(alpha: 0.08)
                                      : null,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
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
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: HCColor.primary,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                      Text(
                                        u.email,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Role sekarang: $currentRoleName',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSameRole
                                              ? Colors.green
                                              : Colors.grey.shade700,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                      Text(
                                        'Akan di-set menjadi: ${widget.role.name}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: HCColor.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HCColor.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

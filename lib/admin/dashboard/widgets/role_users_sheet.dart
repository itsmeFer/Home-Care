import 'package:flutter/material.dart';
import 'package:home_care/admin/dashboard/models/admin_dashboard_models.dart';
import 'package:home_care/admin/dashboard/services/admin_dashboard_service.dart';
import 'package:home_care/admin/dashboard/widgets/user_detail_dialog.dart';
import 'package:home_care/admin/dashboard/widgets/user_detail_widgets.dart';

class RoleUsersSheet extends StatefulWidget {
  final String roleSlug;
  final String roleName;

  const RoleUsersSheet({
    super.key,
    required this.roleSlug,
    required this.roleName,
  });

  static Future<void> show(
    BuildContext context, {
    required String roleSlug,
    required String roleName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F8FB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RoleUsersSheet(
        roleSlug: roleSlug,
        roleName: roleName,
      ),
    );
  }

  @override
  State<RoleUsersSheet> createState() => _RoleUsersSheetState();
}

class _RoleUsersSheetState extends State<RoleUsersSheet> {
  final TextEditingController _searchC = TextEditingController();
  List<AdminUserItem> _allUsers = [];
  List<AdminUserItem> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchC.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await AdminDashboardService.fetchUsersByRole(widget.roleSlug);
      if (mounted) {
        setState(() {
          _allUsers = list;
          _filteredUsers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchC.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredUsers = _allUsers);
    } else {
      setState(() {
        _filteredUsers = _allUsers.where((u) {
          final nameMatch = u.name.toLowerCase().contains(query);
          final emailMatch = u.email.toLowerCase().contains(query);
          return nameMatch || emailMatch;
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Daftar ${widget.roleName} (${_allUsers.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchC,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau email pengguna...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchC.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchC.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildBody(scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.redAccent, size: 40),
              const SizedBox(height: 10),
              Text(
                'Gagal memuat daftar ${widget.roleName}\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_allUsers.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data user untuk role ini.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada user yang cocok dengan pencarian.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    final roleColor = AdminRoleStyle.color(widget.roleSlug);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                UserDetailDialog.show(context, user.id);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE9EEF5)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: roleColor.withValues(alpha: 0.12),
                      child: Text(
                        user.name.trim().isNotEmpty
                            ? user.name.trim()[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user.roleName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              UserMiniChip(
                                label: user.isActive ? 'Aktif' : 'Tidak Aktif',
                                bg: user.isActive
                                    ? const Color(0xFFE8FFF1)
                                    : const Color(0xFFF3F4F6),
                                fg: user.isActive
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF6B7280),
                              ),
                              UserMiniChip(
                                label: user.isFrozen ? 'Frozen' : 'Normal',
                                bg: user.isFrozen
                                    ? const Color(0xFFFFEAEA)
                                    : const Color(0xFFEFF6FF),
                                fg: user.isFrozen
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF2563EB),
                              ),
                              UserMiniChip(
                                label: user.isVerified ? 'Verified' : 'Belum Verify',
                                bg: user.isVerified
                                    ? const Color(0xFFEEFDF3)
                                    : const Color(0xFFFFF7ED),
                                fg: user.isVerified
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFEA580C),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// lib/it/pages/user_monitor_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================
// USER MONITOR PAGE (FULL) — FIXED (ANTI setState async)
// - Semua UI components (SectionHeader, XCard, OutlineButtonX) disertakan
// - OutlineButtonX aman untuk onTap async (tidak pernah setState(() async {}))
// =============================================================
class UserMonitorPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const UserMonitorPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<UserMonitorPage> createState() => _UserMonitorPageState();
}

class _UserMonitorPageState extends State<UserMonitorPage> {
  static const String kBaseUrl = 'http://192.168.1.5:8000';
  String get kApiBase => '$kBaseUrl/api';

  // =========================
  // Query state
  // =========================
  final _qC = TextEditingController();
  Timer? _debounce;

  String _q = '';
  int _perPage = 20;
  int _page = 1;

  // Filters
  int? _roleId;
  bool? _isActive;
  bool? _isFrozen;

  Future<Map<String, dynamic>>? _future;
  Future<List<Map<String, dynamic>>>? _rolesFuture;

  @override
  void initState() {
    super.initState();
    _qC.addListener(_onRealtimeChanged);
    _rolesFuture = _fetchRoles();
    _future = _fetchUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qC.removeListener(_onRealtimeChanged);
    _qC.dispose();
    super.dispose();
  }

  void _onRealtimeChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final nextQ = _qC.text.trim();
      if (nextQ == _q) return;
      _q = nextQ;
      _page = 1;
      _reloadUsers();
    });
  }

  void _reloadUsers({bool resetPage = false}) {
    if (resetPage) _page = 1;
    if (!mounted) return;
    setState(() {
      _future = _fetchUsers();
    });
  }

  void _reloadRoles() {
    if (!mounted) return;
    setState(() {
      _rolesFuture = _fetchRoles();
    });
  }

  // =========================
  // Formatting helpers
  // =========================
  String formatWaktuID(String iso) {
    try {
      final dt = DateTime.tryParse(iso)?.toLocal();
      if (dt == null) return iso;
      return DateFormat("dd MMMM yyyy • HH:mm", 'id_ID').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _s(dynamic v, [String fb = '-']) {
    if (v == null) return fb;
    final t = v.toString().trim();
    return t.isEmpty ? fb : t;
  }

  int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  bool _b(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  Color _roleColor(String slug) {
    final s = slug.toLowerCase();
    if (s == 'direktur') return const Color(0xFF2563EB);
    if (s == 'it' ||
        s == 'itdev' ||
        s == 'it-developer' ||
        s == 'it_developer') {
      return const Color(0xFF0EA5E9);
    }
    if (s == 'admin') return const Color(0xFF8B5CF6);
    if (s == 'koordinator') return const Color(0xFFF59E0B);
    if (s == 'perawat') return const Color(0xFF10B981);
    if (s == 'dokter') return const Color(0xFF14B8A6);
    if (s == 'pasien') return const Color(0xFF334155);
    return const Color(0xFF334155);
  }

  // =========================
  // API helpers
  // =========================
  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        (prefs.getString('auth_token') ?? prefs.getString('token') ?? '').trim();
    if (token.isEmpty) throw Exception('Token kosong. Silakan login ulang.');
    return token;
  }

  Future<Map<String, dynamic>> _api(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final token = await _token();

    final uri = Uri.parse('$kApiBase$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    http.Response res;

    if (method == 'GET') {
      res = await http.get(uri, headers: headers);
    } else if (method == 'POST') {
      headers['Content-Type'] = 'application/json';
      res = await http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
    } else if (method == 'PUT') {
      headers['Content-Type'] = 'application/json';
      res = await http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
    } else if (method == 'PATCH') {
      headers['Content-Type'] = 'application/json';
      res =
          await http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
    } else if (method == 'DELETE') {
      res = await http.delete(uri, headers: headers);
    } else {
      throw Exception('HTTP method tidak dikenal: $method');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw Exception('Response bukan object JSON.');
  }

  // =========================
  // ENDPOINTS
  // =========================
  Future<List<Map<String, dynamic>>> _fetchRoles() async {
    final map = await _api('GET', '/it/roles');
    final data = map['data'];
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> _fetchUsers() async {
    final qp = <String, String>{
      'per_page': '$_perPage',
      'page': '$_page',
    };

    if (_q.trim().isNotEmpty) qp['q'] = _q.trim();
    if (_roleId != null) qp['role_id'] = '$_roleId';
    if (_isActive != null) qp['is_active'] = _isActive! ? '1' : '0';
    if (_isFrozen != null) qp['is_frozen'] = _isFrozen! ? '1' : '0';

    final map = await _api('GET', '/it/users-crud', query: qp);

    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }
    return map;
  }

  // =========================
  // ACTIONS
  // =========================
  Future<void> _createUser() async {
    final roles = await (_rolesFuture ?? _fetchRoles());
    if (!mounted) return;

    final result = await showDialog<_UserFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserFormDialog(
        title: 'Tambah Akun',
        roles: roles,
        initial: null,
        isCreate: true,
      ),
    );

    if (result == null) return;

    await _runAction(
      label: 'Membuat user…',
      action: () => _api(
        'POST',
        '/it/users-crud',
        body: {
          'name': result.name,
          'email': result.email,
          'password': result.password ?? '',
          'role_id': result.roleId,
          'is_active': result.isActive,
        },
      ),
      onSuccess: () {
        _reloadUsers(resetPage: true);
        _toast('User berhasil dibuat ✅');
      },
    );
  }

  Future<void> _editUser(Map u) async {
    final roles = await (_rolesFuture ?? _fetchRoles());
    if (!mounted) return;

    final initial = _UserFormResult(
      name: _s(u['name'], ''),
      email: _s(u['email'], ''),
      roleId: (u['role_id'] is int) ? (u['role_id'] as int) : _i(u['role_id']),
      isActive: _b(u['is_active']),
      password: null,
    );

    final result = await showDialog<_UserFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserFormDialog(
        title: 'Edit Akun',
        roles: roles,
        initial: initial,
        isCreate: false,
      ),
    );

    if (result == null) return;

    await _runAction(
      label: 'Menyimpan perubahan…',
      action: () => _api(
        'PUT',
        '/it/users-crud/${_i(u['id'])}',
        body: {
          'name': result.name,
          'email': result.email,
          'role_id': result.roleId,
          'is_active': result.isActive,
        },
      ),
      onSuccess: () {
        _reloadUsers();
        _toast('User berhasil diupdate ✅');
      },
    );
  }

  Future<void> _deleteUser(Map u) async {
    final ok = await _confirm(
      title: 'Hapus Akun?',
      message:
          'Akun ini akan dihapus permanen.\n\nEmail: ${_s(u['email'])}\nID: ${_i(u['id'])}',
      danger: true,
      okText: 'Hapus',
    );
    if (ok != true) return;

    await _runAction(
      label: 'Menghapus user…',
      action: () => _api('DELETE', '/it/users-crud/${_i(u['id'])}'),
      onSuccess: () {
        _reloadUsers(resetPage: true);
        _toast('User berhasil dihapus ✅');
      },
    );
  }

  Future<void> _toggleActive(Map u) async {
    final current = _b(u['is_active']);
    final next = !current;

    await _runAction(
      label: next ? 'Mengaktifkan…' : 'Menonaktifkan…',
      action: () => _api(
        'PATCH',
        '/it/users-crud/${_i(u['id'])}/active',
        body: {'is_active': next},
      ),
      onSuccess: () {
        _reloadUsers();
        _toast(next ? 'User diaktifkan ✅' : 'User dinonaktifkan ✅');
      },
    );
  }

  Future<void> _freeze(Map u) async {
    final reason = await _promptText(
      title: 'Freeze Akun (Emergency)',
      hint: 'Alasan freeze (opsional)',
      initial: '',
      okText: 'Freeze',
      danger: true,
    );
    if (reason == null) return;

    await _runAction(
      label: 'Membekukan akun…',
      action: () => _api(
        'PATCH',
        '/it/users-crud/${_i(u['id'])}/freeze',
        body: {'reason': reason},
      ),
      onSuccess: () {
        _reloadUsers();
        _toast('Akun di-freeze ✅');
      },
    );
  }

  Future<void> _unfreeze(Map u) async {
    final ok = await _confirm(
      title: 'Unfreeze Akun?',
      message: 'Akun akan dibuka kembali dari status freeze.',
      okText: 'Unfreeze',
    );
    if (ok != true) return;

    await _runAction(
      label: 'Membuka freeze…',
      action: () => _api('PATCH', '/it/users-crud/${_i(u['id'])}/unfreeze'),
      onSuccess: () {
        _reloadUsers();
        _toast('Akun di-unfreeze ✅');
      },
    );
  }

  Future<void> _forceLogout(Map u) async {
    final ok = await _confirm(
      title: 'Force Logout?',
      message:
          'User akan dipaksa logout di semua device (force_logout_at di-update).',
      okText: 'Force Logout',
      danger: true,
    );
    if (ok != true) return;

    await _runAction(
      label: 'Force logout…',
      action: () => _api('POST', '/it/users-crud/${_i(u['id'])}/force-logout'),
      onSuccess: () {
        _reloadUsers();
        _toast('Force logout berhasil ✅');
      },
    );
  }

  Future<void> _resetPassword(Map u) async {
    final pass = await _promptText(
      title: 'Reset Password',
      hint: 'Masukkan password baru (min 6)',
      initial: '',
      okText: 'Reset',
      obscure: true,
      danger: true,
    );
    if (pass == null) return;

    if (pass.trim().length < 6) {
      _toast('Password minimal 6 karakter.');
      return;
    }

    await _runAction(
      label: 'Reset password…',
      action: () => _api(
        'PUT',
        '/it/users-crud/${_i(u['id'])}/reset-password',
        body: {'new_password': pass.trim()},
      ),
      onSuccess: () {
        _reloadUsers();
        _toast('Password berhasil direset ✅');
      },
    );
  }

  // =========================
  // UX helpers
  // =========================
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _runAction({
    required String label,
    required Future<Map<String, dynamic>> Function() action,
    required VoidCallback onSuccess,
  }) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BusyDialog(label: label),
    );

    try {
      final res = await action();
      if (res.containsKey('success') && res['success'] == false) {
        throw Exception(_s(res['message'], 'Gagal'));
      }
      if (mounted) Navigator.of(context).pop();
      onSuccess();
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _toast('Gagal: $e');
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    String okText = 'Ya',
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: danger ? const Color(0xFFDC2626) : null,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(okText),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
    required String initial,
    String okText = 'OK',
    bool obscure = false,
    bool danger = false,
  }) async {
    final c = TextEditingController(text: initial);
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: TextField(
          controller: c,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: danger ? const Color(0xFFDC2626) : null,
            ),
            onPressed: () => Navigator.of(context).pop(c.text),
            child: Text(okText),
          ),
        ],
      ),
    );
    c.dispose();
    return res;
  }

  // =========================
  // UI (RESPONSIVE + FIX UNBOUNDED WIDTH ✅)
  // =========================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final mqW = MediaQuery.sizeOf(context).width;
        final w = (c.maxWidth.isFinite && c.maxWidth > 0) ? c.maxWidth : mqW;

        final isWide = w >= 980; // desktop table
        final isCompact = w < 720; // mobile

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'User Monitor',
              subtitle: 'IT Security & Support',
            ),
            const SizedBox(height: 12),

            // =========================
            // Search & Filters
            // =========================
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _rolesFuture,
              builder: (context, roleSnap) {
                final roles = roleSnap.data ?? const <Map<String, dynamic>>[];

                return XCard(
                  title: 'Search & Filter',
                  subtitle: 'Nama/email + filter role/aktif/freeze (server-side).',
                  child: Column(
                    children: [
                      if (isCompact) ...[
                        TextField(
                          controller: _qC,
                          decoration: InputDecoration(
                            hintText: 'Cari user (nama / email)…',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlineButtonX(
                              icon: Icons.search_rounded,
                              label: 'Cari',
                              onTap: () async {
                                _debounce?.cancel();
                                _q = _qC.text.trim();
                                _reloadUsers(resetPage: true);
                              },
                            ),
                            OutlineButtonX(
                              icon: Icons.clear_rounded,
                              label: 'Reset',
                              onTap: () async {
                                _debounce?.cancel();
                                _qC.text = '';
                                _q = '';
                                _roleId = null;
                                _isActive = null;
                                _isFrozen = null;
                                _reloadUsers(resetPage: true);
                              },
                            ),
                            OutlineButtonX(
                              icon: Icons.person_add_alt_1_rounded,
                              label: 'Tambah',
                              onTap: () async => _createUser(),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _qC,
                                decoration: InputDecoration(
                                  hintText: 'Cari user (nama / email)…',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlineButtonX(
                              icon: Icons.search_rounded,
                              label: 'Cari',
                              onTap: () async {
                                _debounce?.cancel();
                                _q = _qC.text.trim();
                                _reloadUsers(resetPage: true);
                              },
                            ),
                            const SizedBox(width: 10),
                            OutlineButtonX(
                              icon: Icons.clear_rounded,
                              label: 'Reset',
                              onTap: () async {
                                _debounce?.cancel();
                                _qC.text = '';
                                _q = '';
                                _roleId = null;
                                _isActive = null;
                                _isFrozen = null;
                                _reloadUsers(resetPage: true);
                              },
                            ),
                            const SizedBox(width: 10),
                            OutlineButtonX(
                              icon: Icons.person_add_alt_1_rounded,
                              label: 'Tambah Akun',
                              onTap: () async => _createUser(),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _FilterChipX(
                            label: _isActive == null
                                ? "Aktif: All"
                                : (_isActive! ? "Aktif: Ya" : "Aktif: Tidak"),
                            icon: Icons.toggle_on_rounded,
                            onTap: () async {
                              final next = await _pickTriState(
                                title: 'Filter Aktif',
                                current: _isActive,
                              );
                              if (next == null && _isActive == null) return;
                              _isActive = next;
                              _reloadUsers(resetPage: true);
                            },
                          ),
                          _FilterChipX(
                            label: _isFrozen == null
                                ? "Frozen: All"
                                : (_isFrozen! ? "Frozen: Ya" : "Frozen: Tidak"),
                            icon: Icons.lock_rounded,
                            onTap: () async {
                              final next = await _pickTriState(
                                title: 'Filter Frozen',
                                current: _isFrozen,
                              );
                              if (next == null && _isFrozen == null) return;
                              _isFrozen = next;
                              _reloadUsers(resetPage: true);
                            },
                          ),
                          _FilterChipX(
                            label: _roleId == null
                                ? 'Role: All'
                                : 'Role: ${_roleNameById(roles, _roleId!)}',
                            icon: Icons.badge_rounded,
                            onTap: () async {
                              final picked = await _pickRole(roles, _roleId);
                              if (picked == _roleId) return;
                              _roleId = picked;
                              _reloadUsers(resetPage: true);
                            },
                          ),
                          if (!isCompact) ...[
                            OutlineButtonX(
                              icon: Icons.refresh_rounded,
                              label: 'Refresh',
                              onTap: () async => _reloadUsers(),
                            ),
                            OutlineButtonX(
                              icon: Icons.sync_rounded,
                              label: 'Reload Roles',
                              onTap: () async {
                                _reloadRoles();
                                _toast('Roles di-refresh ✅');
                              },
                            ),
                          ],
                        ],
                      ),

                      if (roleSnap.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _warnBar('Gagal load roles: ${roleSnap.error}'),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // =========================
            // Users list
            // =========================
            FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snap) {
                final loading =
                    snap.connectionState != ConnectionState.done;
                final error = snap.hasError;

                final data = snap.data ?? {};
                final List rows = (data['data'] is List)
                    ? (data['data'] as List)
                    : const [];

                final currentPage = _i(data['current_page']);
                final lastPage = _i(data['last_page']);
                final total = _i(data['total']);

                final safeCurrent = currentPage == 0 ? _page : currentPage;
                final safeLast = lastPage == 0 ? 1 : lastPage;

                if (loading && snap.data == null) {
                  return const _LoadingCardX(title: 'Users');
                }

                if (error && snap.data == null) {
                  return _ErrorCardX(
                    title: 'Users',
                    message: snap.error.toString(),
                    onRetry: () => _reloadUsers(),
                  );
                }

                Widget listBody;

                if (rows.isEmpty) {
                  listBody =
                      const _EmptyState(text: 'Tidak ada user untuk filter ini.');
                } else {
                  final content = Column(
                    children: [
                      if (isWide) const _HeaderRow(),
                      for (final e in rows)
                        _UserRowCrud(
                          isWide: isWide,
                          isCompact: isCompact,
                          user: Map<String, dynamic>.from(e as Map),
                          roleColor: _roleColor(_userRoleSlug(e)),
                          roleLabel: _userRoleName(e),
                          frozen: _b((e as Map)['is_frozen']),
                          active: _b((e as Map)['is_active']),
                          onEdit: () => _editUser(Map<String, dynamic>.from(e)),
                          onDelete: () => _deleteUser(Map<String, dynamic>.from(e)),
                          onToggleActive: () =>
                              _toggleActive(Map<String, dynamic>.from(e)),
                          onFreeze: () => _freeze(Map<String, dynamic>.from(e)),
                          onUnfreeze: () =>
                              _unfreeze(Map<String, dynamic>.from(e)),
                          onResetPassword: () =>
                              _resetPassword(Map<String, dynamic>.from(e)),
                          onForceLogout: () =>
                              _forceLogout(Map<String, dynamic>.from(e)),
                          formatTime: formatWaktuID,
                          s: _s,
                        ),
                    ],
                  );

                  // ✅ FIX UTAMA: width HARUS bounded (tidak infinite)
                  if (isWide) {
                    final tableW = (w < 980) ? 980.0 : w;
                    listBody = SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: tableW, child: content),
                    );
                  } else {
                    listBody = content;
                  }
                }

                return XCard(
                  title: 'Users',
                  subtitle: 'Total: $total • page $safeCurrent/$safeLast',
                  child: Column(
                    children: [
                      if (error && snap.data != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _warnBar('Gagal refresh: ${snap.error}'),
                        ),
                      listBody,
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: (_page > 1 && !loading)
                                ? () {
                                    _page -= 1;
                                    _reloadUsers();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left_rounded),
                            label: const Text('Prev'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              color: const Color(0xFFF8FAFC),
                            ),
                            child: Text(
                              'Page $_page',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                fontSize: 12.2,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: (!loading && _page < safeLast)
                                ? () {
                                    _page += 1;
                                    _reloadUsers();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded),
                            label: const Text('Next'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _roleNameById(List<Map<String, dynamic>> roles, int id) {
    for (final r in roles) {
      if (_i(r['id']) == id) return _s(r['name'], 'Role');
    }
    return 'Role';
  }

  String _userRoleName(dynamic e) {
    final m = e is Map ? e : {};
    final role = m['role'];
    if (role is Map) return _s(role['name'], '-');
    return '-';
  }

  String _userRoleSlug(dynamic e) {
    final m = e is Map ? e : {};
    final role = m['role'];
    if (role is Map) return _s(role['slug'], '');
    return '';
  }

  Future<bool?> _pickTriState({
    required String title,
    required bool? current,
  }) async {
    return showDialog<bool?>(
      context: context,
      builder: (_) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('All'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
        ],
      ),
    );
  }

  Future<int?> _pickRole(List<Map<String, dynamic>> roles, int? currentRoleId) {
    return showDialog<int?>(
      context: context,
      builder: (_) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Role'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('All Roles'),
          ),
          for (final r in roles)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(_i(r['id'])),
              child: Text('${_s(r['name'])}  (${_s(r['slug'])})'),
            ),
        ],
      ),
    );
  }

  Widget _warnBar(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF92400E),
                fontSize: 12.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// UI COMPONENTS (self-contained)
// =============================================================
class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.8,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class XCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const XCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontSize: 14.6,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 12.2,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// ✅ FIX UTAMA: tombol aman untuk callback async (tidak pernah setState async)
class OutlineButtonX extends StatefulWidget {
  final IconData icon;
  final String label;

  /// boleh async / sync (sync tinggal: () async { ... })
  final Future<void> Function()? onTap;

  final bool enabled;

  const OutlineButtonX({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<OutlineButtonX> createState() => _OutlineButtonXState();
}

class _OutlineButtonXState extends State<OutlineButtonX> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (!widget.enabled) return;
    if (widget.onTap == null) return;
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await widget.onTap!.call();
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.onTap == null || _busy;

    return Opacity(
      opacity: disabled ? 0.65 : 1.0,
      child: InkWell(
        onTap: disabled ? null : _handleTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            color: const Color(0xFFF8FAFC),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(widget.icon, size: 18, color: const Color(0xFF334155)),
              const SizedBox(width: 8),
              Text(
                _busy ? 'Loading…' : widget.label,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 12.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// Header row (desktop only)
// =========================
class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: const Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('User', style: TextStyle(fontWeight: FontWeight.w900))),
          SizedBox(width: 10),
          Expanded(
              flex: 2,
              child: Text('Role', style: TextStyle(fontWeight: FontWeight.w900))),
          Expanded(
              flex: 2,
              child:
                  Text('Status', style: TextStyle(fontWeight: FontWeight.w900))),
          Expanded(
              flex: 2,
              child:
                  Text('Login', style: TextStyle(fontWeight: FontWeight.w900))),
          Expanded(
              flex: 3,
              child: Text('Actions',
                  style: TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

// =========================
// Row widget (CRUD)
// - Desktop: tombol actions tetap wrap
// - Mobile : actions via arrow dropdown ✅
// =========================
class _UserRowCrud extends StatefulWidget {
  final bool isWide;
  final bool isCompact;
  final Map<String, dynamic> user;
  final Color roleColor;
  final String roleLabel;
  final bool frozen;
  final bool active;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onFreeze;
  final VoidCallback onUnfreeze;
  final VoidCallback onResetPassword;
  final VoidCallback onForceLogout;

  final String Function(String iso) formatTime;
  final String Function(dynamic v, [String fb]) s;

  const _UserRowCrud({
    super.key,
    required this.isWide,
    required this.isCompact,
    required this.user,
    required this.roleColor,
    required this.roleLabel,
    required this.frozen,
    required this.active,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    required this.onFreeze,
    required this.onUnfreeze,
    required this.onResetPassword,
    required this.onForceLogout,
    required this.formatTime,
    required this.s,
  });

  @override
  State<_UserRowCrud> createState() => _UserRowCrudState();
}

class _UserRowCrudState extends State<_UserRowCrud> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final id = (widget.user['id'] ?? '').toString();
    final name = widget.s(widget.user['name'], '-');
    final email = widget.s(widget.user['email'], '-');

    final lastLoginAtRaw = widget.s(widget.user['last_login_at'], '-');
    final lastLoginAt =
        lastLoginAtRaw == '-' ? '-' : widget.formatTime(lastLoginAtRaw);

    final statusColor = widget.frozen
        ? const Color(0xFFDC2626)
        : (widget.active
            ? const Color(0xFF16A34A)
            : const Color(0xFF64748B));
    final statusLabel = widget.frozen
        ? 'FROZEN'
        : (widget.active ? 'ACTIVE' : 'INACTIVE');

    // ===== DESKTOP ROW =====
    if (widget.isWide) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name  (#$id)',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      fontSize: 12.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _pill(widget.roleLabel, widget.roleColor),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _pill(statusLabel, statusColor),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                lastLoginAt,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _miniBtn(
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                      onTap: widget.onEdit),
                  _miniBtn(
                    icon: widget.active
                        ? Icons.toggle_off_rounded
                        : Icons.toggle_on_rounded,
                    label: widget.active ? 'Off' : 'On',
                    onTap: widget.onToggleActive,
                  ),
                  _miniBtn(
                    icon: widget.frozen
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    label: widget.frozen ? 'Unfreeze' : 'Freeze',
                    onTap: widget.frozen ? widget.onUnfreeze : widget.onFreeze,
                    danger: !widget.frozen,
                  ),
                  _miniBtn(
                    icon: Icons.password_rounded,
                    label: 'Reset',
                    onTap: widget.onResetPassword,
                    danger: true,
                  ),
                  _miniBtn(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    onTap: widget.onForceLogout,
                    danger: true,
                  ),
                  _miniBtn(
                    icon: Icons.delete_outline_rounded,
                    label: 'Hapus',
                    onTap: widget.onDelete,
                    danger: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ===== MOBILE CARD (arrow dropdown actions) =====
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // left info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name  (#$id)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          fontSize: 14.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          fontSize: 12.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill(widget.roleLabel, widget.roleColor),
                          _pill(statusLabel, statusColor),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              color: const Color(0xFFF8FAFC),
                            ),
                            child: Text(
                              lastLoginAt == '-' ? 'Login: -' : 'Login: $lastLoginAt',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11.4,
                                color: Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // arrow toggle
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(height: 18),
                  _actionTile(icon: Icons.edit_rounded, title: 'Edit', onTap: widget.onEdit),
                  _actionTile(
                    icon: widget.active ? Icons.toggle_off_rounded : Icons.toggle_on_rounded,
                    title: widget.active ? 'Nonaktifkan' : 'Aktifkan',
                    onTap: widget.onToggleActive,
                  ),
                  _actionTile(
                    icon: widget.frozen ? Icons.lock_open_rounded : Icons.lock_rounded,
                    title: widget.frozen ? 'Unfreeze' : 'Freeze',
                    onTap: widget.frozen ? widget.onUnfreeze : widget.onFreeze,
                    danger: !widget.frozen,
                  ),
                  _actionTile(
                    icon: Icons.password_rounded,
                    title: 'Reset Password',
                    onTap: widget.onResetPassword,
                    danger: true,
                  ),
                  _actionTile(
                    icon: Icons.logout_rounded,
                    title: 'Force Logout',
                    onTap: widget.onForceLogout,
                    danger: true,
                  ),
                  _actionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Hapus Akun',
                    onTap: widget.onDelete,
                    danger: true,
                  ),
                ],
              ),
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final c = danger ? const Color(0xFFDC2626) : const Color(0xFF0F172A);
    return InkWell(
      onTap: () {
        setState(() => _expanded = false);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(.14)),
          color: c.withOpacity(.06),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w900, color: c),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _miniBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final c = danger ? const Color(0xFFDC2626) : const Color(0xFF0F172A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withOpacity(.18)),
          color: c.withOpacity(.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 11.8, color: c),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _pill(String s, Color c) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: c.withOpacity(.25)),
      color: c.withOpacity(.10),
    ),
    child: Text(
      s,
      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: c),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    ),
  );
}

// =========================
// Dialog: Create/Edit user
// =========================
class _UserFormResult {
  final String name;
  final String email;
  final int? roleId;
  final bool isActive;
  final String? password;

  _UserFormResult({
    required this.name,
    required this.email,
    required this.roleId,
    required this.isActive,
    required this.password,
  });
}

class _UserFormDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> roles;
  final _UserFormResult? initial;
  final bool isCreate;

  const _UserFormDialog({
    required this.title,
    required this.roles,
    required this.initial,
    required this.isCreate,
  });

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC;
  late final TextEditingController _emailC;
  late final TextEditingController _passC;

  int? _roleId;
  bool _isActive = true;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.initial?.name ?? '');
    _emailC = TextEditingController(text: widget.initial?.email ?? '');
    _passC = TextEditingController(text: '');
    _roleId = widget.initial?.roleId;
    _isActive = widget.initial?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _s(dynamic v, [String fb = '']) {
    if (v == null) return fb;
    final t = v.toString().trim();
    return t.isEmpty ? fb : t;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameC,
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama wajib' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailC,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Email wajib';
                    if (!t.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (widget.isCreate) ...[
                  TextFormField(
                    controller: _passC,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.length < 6) return 'Min 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                DropdownButtonFormField<int?>(
                  value: _roleId,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tanpa Role (null)'),
                    ),
                    for (final r in widget.roles)
                      DropdownMenuItem<int?>(
                        value: _i(r['id']),
                        child: Text(
                            '${_s(r['name'], 'Role')}  (${_s(r['slug'], '-')})'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _roleId = v),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Akun Aktif'),
                  subtitle:
                      const Text('Jika nonaktif, user tidak boleh akses sistem.'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(
              _UserFormResult(
                name: _nameC.text.trim(),
                email: _emailC.text.trim(),
                roleId: _roleId,
                isActive: _isActive,
                password: widget.isCreate ? _passC.text.trim() : null,
              ),
            );
          },
          child: Text(widget.isCreate ? 'Buat' : 'Simpan'),
        ),
      ],
    );
  }
}

// =========================
// Small filter chip
// =========================
class _FilterChipX extends StatelessWidget {
  final String label;
  final IconData icon;
  final Future<void> Function() onTap;

  const _FilterChipX({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          color: const Color(0xFFF8FAFC),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0F172A)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.2,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded,
                size: 18, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

// =========================
// Busy dialog
// =========================
class _BusyDialog extends StatelessWidget {
  final String label;
  const _BusyDialog({required this.label});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// Local Loading & Error card
// =========================
class _LoadingCardX extends StatelessWidget {
  final String title;
  const _LoadingCardX({required this.title});

  @override
  Widget build(BuildContext context) {
    return XCard(
      title: title,
      subtitle: 'Memuat data…',
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SizedBox(width: 6),
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading…',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCardX extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorCardX({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return XCard(
      title: title,
      subtitle: 'Terjadi error saat mengambil data.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFFDC2626),
              fontSize: 12.8,
            ),
          ),
          const SizedBox(height: 10),
          OutlineButtonX(
            icon: Icons.refresh_rounded,
            label: 'Coba Lagi',
            onTap: () async => onRetry(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

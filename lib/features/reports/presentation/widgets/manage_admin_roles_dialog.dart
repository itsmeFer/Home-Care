import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/features/reports/presentation/widgets/audit_dialog_helpers.dart';

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class ManageAdminRolesDialog {
  static Future<void> show({
    required BuildContext context,
    required String token,
    required bool isDesktop,
    required Future<Map<String, dynamic>> Function({
      required String token,
      String q,
      int page,
      int perPage,
    }) fetchAdminUsers,
    required Future<List<Map<String, dynamic>>> Function({
      required String token,
    }) fetchRoles,
    required Future<void> Function({
      required int userId,
      required String token,
      required String roleSlug,
      String reason,
      bool revokeTokens,
    }) updateUserRole,
    required void Function(String msg) toast,
  }) async {
const kCard = Colors.white;
    const kBorder = Color(0xFFE2E8F0);
    const kText = Color(0xFF0F172A);
    const kMuted = Color(0xFF64748B);
    const kBg = Color(0xFFFFFFFF);

    const kInfo = Color(0xFF0284C7);
    const kDanger = Color(0xFFDC2626);
    const kSuccess = Color(0xFF16A34A);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {

        String q = '';
        bool loading = true;
        bool busy = false;
        String? err;
        bool didInit = false;

        int page = 1;
        int perPage = 15;
        int lastPage = 1;
        int total = 0;

        final searchCtrl = TextEditingController();
        final reasonCtrl = TextEditingController();
        Timer? debounce;

        List<Map<String, dynamic>> items = [];
        List<Map<String, dynamic>> roleOptions = [];

        final Map<int, String> pendingRoleById = {};

        final List<Map<String, String>> logPreview = [];

        String roleNameFromSlug(String slug) {
          final hit =
              roleOptions
                  .where((r) => (r['slug'] ?? '').toString() == slug)
                  .toList();
          return hit.isEmpty ? slug : (hit.first['name'] ?? slug).toString();
        }

        Future<void> load(void Function(void Function()) setStateSB) async {
          setStateSB(() {
            loading = true;
            err = null;
          });

          try {
            // token in scope

            if (roleOptions.isEmpty) {
              final roles = await fetchRoles(token: token);
              roleOptions = roles;
            }

            final paged = await fetchAdminUsers(
              token: token,
              q: q,
              page: page,
              perPage: perPage,
            );

            final List list =
                (paged['data'] is List) ? paged['data'] : const [];
            items =
                list
                    .map(
                      (e) =>
                          (e is Map)
                              ? Map<String, dynamic>.from(e)
                              : <String, dynamic>{},
                    )
                    .toList();

            total = _toInt(paged['total']);
            lastPage = _toInt(paged['last_page']);
            if (lastPage <= 0) lastPage = 1;

            setStateSB(() => loading = false);
          } catch (e) {
            setStateSB(() {
              loading = false;
              err = e.toString();
            });
          }
        }

        Widget pill({
          required String text,
          required Color bg,
          required Color border,
          required Color fg,
        }) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: bg,
              border: Border.all(color: border),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: fg,
                fontSize: 12,
              ),
            ),
          );
        }

        Widget userRow(
          Map<String, dynamic> u,
          void Function(void Function()) setStateSB,
        ) {
          final id = _toInt(u['id']);
          final name = (u['name'] ?? '-').toString();
          final email = (u['email'] ?? '-').toString();

          final roleMap =
              (u['role'] is Map) ? Map<String, dynamic>.from(u['role']) : null;
          final currentSlug = (roleMap?['slug'] ?? '-').toString();
          final currentName = (roleMap?['name'] ?? '-').toString();

          final pendingSlug = pendingRoleById[id];
          final displaySlug = pendingSlug ?? currentSlug;
          final displayName =
              pendingSlug != null ? roleNameFromSlug(pendingSlug) : currentName;

          final changed = pendingSlug != null && pendingSlug != currentSlug;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFE0F2FE),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Icon(Icons.person_rounded, color: kInfo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (changed)
                            pill(
                              text: 'CHANGED',
                              bg: const Color(0xFFFEF3C7),
                              border: const Color(0xFFFDE68A),
                              fg: const Color(0xFF92400E),
                            )
                          else
                            pill(
                              text: 'OK',
                              bg: const Color(0xFFE0F2FE),
                              border: const Color(0xFFBAE6FD),
                              fg: kInfo,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kMuted,
                          fontSize: 12.4,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: kBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value:
                                      displaySlug == '-' ? null : displaySlug,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.expand_more_rounded,
                                    color: kMuted,
                                  ),
                                  hint: const Text(
                                    'Pilih role',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  items:
                                      roleOptions.map((r) {
                                        final slug =
                                            (r['slug'] ?? '-').toString();
                                        final nm =
                                            (r['name'] ?? slug).toString();
                                        return DropdownMenuItem<String>(
                                          value: slug,
                                          child: Text(
                                            nm,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: kText,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged:
                                      busy || loading
                                          ? null
                                          : (val) {
                                            if (val == null) return;
                                            setStateSB(() {
                                              if (val == currentSlug) {
                                                pendingRoleById.remove(id);
                                              } else {
                                                pendingRoleById[id] = val;
                                              }
                                            });
                                          },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white,
                              border: Border.all(color: kBorder),
                            ),
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kMuted,
                                fontSize: 12.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        Future<void> applyChanges(
          void Function(void Function()) setStateSB,
        ) async {
          if (pendingRoleById.isEmpty) {
            toast('Tidak ada perubahan role.');
            return;
          }

          setStateSB(() => busy = true);

          try {
            // token in scope

            int successCount = 0;
            int failCount = 0;
            final List<String> errors = [];

            for (final entry in pendingRoleById.entries) {
              final userId = entry.key;
              final newSlug = entry.value;

              final idx = items.indexWhere((u) => _toInt(u['id']) == userId);
              final beforeRole =
                  (idx >= 0 && items[idx]['role'] is Map)
                      ? Map<String, dynamic>.from(items[idx]['role'])
                      : <String, dynamic>{};
              final oldSlug = (beforeRole['slug'] ?? '-').toString();
              final oldName = (beforeRole['name'] ?? '-').toString();
              final userName =
                  (idx >= 0)
                      ? (items[idx]['name'] ?? 'User #$userId').toString()
                      : 'User #$userId';

              try {
                await updateUserRole(
                  userId: userId,
                  token: token,
                  roleSlug: newSlug,
                  reason: reasonCtrl.text.trim(),
                  revokeTokens: true,
                );

                successCount++;

                logPreview.insert(0, {
                  'title': 'user.role_changed',
                  'desc':
                      '$userName: $oldName ($oldSlug) → ${roleNameFromSlug(newSlug)} ($newSlug)',
                });
              } catch (e) {

                failCount++;
                errors.add('$userName: ${e.toString()}');
              }
            }

            pendingRoleById.clear();
            reasonCtrl.clear();

            await load(setStateSB);

            setStateSB(() => busy = false);

            if (failCount == 0) {

              if (!ctx.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Perubahan Role Berhasil!',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$successCount user berhasil diubah rolenya.',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
            } else if (successCount > 0) {

              if (!ctx.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.warning_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sebagian Berhasil',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '✓ $successCount berhasil, ✗ $failCount gagal',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFF59E0B),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  action: SnackBarAction(
                    label: 'Detail',
                    textColor: Colors.white,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text(
                                'Detail Error',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      errors.map((err) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Text(
                                            '• $err',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ),
              );
            } else {

              if (!ctx.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gagal Simpan',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Semua perubahan gagal ($failCount user)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  action: SnackBarAction(
                    label: 'Detail',
                    textColor: Colors.white,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text(
                                'Detail Error',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      errors.map((err) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Text(
                                            '• $err',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Tutup'),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            setStateSB(() => busy = false);

            if (!ctx.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Error Sistem',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          }
        }

        return StatefulBuilder(
          builder: (context, setStateSB) {

            if (!didInit) {
              didInit = true;
              Future.microtask(() => load(setStateSB));
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 920 : 560,
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: kBorder),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 30,
                      spreadRadius: 0,
                      offset: const Offset(0, 18),
                      color: Colors.black.withOpacity(0.14),
                    ),
                  ],
                ),
                child: Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFE0F2FE),
                              border: Border.all(
                                color: const Color(0xFFBAE6FD),
                              ),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: kInfo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kelola Admin / Role',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: kText,
                                    fontSize: 16.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Atur role user (dynamic). Simpan akan memanggil API & menulis audit_logs.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: kMuted,
                                    fontSize: 12.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed:
                                busy
                                    ? null
                                    : () {
                                      debounce?.cancel();
                                      Navigator.pop(ctx);
                                    },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: kMuted,
                            ),
                            tooltip: 'Tutup',
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchCtrl,
                                  onChanged: (v) {
                                    debounce?.cancel();
                                    debounce = Timer(
                                      const Duration(milliseconds: 350),
                                      () {
                                        setStateSB(() {
                                          q = v;
                                          page = 1;
                                        });
                                        load(setStateSB);
                                      },
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Cari nama / email / role...',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    filled: true,
                                    fillColor: kBg,
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: kMuted,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: kBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: kBorder,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFBAE6FD),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed:
                                    busy || loading
                                        ? null
                                        : () {
                                          searchCtrl.clear();
                                          setStateSB(() {
                                            q = '';
                                            page = 1;
                                          });
                                          load(setStateSB);
                                        },
                                icon: const Icon(Icons.clear_rounded),
                                tooltip: 'Clear',
                              ),
                              IconButton(
                                onPressed:
                                    busy || loading
                                        ? null
                                        : () => load(setStateSB),
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kBorder),
                            ),
                            child: TextField(
                              controller: reasonCtrl,
                              minLines: 1,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    'Alasan perubahan (opsional, untuk audit_logs)',
                                hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: kText,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: kBg,
                                  border: Border.all(color: kBorder),
                                ),
                                child: Text(
                                  'Total: $total',
                                  style: const TextStyle(
                                    color: kMuted,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: kBg,
                                  border: Border.all(color: kBorder),
                                ),
                                child: Text(
                                  'Pending: ${pendingRoleById.length}',
                                  style: const TextStyle(
                                    color: kMuted,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.4,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed:
                                    busy || loading
                                        ? null
                                        : () => applyChanges(setStateSB),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kSuccess,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.save_rounded, size: 18),
                                label: const Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: kBg,
                                  border: Border.all(color: kBorder),
                                ),
                                child: Text(
                                  'Page $page / $lastPage',
                                  style: const TextStyle(
                                    color: kMuted,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.4,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton(
                                onPressed:
                                    busy || loading || page <= 1
                                        ? null
                                        : () {
                                          setStateSB(() => page--);
                                          load(setStateSB);
                                        },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Prev',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed:
                                    busy || loading || page >= lastPage
                                        ? null
                                        : () {
                                          setStateSB(() => page++);
                                          load(setStateSB);
                                        },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Next',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child:
                            loading
                                ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                    ),
                                  ),
                                )
                                : (err != null)
                                ? DialogError(
                                  message: err!,
                                  onRetry: () => load(setStateSB),
                                )
                                : (items.isEmpty)
                                ? const DialogEmpty(
                                  title: 'Tidak ada data',
                                  subtitle: 'Coba kata kunci lain.',
                                )
                                : ListView(
                                  children: [
                                    ...items.map((u) => userRow(u, setStateSB)),
                                    const SizedBox(height: 12),

                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: kBorder),
                                        color: kBg,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Preview Audit Logs (lokal)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: kText,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (logPreview.isEmpty)
                                            const Text(
                                              'Belum ada aksi. Setelah "Simpan Perubahan", log akan muncul di sini.',
                                              style: TextStyle(
                                                color: kMuted,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.6,
                                              ),
                                            )
                                          else
                                            ...logPreview.take(6).map((l) {
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: kBorder,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 34,
                                                      height: 34,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        color: const Color(
                                                          0xFFE0F2FE,
                                                        ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFFBAE6FD,
                                                          ),
                                                        ),
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .receipt_long_outlined,
                                                        color: kInfo,
                                                        size: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            (l['title'] ?? '-')
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  color: kText,
                                                                  fontSize:
                                                                      12.8,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            (l['desc'] ?? '-')
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: kMuted,
                                                                  fontSize:
                                                                      12.2,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: kBorder)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Catatan: Simpan akan revoke token user yang diubah rolenya (user logout).',
                              style: TextStyle(
                                color: kMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed:
                                busy
                                    ? null
                                    : () {
                                      debounce?.cancel();
                                      Navigator.pop(ctx);
                                    },
                            child: const Text(
                              'Tutup',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

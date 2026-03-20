// AuditPage.dart (FULL) ✅ FIXED + RESPONSIVE
// ✅ TOKEN FIX: cek 'auth_token' dulu (sesuai login.dart), fallback 'token'
// ✅ RESPONSIVE FULL: Desktop (3 cols) / Tablet (2 cols) / Mobile (1 col)
// ✅ Audit KPI + Logs
// ✅ Export CSV (Web & Mobile) kolom rapi (sep=; + BOM)
// ✅ Freeze/Unfreeze SEMUA USER (tanpa filter role)
// ✅ Popup Freeze: search + debounce + pagination data list (ambil "data.data" kalau paginate)
// ✅ Kelola Admin (DYNAMIC) : list user (paginate) + search + ubah role + simpan (API) + preview log lokal
//
// Dependencies:
// - http, shared_preferences, path_provider, universal_io, universal_html
// - ui_components.dart (SectionHeader, LoadingCard, ErrorCard, ResponsiveGrid, KpiCard, XCard, OutlineButtonX)
//
// Backend:
// GET  /api/direktur/dashboard/audit?range=...
// GET  /api/direktur/freeze/users?q=...
// POST /api/direktur/freeze/users/{id}           body: {"reason": "..."} optional
// POST /api/direktur/freeze/users/{id}/unfreeze  body: null
//
// ✅ Kelola Admin / Role (DIRECTOR)
// GET  /api/direktur/kelola-admin/users?q=...&page=...&per_page=...
// GET  /api/direktur/kelola-admin/roles
// POST /api/direktur/kelola-admin/users/{id}/role body: {role_slug, reason?, revoke_tokens?}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart' as uio;
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

import '../widgets/ui_components.dart';

class AuditPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const AuditPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  static const String kBaseUrl = 'http://147.93.81.243';
  String get kApiBase => '$kBaseUrl/api';

  // ✅ sesuai route:list kamu: api/direktur/dashboard/audit
  String get _url =>
      '$kApiBase/direktur/dashboard/audit?range=${Uri.encodeComponent(widget.range)}';

  // ✅ Freeze API (SEMUA USER)
  String get _freezeListUrl => '$kApiBase/direktur/freeze/users';
  String _freezeUrl(int userId) => '$kApiBase/direktur/freeze/users/$userId';
  String _unfreezeUrl(int userId) =>
      '$kApiBase/direktur/freeze/users/$userId/unfreeze';

  // ✅ Kelola Admin / Role (DIRECTOR)
  String get _adminUsersUrl => '$kApiBase/direktur/kelola-admin/users';
  String get _adminRolesUrl => '$kApiBase/direktur/kelola-admin/roles';
  String _updateUserRoleUrl(int userId) =>
      '$kApiBase/direktur/kelola-admin/users/$userId/role';

  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void didUpdateWidget(covariant AuditPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      setState(() => _future = _fetch());
    }
  }

  // =========================
  // AUTH + FETCH
  // =========================
  Future<Map<String, dynamic>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ Cek auth_token dulu (sesuai login.dart), fallback ke token
    final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    if (token.isEmpty) throw Exception('Token kosong. Silakan login ulang.');

    final res = await http.get(
      Uri.parse(_url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);

      // format kamu: { success:true, data:{ ... } }
      if (body is Map && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data']);
      }
      return Map<String, dynamic>.from(body as Map);
    }

    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ Cek auth_token dulu (sesuai login.dart), fallback ke token
    final t = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    if (t.isEmpty) throw Exception('Token kosong. Silakan login ulang.');
    return t;
  }

  // =========================
  // HELPERS
  // =========================
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  // ✅ Normalisasi rating ke 0..5
  double? _normalizeRating(dynamic raw) {
    if (raw == null) return null;

    final d = _toDouble(raw);
    if (d.isNaN) return null;

    double r;
    if (d <= 1.0) {
      r = d * 5.0;
    } else if (d <= 5.0) {
      r = d;
    } else if (d <= 100.0) {
      r = d / 20.0;
    } else {
      r = d;
    }

    if (r < 0) r = 0;
    if (r > 5) r = 5;
    return r;
  }

  Uint8List _utf8WithBom(String s) {
    final b = utf8.encode(s);
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...b]);
  }

  String _esc(String s) {
    final needsQuote =
        s.contains(';') ||
        s.contains('\n') ||
        s.contains('\r') ||
        s.contains('"');
    if (!needsQuote) return s;
    final escaped = s.replaceAll('"', '""');
    return '"$escaped"';
  }

  // =========================
  // ✅ EXPORT CSV (LOCAL) - kolom selalu rapi
  // =========================
  Future<void> _exportAudit(Map<String, dynamic> data) async {
    try {
      final kpi = (data['kpi'] is Map)
          ? Map<String, dynamic>.from(data['kpi'])
          : <String, dynamic>{};

      final List logsRaw = (data['logs'] is List) ? data['logs'] : const [];

      final logs = logsRaw.map((e) {
        final m = (e is Map)
            ? Map<String, dynamic>.from(e)
            : <String, dynamic>{};
        final title = (m['title'] ?? 'Audit').toString();
        final desc = (m['desc'] ?? '-').toString();
        final time = (m['time'] ?? '-').toString();
        final icon = (m['icon'] ?? 'security').toString();

        final ratingRaw = m['rating'] ?? m['score'] ?? m['risk_score'];
        final rating = _normalizeRating(ratingRaw);

        return {
          'title': title,
          'desc': desc,
          'time': time,
          'icon': icon,
          'rating': rating,
        };
      }).toList();

      final sb = StringBuffer();
      sb.writeln('sep=;');

      sb.writeln('KPI;key;value');
      sb.writeln('KPI;range;${_esc(widget.range)}');
      sb.writeln('KPI;perubahan_fee_rule;${_toInt(kpi['perubahan_fee_rule'])}');
      sb.writeln('KPI;akun_baru;${_toInt(kpi['akun_baru'])}');
      sb.writeln('KPI;aksi_berisiko;${_toInt(kpi['aksi_berisiko'])}');

      sb.writeln('');
      sb.writeln('LOGS;title;desc;time;icon;rating');
      for (final m in logs) {
        final r = (m['rating'] as double?);
        final rTxt = r == null ? '' : r.toStringAsFixed(2);

        sb.writeln(
          'LOGS;'
          '${_esc((m['title'] ?? '').toString())};'
          '${_esc((m['desc'] ?? '').toString())};'
          '${_esc((m['time'] ?? '').toString())};'
          '${_esc((m['icon'] ?? '').toString())};'
          '${_esc(rTxt)}',
        );
      }

      final bytes = _utf8WithBom(sb.toString());

      final safeRange = widget.range.replaceAll(' ', '_');
      final safeTime = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'audit_${safeRange}_$safeTime.csv';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: blobUrl)
          ..download = fileName
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
        _toast('Export audit berhasil (CSV).');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = uio.File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      _toast('Export tersimpan: ${file.path}');
    } catch (e) {
      _toast('Gagal export: $e');
    }
  }

  // =========================
  // ✅ FREEZE POPUP (DIRECTOR) - SEMUA ROLE
  // =========================

  Future<List<Map<String, dynamic>>> _fetchFreezeUsers({
    required String token,
    String q = '',
  }) async {
    final uri = Uri.parse(
      _freezeListUrl,
    ).replace(queryParameters: {if (q.trim().isNotEmpty) 'q': q.trim()});

    final res = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body);
    final data = (body is Map) ? body['data'] : null;

    // Laravel paginate: data: { data: [...], ... }
    final List list = (data is Map && data['data'] is List)
        ? data['data']
        : (data is List ? data : const []);

    return list
        .map(
          (e) =>
              (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{},
        )
        .toList();
  }

  Future<void> _doFreezeAction({
    required int userId,
    required bool freeze, // true=freeze, false=unfreeze
    String reason = '',
  }) async {
    final token = await _token();

    final uri = Uri.parse(freeze ? _freezeUrl(userId) : _unfreezeUrl(userId));

    final res = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: freeze ? jsonEncode({'reason': reason}) : null,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final body = jsonDecode(res.body);
        final msg = (body is Map && body['message'] != null)
            ? body['message'].toString()
            : 'HTTP ${res.statusCode}';
        throw Exception(msg);
      } catch (_) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    }
  }

  // ✅ FIX LOOP: pakai StatefulBuilder + didInit + setStateSB
  Future<void> _openFreezePopup() async {
    final token = await _token();

    // theme (samain dengan UI page kamu)
    const kCard = Colors.white;
    const kBorder = Color(0xFFE2E8F0);
    const kText = Color(0xFF0F172A);
    const kMuted = Color(0xFF64748B);
    const kBg = Color(0xFFF8FAFC);

    const kDanger = Color(0xFFDC2626);
    const kInfo = Color(0xFF0284C7);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // STATE dialog
        String q = '';
        bool loading = true;
        bool busyAction = false;
        String? err;
        bool didInit = false;

        final reasonCtrl = TextEditingController();
        final searchCtrl = TextEditingController();
        Timer? debounce;

        List<Map<String, dynamic>> items = [];

        Future<void> load(void Function(void Function()) setStateSB) async {
          setStateSB(() {
            loading = true;
            err = null;
          });

          try {
            final res = await _fetchFreezeUsers(token: token, q: q);
            setStateSB(() {
              items = res;
              loading = false;
            });
          } catch (e) {
            setStateSB(() {
              loading = false;
              err = e.toString();
            });
          }
        }

        Widget userRow(
          Map<String, dynamic> u,
          void Function(void Function()) setStateSB,
        ) {
          final id = _toInt(u['id']);
          final name = (u['name'] ?? '-').toString();
          final email = (u['email'] ?? '-').toString();

          final roleMap = (u['role'] is Map)
              ? Map<String, dynamic>.from(u['role'])
              : null;
          final roleName = (roleMap?['name'] ?? '-').toString();
          final roleSlug = (roleMap?['slug'] ?? '-').toString();

          // ✅ Freeze API kamu mengirim is_active (kalau tidak ada, anggap true)
          final ia = u['is_active'];
          final bool isActive = (ia is bool)
              ? ia
              : (ia == null ? true : ia.toString() == '1');
          final frozen = !isActive;

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
                    color: frozen
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFE0F2FE),
                    border: Border.all(
                      color: frozen
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Icon(
                    frozen ? Icons.lock_rounded : Icons.person_rounded,
                    color: frozen ? kDanger : kInfo,
                  ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white,
                              border: Border.all(color: kBorder),
                            ),
                            child: Text(
                              roleName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kMuted,
                                fontSize: 12,
                              ),
                            ),
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: frozen
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFDCFCE7),
                              border: Border.all(
                                color: frozen
                                    ? const Color(0xFFFECACA)
                                    : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Text(
                              frozen ? 'FROZEN' : 'ACTIVE',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: frozen
                                    ? kDanger
                                    : const Color(0xFF15803D),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: busyAction
                                ? null
                                : () async {
                                    final wantFreeze = !frozen;

                                    final ok = await showDialog<bool>(
                                      context: ctx,
                                      barrierDismissible: true,
                                      builder: (c2) {
                                        return AlertDialog(
                                          backgroundColor: kCard,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          title: Text(
                                            wantFreeze
                                                ? 'Freeze Akun'
                                                : 'Unfreeze Akun',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: kText,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$name ($roleSlug)',
                                                style: const TextStyle(
                                                  color: kMuted,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              if (wantFreeze) ...[
                                                const Text(
                                                  'Alasan (opsional)',
                                                  style: TextStyle(
                                                    color: kText,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                TextField(
                                                  controller: reasonCtrl,
                                                  minLines: 2,
                                                  maxLines: 3,
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'contoh: pelanggaran SOP / akun bermasalah',
                                                    hintStyle: const TextStyle(
                                                      color: Color(0xFF94A3B8),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                    filled: true,
                                                    fillColor: const Color(
                                                      0xFFF8FAFC,
                                                    ),
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 10,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: kBorder,
                                                          ),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: kBorder,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                14,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: Color(
                                                                  0xFFBAE6FD,
                                                                ),
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                              ] else ...[
                                                const Text(
                                                  'Akun akan diaktifkan kembali.',
                                                  style: TextStyle(
                                                    color: kMuted,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c2, false),
                                              child: const Text(
                                                'Batal',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: wantFreeze
                                                    ? kDanger
                                                    : const Color(0xFF16A34A),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  Navigator.pop(c2, true),
                                              child: Text(
                                                wantFreeze
                                                    ? 'Freeze'
                                                    : 'Unfreeze',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (ok != true) return;

                                    try {
                                      setStateSB(() => busyAction = true);

                                      await _doFreezeAction(
                                        userId: id,
                                        freeze: wantFreeze,
                                        reason: reasonCtrl.text.trim(),
                                      );

                                      reasonCtrl.clear();
                                      _toast(
                                        wantFreeze
                                            ? 'Akun berhasil di-freeze.'
                                            : 'Akun berhasil di-unfreeze.',
                                      );

                                      await load(setStateSB);

                                      setStateSB(() => busyAction = false);
                                    } catch (e) {
                                      setStateSB(() => busyAction = false);
                                      _toast('Gagal: $e');
                                    }
                                  },
                            icon: Icon(
                              frozen
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_rounded,
                              size: 18,
                              color: frozen ? const Color(0xFF16A34A) : kDanger,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: frozen
                                    ? const Color(0xFFBBF7D0)
                                    : const Color(0xFFFECACA),
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            label: Text(
                              frozen ? 'Unfreeze' : 'Freeze',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: frozen
                                    ? const Color(0xFF16A34A)
                                    : kDanger,
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

        return StatefulBuilder(
          builder: (context, setStateSB) {
            // ✅ init load sekali
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
                  maxWidth: widget.isDesktop ? 860 : 520,
                  maxHeight: MediaQuery.of(context).size.height * 0.86,
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
                    // header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFFEE2E2),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: const Icon(
                              Icons.gpp_maybe_outlined,
                              color: kDanger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Freeze Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: kText,
                                    fontSize: 16.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Cari user lalu freeze/unfreeze (Semua role).',
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
                            onPressed: busyAction
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

                    // controls
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
                                        q = v;
                                        load(setStateSB);
                                      },
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Cari nama / email...',
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
                                onPressed: busyAction
                                    ? null
                                    : () => load(setStateSB),
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // ✅ tanpa filter role, cuma badge "Semua Role" + total
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
                                child: const Text(
                                  'Semua Role',
                                  style: TextStyle(
                                    color: kMuted,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.4,
                                  ),
                                ),
                              ),
                              const Spacer(),
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
                                  'Total: ${items.length}',
                                  style: const TextStyle(
                                    color: kMuted,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // content
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: loading
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
                            ? _DialogError(
                                message: err!,
                                onRetry: () => load(setStateSB),
                              )
                            : (items.isEmpty)
                            ? const _DialogEmpty(
                                title: 'Tidak ada data',
                                subtitle: 'Coba ketik kata kunci lain.',
                              )
                            : ListView(
                                children: items
                                    .map((u) => userRow(u, setStateSB))
                                    .toList(),
                              ),
                      ),
                    ),

                    // footer
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: kBorder)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Freeze akan revoke token (user langsung logout).',
                              style: TextStyle(
                                color: kMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: busyAction
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

  // =========================
  // ✅ KELOLA ADMIN (DYNAMIC)
  // =========================

  Future<List<Map<String, dynamic>>> _fetchRoles({
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse(_adminRolesUrl),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body);
    final data = (body is Map) ? body['data'] : null;

    final List list = (data is List) ? data : const [];
    return list
        .map(
          (e) =>
              (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{},
        )
        .toList();
  }

  Future<Map<String, dynamic>> _fetchAdminUsers({
    required String token,
    String q = '',
    int page = 1,
    int perPage = 15,
  }) async {
    final qp = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (q.trim().isNotEmpty) 'q': q.trim(),
    };

    final uri = Uri.parse(_adminUsersUrl).replace(queryParameters: qp);

    final res = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body);
    final data = (body is Map) ? body['data'] : null; // paginate object
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  Future<void> _updateUserRole({
    required int userId,
    required String token,
    required String roleSlug,
    String reason = '',
    bool revokeTokens = true,
  }) async {
    final uri = Uri.parse(_updateUserRoleUrl(userId));

    final res = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'role_slug': roleSlug,
        'reason': reason,
        'revoke_tokens': revokeTokens,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final body = jsonDecode(res.body);
        final msg = (body is Map && body['message'] != null)
            ? body['message'].toString()
            : 'HTTP ${res.statusCode}';
        throw Exception(msg);
      } catch (_) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    }
  }

  Future<void> _openKelolaAdminPopup() async {
    // theme (samain dengan UI page kamu)
    const kCard = Colors.white;
    const kBorder = Color(0xFFE2E8F0);
    const kText = Color(0xFF0F172A);
    const kMuted = Color(0xFF64748B);
    const kBg = Color(0xFFF8FAFC);

    const kInfo = Color(0xFF0284C7);
    const kDanger = Color(0xFFDC2626);
    const kSuccess = Color(0xFF16A34A);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // STATE dialog
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
        final reasonCtrl = TextEditingController(); // opsional
        Timer? debounce;

        List<Map<String, dynamic>> items = [];
        List<Map<String, dynamic>> roleOptions = [];

        // ✅ tracking perubahan: userId -> roleSlug baru
        final Map<int, String> pendingRoleById = {};

        // ✅ log preview (lokal)
        final List<Map<String, String>> logPreview = [];

        String roleNameFromSlug(String slug) {
          final hit = roleOptions
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
            final token = await _token();

            if (roleOptions.isEmpty) {
              final roles = await _fetchRoles(token: token);
              roleOptions = roles;
            }

            final paged = await _fetchAdminUsers(
              token: token,
              q: q,
              page: page,
              perPage: perPage,
            );

            final List list = (paged['data'] is List)
                ? paged['data']
                : const [];
            items = list
                .map(
                  (e) => (e is Map)
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

          final roleMap = (u['role'] is Map)
              ? Map<String, dynamic>.from(u['role'])
              : null;
          final currentSlug = (roleMap?['slug'] ?? '-').toString();
          final currentName = (roleMap?['name'] ?? '-').toString();

          // ✅ role yang tampil = pending kalau ada, else current
          final pendingSlug = pendingRoleById[id];
          final displaySlug = pendingSlug ?? currentSlug;
          final displayName = pendingSlug != null
              ? roleNameFromSlug(pendingSlug)
              : currentName;

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

                      // ✅ Role dropdown (dynamic)
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
                                  value: displaySlug == '-'
                                      ? null
                                      : displaySlug,
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
                                  items: roleOptions.map((r) {
                                    final slug = (r['slug'] ?? '-').toString();
                                    final nm = (r['name'] ?? slug).toString();
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
                                  onChanged: busy || loading
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
            _toast('Tidak ada perubahan role.');
            return;
          }

          setStateSB(() => busy = true);

          try {
            final token = await _token();

            // ✅ Counter untuk tracking success
            int successCount = 0;
            int failCount = 0;
            final List<String> errors = [];

            for (final entry in pendingRoleById.entries) {
              final userId = entry.key;
              final newSlug = entry.value;

              // ambil sebelum utk preview (opsional)
              final idx = items.indexWhere((u) => _toInt(u['id']) == userId);
              final beforeRole = (idx >= 0 && items[idx]['role'] is Map)
                  ? Map<String, dynamic>.from(items[idx]['role'])
                  : <String, dynamic>{};
              final oldSlug = (beforeRole['slug'] ?? '-').toString();
              final oldName = (beforeRole['name'] ?? '-').toString();
              final userName = (idx >= 0)
                  ? (items[idx]['name'] ?? 'User #$userId').toString()
                  : 'User #$userId';

              try {
                await _updateUserRole(
                  userId: userId,
                  token: token,
                  roleSlug: newSlug,
                  reason: reasonCtrl.text.trim(),
                  revokeTokens: true,
                );

                // ✅ Success
                successCount++;

                logPreview.insert(0, {
                  'title': 'user.role_changed',
                  'desc':
                      '$userName: $oldName ($oldSlug) → ${roleNameFromSlug(newSlug)} ($newSlug)',
                });
              } catch (e) {
                // ✅ Track error per user
                failCount++;
                errors.add('$userName: ${e.toString()}');
              }
            }

            pendingRoleById.clear();
            reasonCtrl.clear();

            // reload agar data fresh dari server
            await load(setStateSB);

            setStateSB(() => busy = false);

            // ✅ NOTIFIKASI LENGKAP
            if (failCount == 0) {
              // Semua berhasil
              if (!mounted) return;
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
              // Sebagian berhasil
              if (!mounted) return;
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
                        builder: (ctx) => AlertDialog(
                          title: const Text(
                            'Detail Error',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: errors.map((err) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
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
              // Semua gagal
              if (!mounted) return;
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
                        builder: (ctx) => AlertDialog(
                          title: const Text(
                            'Detail Error',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: errors.map((err) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
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

            // ✅ Error umum (di luar loop)
            if (!mounted) return;
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
            // init load sekali
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
                  maxWidth: widget.isDesktop ? 920 : 560,
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
                    // header
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
                            onPressed: busy
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

                    // controls
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
                                onPressed: busy || loading
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
                                onPressed: busy || loading
                                    ? null
                                    : () => load(setStateSB),
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // alasan opsional (sekali untuk batch save)
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
                                onPressed: busy || loading
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

                          // pagination
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
                                onPressed: busy || loading || page <= 1
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
                                onPressed: busy || loading || page >= lastPage
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

                    // content
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: loading
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
                            ? _DialogError(
                                message: err!,
                                onRetry: () => load(setStateSB),
                              )
                            : (items.isEmpty)
                            ? const _DialogEmpty(
                                title: 'Tidak ada data',
                                subtitle: 'Coba kata kunci lain.',
                              )
                            : ListView(
                                children: [
                                  ...items.map((u) => userRow(u, setStateSB)),
                                  const SizedBox(height: 12),

                                  // ✅ log preview
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
                                              padding: const EdgeInsets.all(10),
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
                                                                fontSize: 12.8,
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
                                                                fontSize: 12.2,
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

                    // footer
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
                            onPressed: busy
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

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    // ✅ RESPONSIVE: Desktop (3 cols) / Tablet (2 cols) / Mobile (1 col)
    final cols = widget.isDesktop ? 3 : (widget.isTablet ? 2 : 1);

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final isLoading =
            snap.connectionState == ConnectionState.waiting &&
            snap.data == null;
        final isError = snap.hasError && snap.data == null;

        final data = snap.data ?? {};
        final kpi = (data['kpi'] is Map)
            ? Map<String, dynamic>.from(data['kpi'])
            : <String, dynamic>{};

        final feeRule = _toInt(kpi['perubahan_fee_rule']).toString();
        final akunBaru = _toInt(kpi['akun_baru']).toString();
        final aksiBerisiko = _toInt(kpi['aksi_berisiko']).toString();

        final List logs = (data['logs'] is List) ? data['logs'] : const [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Audit & Control',
              subtitle: 'Log perubahan penting (${widget.range}).',
            ),
            const SizedBox(height: 12),

            if (isLoading)
              const LoadingCard(title: 'Audit & Control')
            else if (isError)
              ErrorCard(
                title: 'Audit & Control',
                message: snap.error.toString(),
                onRetry: () => setState(() => _future = _fetch()),
              ),

            ResponsiveGrid(
              columns: cols,
              gap: 12,
              children: [
                KpiCard(
                  title: 'Perubahan Fee Rule',
                  value: feeRule,
                  hint: widget.range,
                  icon: Icons.rule_outlined,
                  accent: const Color(0xFFF59E0B),
                ),
                KpiCard(
                  title: 'Akun Baru',
                  value: akunBaru,
                  hint: widget.range,
                  icon: Icons.person_add_outlined,
                  accent: const Color(0xFF0EA5E9),
                ),
                KpiCard(
                  title: 'Aksi Berisiko',
                  value: aksiBerisiko,
                  hint: 'Perlu review',
                  icon: Icons.warning_amber_outlined,
                  accent: const Color(0xFFDC2626),
                ),
              ],
            ),

            const SizedBox(height: 12),

            XCard(
              title: 'Audit Log (Terbaru)',
              subtitle: 'Siapa melakukan apa & kapan.',
              child: (logs.isEmpty)
                  ? const _EmptyState(
                      text: 'Belum ada audit log pada range ini.',
                    )
                  : Column(
                      children: logs.take(10).map((e) {
                        final m = (e is Map)
                            ? Map<String, dynamic>.from(e)
                            : <String, dynamic>{};

                        final title = (m['title'] ?? 'Audit').toString();
                        final desc = (m['desc'] ?? '-').toString();
                        final time = (m['time'] ?? '-').toString();

                        final iconName = (m['icon'] ?? 'security').toString();
                        final icon = _iconFromName(iconName);

                        final ratingRaw =
                            m['rating'] ?? m['score'] ?? m['risk_score'];
                        final rating = _normalizeRating(ratingRaw);

                        return _AuditRow(
                          title: title,
                          desc: desc,
                          time: time,
                          icon: icon,
                          rating: rating,
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 12),

            XCard(
              title: 'Kontrol Direktur',
              subtitle:
                  'Aksi yang hanya boleh dilakukan direktur (placeholder).',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlineButtonX(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Kelola Admin',
                    onTap: _openKelolaAdminPopup,
                  ),
                  OutlineButtonX(
                    icon: Icons.lock_reset_outlined,
                    label: 'Reset Akses',
                    onTap: () {},
                  ),
                  OutlineButtonX(
                    icon: Icons.gpp_maybe_outlined,
                    label: 'Freeze User',
                    onTap: _openFreezePopup,
                  ),
                  OutlineButtonX(
                    icon: Icons.key_outlined,
                    label: 'Approval Rule',
                    onTap: () {},
                  ),
                  OutlineButtonX(
                    icon: Icons.download_outlined,
                    label: 'Export Audit',
                    onTap: () => _exportAudit(data),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'rule':
        return Icons.rule_outlined;
      case 'price_change':
      case 'price':
        return Icons.price_change_outlined;
      case 'person_add':
      case 'user':
        return Icons.person_add_alt_1_outlined;
      case 'approval':
        return Icons.approval_outlined;
      default:
        return Icons.security_outlined;
    }
  }
}

// =========================
// UI kecil untuk dialog
// =========================

class _DialogEmpty extends StatelessWidget {
  final String title;
  final String subtitle;
  const _DialogEmpty({required this.title, required this.subtitle});

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
          const Icon(Icons.inbox_outlined, color: Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _DialogError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7F1D1D),
                fontWeight: FontWeight.w800,
                fontSize: 12.6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Coba lagi',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
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
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final String title;
  final String desc;
  final String time;
  final IconData icon;
  final double? rating;

  const _AuditRow({
    required this.title,
    required this.desc,
    required this.time,
    required this.icon,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    Widget ratingUi() {
      final r = rating;
      if (r == null) return const SizedBox.shrink();

      final full = r.floor();
      final hasHalf = (r - full) >= 0.5;

      final stars = <Widget>[];
      for (int i = 0; i < 5; i++) {
        IconData ic;
        if (i < full) {
          ic = Icons.star_rounded;
        } else if (i == full && hasHalf) {
          ic = Icons.star_half_rounded;
        } else {
          ic = Icons.star_outline_rounded;
        }
        stars.add(Icon(ic, size: 16, color: const Color(0xFFF59E0B)));
      }

      return Row(
        children: [
          ...stars,
          const SizedBox(width: 8),
          Text(
            r.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontSize: 12.2,
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: const Color(0xFFF8FAFC),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFE0F2FE),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Icon(icon, color: const Color(0xFF0284C7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                ratingUi(),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.2,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'package:home_care/core/services/storage_service.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart' as uio;

import 'package:universal_html/html.dart' as html;
import 'package:home_care/core/constants/api_constants.dart';

import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/shared/widgets/dashboard/ui_components.dart';
import 'package:home_care/features/reports/presentation/widgets/audit_dialog_helpers.dart';
import 'package:home_care/features/reports/presentation/widgets/freeze_account_dialog.dart';
import 'package:home_care/features/reports/presentation/widgets/manage_admin_roles_dialog.dart';

class DashboardAuditScreen extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;
  final String role;

  const DashboardAuditScreen({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
    this.role = 'direktur',
  });

  @override
  State<DashboardAuditScreen> createState() => _DashboardAuditScreenState();
}

class _DashboardAuditScreenState extends State<DashboardAuditScreen> {
  String get kBaseUrl => ApiConstants.baseUrl;
  String get kApiBase => ApiConstants.apiBase;

  String get _url =>
      '$kApiBase/${widget.role}/dashboard/audit?range=${Uri.encodeComponent(widget.range)}';

  String get _freezeListUrl => '$kApiBase/direktur/freeze/users';
  String _freezeUrl(int userId) => '$kApiBase/direktur/freeze/users/$userId';
  String _unfreezeUrl(int userId) =>
      '$kApiBase/direktur/freeze/users/$userId/unfreeze';

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
  void didUpdateWidget(covariant DashboardAuditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range || oldWidget.role != widget.role) {
      setState(() => _future = _fetch());
    }
  }

  Future<Map<String, dynamic>> _fetch() async {
    final res = await ApiClient.get(
      '/${widget.role}/dashboard/audit',
      queryParams: {'range': widget.range},
    );

    if (res is Map && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data']);
    }
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return <String, dynamic>{};
  }

  Future<String> _token() async {
    final t = ((await StorageService.getToken()) ?? '').trim();
    if (t.isEmpty) throw Exception('Token kosong. Silakan login ulang.');
    return t;
  }

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

  Future<void> _exportAudit(Map<String, dynamic> data) async {
    try {
      final kpi =
          (data['kpi'] is Map)
              ? Map<String, dynamic>.from(data['kpi'])
              : <String, dynamic>{};

      final List logsRaw = (data['logs'] is List) ? data['logs'] : const [];

      final logs =
          logsRaw.map((e) {
            final m =
                (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{};
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

    final List list =
        (data is Map && data['data'] is List)
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
    required bool freeze,
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
        final msg =
            (body is Map && body['message'] != null)
                ? body['message'].toString()
                : 'HTTP ${res.statusCode}';
        throw Exception(msg);
      } catch (_) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    }
  }

  Future<void> _openFreezePopup() async {
    final token = await _token();
    if (!mounted) return;
    await FreezeAccountDialog.show(
      context: context,
      token: token,
      isDesktop: widget.isDesktop,
      fetchFreezeUsers: _fetchFreezeUsers,
      doFreezeAction: _doFreezeAction,
      toast: _toast,
    );
  }

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
    final data = (body is Map) ? body['data'] : null;
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
        final msg =
            (body is Map && body['message'] != null)
                ? body['message'].toString()
                : 'HTTP ${res.statusCode}';
        throw Exception(msg);
      } catch (_) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    }
  }

  Future<void> _openKelolaAdminPopup() async {
    final token = await _token();
    if (!mounted) return;
    await ManageAdminRolesDialog.show(
      context: context,
      token: token,
      isDesktop: widget.isDesktop,
      fetchAdminUsers: _fetchAdminUsers,
      fetchRoles: _fetchRoles,
      updateUserRole: _updateUserRole,
      toast: _toast,
    );
  }

  @override
  Widget build(BuildContext context) {

    final cols = widget.isDesktop ? 3 : (widget.isTablet ? 2 : 1);

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final isLoading =
            snap.connectionState == ConnectionState.waiting &&
            snap.data == null;
        final isError = snap.hasError && snap.data == null;

        final data = snap.data ?? {};
        final kpi =
            (data['kpi'] is Map)
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
              child:
                  (logs.isEmpty)
                      ? const _EmptyState(
                        text: 'Belum ada audit log pada range ini.',
                      )
                      : Column(
                        children:
                            logs.take(10).map((e) {
                              final m =
                                  (e is Map)
                                      ? Map<String, dynamic>.from(e)
                                      : <String, dynamic>{};

                              final title = (m['title'] ?? 'Audit').toString();
                              final desc = (m['desc'] ?? '-').toString();
                              final time = (m['time'] ?? '-').toString();

                              final iconName =
                                  (m['icon'] ?? 'security').toString();
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

typedef _DialogEmpty = DialogEmpty;
typedef _DialogError = DialogError;
typedef _EmptyState = EmptyStateBox;
typedef _AuditRow = AuditRowCard;

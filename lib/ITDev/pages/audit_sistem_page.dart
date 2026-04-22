import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/ui_components.dart';

class AuditSistemPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const AuditSistemPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<AuditSistemPage> createState() => _AuditSistemPageState();
}

class _AuditSistemPageState extends State<AuditSistemPage> {
  static const String kBaseUrl = 'http://192.168.1.5:8000';
  String get kApiBase => '$kBaseUrl/api';

  // ===== Filters =====
  String _risk = 'all'; // all|low|medium|high
  String _action = '';
  String _q = '';
  Timer? _debounce;

  int _perPage = 20;
  int _page = 1;
  String _formatWaktuID(dynamic v) {
    final s = _s(v, '');
    if (s.isEmpty) return '-';
    try {
      final dt = DateTime.tryParse(s);
      if (dt == null) return s;
      return DateFormat("dd MMMM yyyy • HH:mm", 'id_ID').format(dt.toLocal());
    } catch (_) {
      return s;
    }
  }

  final _qC = TextEditingController();
  final _actionC = TextEditingController();

  Future<Map<String, dynamic>>? _future;

  // =========================
  // NORMALIZE (ANTI DROPDOWN CRASH)
  // =========================
  String _normalizeRisk(String v) {
    final x = v.trim().toLowerCase();
    const allowed = {'all', 'low', 'medium', 'high'};
    return allowed.contains(x) ? x : 'all';
  }

  void _onRealtimeChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _q = _qC.text.trim();
      _action = _actionC.text.trim();
      _page = 1;
      _debounce = Timer(const Duration(milliseconds: 350), () {
        _q = _qC.text.trim();
        _action = _actionC.text.trim();
        _page = 1;
        _reload();
      });

      if (!mounted) return;

      // ❗️PASTIKAN BUKAN async di dalam setState
      setState(() {
        _future = _fetch();
      });
    });
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _fetch(); // tetap tidak await
    });
  }

  @override
  void initState() {
    super.initState();
    _qC.addListener(_onRealtimeChanged);
    _actionC.addListener(_onRealtimeChanged);
    _future = _fetch();
  }

  @override
  void didUpdateWidget(covariant AuditSistemPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      _page = 1;
      setState(() => _future = _fetch());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qC.removeListener(_onRealtimeChanged);
    _actionC.removeListener(_onRealtimeChanged);
    _qC.dispose();
    _actionC.dispose();
    super.dispose();
  }

  // =========================
  // FETCH
  // =========================
  String _buildUrl() {
    final qp = <String, String>{
      'range': widget.range,
      'per_page': '$_perPage',
      'page': '$_page',
    };

    final riskNormalized = _normalizeRisk(_risk);
    if (riskNormalized != 'all') qp['risk'] = riskNormalized;

    if (_action.trim().isNotEmpty) qp['action'] = _action.trim();
    if (_q.trim().isNotEmpty) qp['q'] = _q.trim();

    return Uri.parse(
      '$kApiBase/it/audit',
    ).replace(queryParameters: qp).toString();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
            .trim();

    if (token.isEmpty) {
      throw Exception('Token kosong. Silakan login ulang.');
    }

    final res = await http.get(
      Uri.parse(_buildUrl()),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      if (body is Map && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data']);
      }
      return Map<String, dynamic>.from(body as Map);
    }

    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  // =========================
  // HELPERS
  // =========================
  String _s(dynamic v, [String fb = '']) {
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

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF16A34A);
    }
  }

  String _riskLabel(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return 'HIGH';
      case 'medium':
        return 'MED';
      default:
        return 'LOW';
    }
  }

  String _prettyJson(dynamic v) {
    try {
      if (v == null) return '-';
      if (v is String) {
        final decoded = jsonDecode(v);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(v);
    } catch (_) {
      return v?.toString() ?? '-';
    }
  }

  void _applyFilters() {
    _q = _qC.text.trim();
    _action = _actionC.text.trim();
    _page = 1;
    setState(() => _future = _fetch());
  }

  void _resetFilters() {
    _debounce?.cancel();
    _risk = 'all';
    _action = '';
    _q = '';
    _qC.text = '';
    _actionC.text = '';
    _page = 1;
    setState(() => _future = _fetch());
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final isLoading =
            snap.connectionState == ConnectionState.waiting &&
            snap.data == null;
        final isError = snap.hasError && snap.data == null;

        final data = snap.data ?? {};
        final rangeLabel = _s(data['range'], widget.range);

        final itemsObj = (data['items'] is Map)
            ? Map<String, dynamic>.from(data['items'])
            : <String, dynamic>{};

        final List items = (itemsObj['data'] is List)
            ? itemsObj['data']
            : const [];

        final currentPage = _i(itemsObj['current_page']);
        final lastPage = _i(itemsObj['last_page']);
        final total = _i(itemsObj['total']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Audit Sistem',
              subtitle: 'Read-only • filter teknis • $rangeLabel',
            ),
            const SizedBox(height: 12),

            if (isLoading)
              const _LoadingCardX(title: 'Audit Sistem')
            else if (isError)
              _ErrorCardX(
                title: 'Audit Sistem',
                message: snap.error.toString(),
                onRetry: () {
                  if (!mounted) return;
                  setState(() => _future = _fetch());
                },
              ),

            // ===== FILTER =====
            XCard(
              title: 'Filter',
              subtitle: 'Action • Risk • Search (title/desc/ip/ua).',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            flex: isWide ? 1 : 2,
                            child: _RiskDropdown(
                              value: _normalizeRisk(_risk),
                              fullWidth: true,
                              onChanged: (v) {
                                _debounce?.cancel();
                                setState(() {
                                  _risk = _normalizeRisk(v);
                                  _page = 1;
                                  _future = _fetch();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlineButtonX(
                            icon: Icons.refresh_rounded,
                            label: 'Reset',
                            onTap: _resetFilters,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (isWide) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _actionC,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  prefixIcon: Icon(
                                    Icons.bolt_rounded,
                                    size: 20,
                                  ),
                                  hintText: 'action (contoh: login.failed)',
                                  hintStyle: TextStyle(fontSize: 13),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _qC,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                  ),
                                  hintText: 'search…',
                                  hintStyle: TextStyle(fontSize: 13),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        TextField(
                          controller: _actionC,
                          decoration: const InputDecoration(
                            isDense: true,
                            prefixIcon: Icon(Icons.bolt_rounded, size: 20),
                            hintText: 'action (contoh: login.failed)',
                            hintStyle: TextStyle(fontSize: 13),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _qC,
                          decoration: const InputDecoration(
                            isDense: true,
                            prefixIcon: Icon(Icons.search_rounded, size: 20),
                            hintText: 'search…',
                            hintStyle: TextStyle(fontSize: 13),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ===== LIST =====
            XCard(
              title: 'Audit Logs',
              subtitle:
                  'Total: $total • page ${currentPage == 0 ? 1 : currentPage}/${lastPage == 0 ? 1 : lastPage}',
              child: items.isEmpty
                  ? const _EmptyState(
                      text: 'Belum ada audit log pada range ini.',
                    )
                  : Column(
                      children: [
                        ...items.map((e) {
                          final m = Map<String, dynamic>.from(e as Map);

                          final action = _s(m['action'], 'audit');
                          final title = _s(m['title'], action);
                          final desc = _s(m['description'], '-');
                          final risk = _s(m['risk_level'], 'low');
                          final timeRaw = _s(
                            m['created_at'],
                            _s(m['time'], '-'),
                          );
                          final time = _formatWaktuID(timeRaw);
                          final ip = _s(m['ip'], '-');
                          final ua = _s(m['user_agent'], '-');

                          return _AuditRow(
                            title: title,
                            desc:
                                '$desc\nIP: $ip • UA: ${ua.length > 60 ? ua.substring(0, 60) + '…' : ua}',
                            time: time,
                            risk: _riskLabel(risk),
                            color: _riskColor(risk),
                            onTap: () => _showDetailDialog(m),
                          );
                        }).toList(),
                        const SizedBox(height: 10),
                        _PaginationBarNative(
                          page: _page,
                          canPrev: _page > 1,
                          canNext: lastPage == 0 ? false : _page < lastPage,
                          onPrev: () {
                            if (_page <= 1) return;
                            setState(() {
                              _page -= 1;
                              _future = _fetch();
                            });
                          },
                          onNext: () {
                            if (lastPage != 0 && _page >= lastPage) return;
                            setState(() {
                              _page += 1;
                              _future = _fetch();
                            });
                          },
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDetailDialog(Map<String, dynamic> m) async {
    final action = _s(m['action'], '-');
    final risk = _s(m['risk_level'], 'low');
    final time = _formatWaktuID(_s(m['created_at'], '-'));
    final title = _s(m['title'], action);
    final desc = _s(m['description'], '-');
    final ip = _s(m['ip'], '-');
    final ua = _s(m['user_agent'], '-');
    final entityType = _s(m['entity_type'], '-');
    final entityId = m['entity_id'];

    final before = _prettyJson(m['before']);
    final after = _prettyJson(m['after']);

    final c = _riskColor(risk);

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: c.withOpacity(.12),
                  border: Border.all(color: c.withOpacity(.25)),
                ),
                child: Text(
                  _riskLabel(risk),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: c,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('Action', action),
                  _kv('Time', time),
                  _kv('Entity', '$entityType • ${entityId ?? '-'}'),
                  _kv('IP', ip),
                  _kv('User-Agent', ua),
                  const SizedBox(height: 10),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Before',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  _jsonBox(before),
                  const SizedBox(height: 12),
                  const Text(
                    'After',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  _jsonBox(after),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _jsonBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.2,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}

// =========================
// Filter widget
// =========================
class _RiskDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool fullWidth;

  const _RiskDropdown({
    required this.value,
    required this.onChanged,
    this.fullWidth = false,
  });

  static const _allowed = ['all', 'low', 'medium', 'high'];

  @override
  Widget build(BuildContext context) {
    final safeValue = _allowed.contains(value) ? value : 'all';

    return SizedBox(
      width: fullWidth ? double.infinity : 170,
      child: DropdownButtonFormField<String>(
        value: safeValue,
        decoration: const InputDecoration(
          isDense: true,
          prefixIcon: Icon(Icons.shield_outlined, size: 20),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: const [
          DropdownMenuItem(value: 'all', child: Text('Risk: Semua')),
          DropdownMenuItem(value: 'low', child: Text('Risk: Low')),
          DropdownMenuItem(value: 'medium', child: Text('Risk: Medium')),
          DropdownMenuItem(value: 'high', child: Text('Risk: High')),
        ],
        onChanged: (v) => onChanged(v ?? 'all'),
      ),
    );
  }
}

class _PaginationBarNative extends StatelessWidget {
  final int page;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _PaginationBarNative({
    required this.page,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: canPrev ? onPrev : null,
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Prev'),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            color: const Color(0xFFF8FAFC),
          ),
          child: Text(
            'Page $page',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontSize: 12.2,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: canNext ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
          label: const Text('Next'),
        ),
      ],
    );
  }
}

// =========================
// List row & empty
// =========================
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
  final String risk;
  final Color color;
  final VoidCallback onTap;

  const _AuditRow({
    required this.title,
    required this.desc,
    required this.time,
    required this.risk,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                color: c.withOpacity(.12),
                border: Border.all(color: c.withOpacity(.25)),
              ),
              child: Icon(Icons.policy_outlined, color: c),
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
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: c.withOpacity(.12),
                          border: Border.all(color: c.withOpacity(.25)),
                        ),
                        child: Text(
                          risk,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: c,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                      fontSize: 12.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      fontSize: 12.2,
                    ),
                  ),
                ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: const [
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
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
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
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

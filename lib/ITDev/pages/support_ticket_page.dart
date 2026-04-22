import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/ui_components.dart';

// =============================================================
// PAGE (IT SUPPORT TICKETS)
// =============================================================
class SupportTicketPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const SupportTicketPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<SupportTicketPage> createState() => _SupportTicketPageState();
}

class _SupportTicketPageState extends State<SupportTicketPage> {
  // ===== BASE URL PATTERN (SAMA PERSIS SEPERTI AUDIT) =====
  static const String kBaseUrl = 'http://192.168.1.5:8000';
  String get kApiBase => '$kBaseUrl/api';

  // ===== Filters =====
  String _status = 'all'; // all|open|in_progress|solved|closed
  String _priority = 'all'; // all|low|medium|high
  String _category = 'all'; // all|bug|error|performance|access|other
  String _q = '';

  Timer? _debounce;

  int _perPage = 15;
  int _page = 1;

  final _qC = TextEditingController();
  final _notesC = TextEditingController();

  Future<Map<String, dynamic>>? _future;

  int? _myUserId; // untuk assign ke saya
  SupportTicket? _selected;

  // =========================
  // NORMALIZE (ANTI DROPDOWN CRASH)
  // =========================
  String _normalizeStatus(String v) {
    final x = v.trim().toLowerCase();
    const allowed = {'all', 'open', 'in_progress', 'solved', 'closed'};
    return allowed.contains(x) ? x : 'all';
  }

  String _normalizePriority(String v) {
    final x = v.trim().toLowerCase();
    const allowed = {'all', 'low', 'medium', 'high'};
    return allowed.contains(x) ? x : 'all';
  }

  String _normalizeCategory(String v) {
    final x = v.trim().toLowerCase();
    const allowed = {'all', 'bug', 'error', 'performance', 'access', 'other'};
    return allowed.contains(x) ? x : 'all';
  }

  void _onRealtimeChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _q = _qC.text.trim();
      _page = 1;
      _reload();
    });
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _fetchList();
    });
  }

  @override
  void initState() {
    super.initState();
    _qC.addListener(_onRealtimeChanged);
    _future = _bootstrap(); // ambil /me lalu list
  }

  @override
  void didUpdateWidget(covariant SupportTicketPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      _page = 1;
      setState(() {
  _future = _fetchList();
});
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _qC.removeListener(_onRealtimeChanged);
    _qC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  // =========================
  // AUTH / HEADER
  // =========================
  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
            .trim();
    if (token.isEmpty) throw Exception('Token kosong. Silakan login ulang.');
    return token;
  }

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // =========================
  // BOOTSTRAP -> ambil /me buat user id IT (assign)
  // =========================
  Future<Map<String, dynamic>> _bootstrap() async {
    final token = await _token();

    final res = await http.get(
      Uri.parse('$kApiBase/me'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body);

    // fleksibel: {data:{user:{id}}} atau {user:{id}} atau {data:{id}}
    final data = (body is Map && body['data'] != null) ? body['data'] : body;
    final user = (data is Map && data['user'] != null) ? data['user'] : data;

    _myUserId = _i((user as Map)['id']);

    return _fetchList();
  }

  // =========================
  // FETCH LIST
  // =========================
  String _buildListUrl() {
    final qp = <String, String>{
      'range': widget.range, // optional
      'per_page': '$_perPage',
      'page': '$_page',
    };

    final st = _normalizeStatus(_status);
    final pr = _normalizePriority(_priority);
    final ct = _normalizeCategory(_category);

    if (st != 'all') qp['status'] = st;
    if (pr != 'all') qp['priority'] = pr;
    if (ct != 'all') qp['category'] = ct;
    if (_q.trim().isNotEmpty) qp['q'] = _q.trim();

    return Uri.parse(
      '$kApiBase/support-tickets',
    ).replace(queryParameters: qp).toString();
  }

  Future<Map<String, dynamic>> _fetchList() async {
    final token = await _token();

    final res = await http.get(
      Uri.parse(_buildListUrl()),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);

      // Controller kamu: { success, message, data: <paginator> }
      if (body is Map && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data']);
      }

      // fallback
      if (body is Map) return Map<String, dynamic>.from(body);

      return {'data': <dynamic>[]};
    }

    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  // =========================
  // ACTIONS (IT)
  // =========================
  Future<void> _setStatus(int ticketId, String status) async {
    final token = await _token();
    final res = await http.post(
      Uri.parse('$kApiBase/support-tickets/$ticketId/status'),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> _assignToMe(int ticketId) async {
    if ((_myUserId ?? 0) == 0) {
      throw Exception('User ID tidak ditemukan (me).');
    }

    final token = await _token();
    final res = await http.post(
      Uri.parse('$kApiBase/support-tickets/$ticketId/assign'),
      headers: _headers(token),
      body: jsonEncode({'assigned_to': _myUserId}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> _saveNotes(int ticketId) async {
    final token = await _token();
    final notes = _notesC.text.trim();

    debugPrint('🔵 Saving notes for ticket $ticketId');
    debugPrint('🔵 Notes content: $notes');

    final payload = {'it_notes': notes.isEmpty ? null : notes};

    debugPrint('🔵 Payload: ${jsonEncode(payload)}');

    final res = await http.post(
      Uri.parse('$kApiBase/support-tickets/$ticketId/it-notes'),
      headers: _headers(token),
      body: jsonEncode(payload),
    );

    debugPrint('🔵 Response status: ${res.statusCode}');
    debugPrint('🔵 Response body: ${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFFDC2626);
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'solved':
        return const Color(0xFF16A34A);
      case 'closed':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF334155);
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'bug':
        return Icons.bug_report_outlined;
      case 'error':
        return Icons.error_outline;
      case 'performance':
        return Icons.speed_outlined;
      case 'access':
        return Icons.lock_outline;
      default:
        return Icons.support_agent_outlined;
    }
  }

  String _titleOf(Map<String, dynamic> t) {
    final subject = _s(t['subject']);
    if (subject.isNotEmpty) return subject;
    final desc = _s(t['description']);
    if (desc.isNotEmpty) {
      return desc.length > 55 ? '${desc.substring(0, 55)}…' : desc;
    }
    return '(tanpa judul)';
  }

  void _resetFilters() {
    _debounce?.cancel();
    _status = 'all';
    _priority = 'all';
    _category = 'all';
    _q = '';
    _qC.text = '';
    _page = 1;
    _selected = null;
    _notesC.text = '';
    setState(() {
  _future = _fetchList();
});
  }

  // ===== parse paginator (FIX UTAMA) =====
  Map<String, dynamic> _asPager(Map<String, dynamic> data) {
    if (data['items'] is Map) return Map<String, dynamic>.from(data['items']);
    if (data['data'] is List && data.containsKey('current_page')) return data;
    if (data['data'] is Map) return Map<String, dynamic>.from(data['data']);
    if (data['data'] is List) return {'data': data['data']};
    return {'data': <dynamic>[]};
  }

  // ✅ CEK apakah ticket ini sudah di-assign ke orang lain
  bool _isAssignedToOther(Map<String, dynamic> t) {
    final assignedId = _i(t['assigned_to']);
    if (assignedId == 0) return false;
    return assignedId != (_myUserId ?? 0);
  }

  // ✅ CEK apakah ticket ini sudah di-assign ke saya
  bool _isAssignedToMe(Map<String, dynamic> t) {
    final assignedId = _i(t['assigned_to']);
    if (assignedId == 0) return false;
    return assignedId == (_myUserId ?? 0);
  }

  // ✅ FIXED: Open Detail dengan Proper Async Handling
  Future<void> _openDetail(Map<String, dynamic> t) async {
    final id = _i(t['id']);

    // ✅ PROTEKSI: Kalau ticket sudah di-assign ke IT lain, tidak bisa dibuka
    if (_isAssignedToOther(t)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ticket ini sedang ditangani oleh ${_s(t['assignee_name'], 'IT lain')}',
          ),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
      return;
    }

    _selected = SupportTicket.fromMap(t);
    _notesC.text = _s(t['it_notes'], '');

    if (!widget.isDesktop) {
      // ✅ CRITICAL: Simpan context di variabel lokal SEBELUM showModalBottomSheet
      final scaffoldContext = context;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _TicketDetailSheet(
          ticket: t,
          statusColor: _statusColor,
          categoryIcon: _categoryIcon,
          notesCtrl: _notesC,
          myUserId: _myUserId ?? 0,

          // ✅ FIX: SYNC CALLBACK (tidak async), tapi tetap jalan async via then/catchError
          onAssignMe: () {
            Navigator.of(sheetContext).pop();
            Future.delayed(const Duration(milliseconds: 100)).then((_) {
              if (!mounted) return;

              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Mengassign ticket...'),
                    ],
                  ),
                  duration: Duration(seconds: 1),
                ),
              );

              _assignToMe(id)
                  .then((_) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text('✅ Ticket di-assign ke kamu'),
                          ],
                        ),
                        backgroundColor: Color(0xFF10B981),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    if (mounted) setState(() {
  _future = _fetchList();
});
                  })
                  .catchError((e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('❌ Gagal assign: $e')),
                          ],
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  });
            });
          },

          onSaveNotes: () {
            Navigator.of(sheetContext).pop();
            Future.delayed(const Duration(milliseconds: 100)).then((_) {
              if (!mounted) return;

              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Menyimpan notes...'),
                    ],
                  ),
                  duration: Duration(seconds: 1),
                ),
              );

              _saveNotes(id)
                  .then((_) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text('✅ IT notes tersimpan'),
                          ],
                        ),
                        backgroundColor: Color(0xFF10B981),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    if (mounted) setState(() {
  _future = _fetchList();
});
                  })
                  .catchError((e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('❌ Gagal simpan: $e')),
                          ],
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  });
            });
          },

          onSetStatus: (st) {
            Navigator.of(sheetContext).pop();
            Future.delayed(const Duration(milliseconds: 100)).then((_) {
              if (!mounted) return;

              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Mengubah status ke $st...'),
                    ],
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );

              _setStatus(id, st)
                  .then((_) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text('✅ Status → $st'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    if (mounted) setState(() {
  _future = _fetchList();
});
                  })
                  .catchError((e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(scaffoldContext).clearSnackBars();
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('❌ Gagal ubah status: $e')),
                          ],
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  });
            });
          },
        ),
      );
    } else {
      if (mounted) setState(() {});
    }
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

        final raw = snap.data ?? {};
        final pager = _asPager(raw);

        final List items = (pager['data'] is List) ? pager['data'] : const [];
        final currentPage = _i(pager['current_page'] ?? _page);
        final lastPage = _i(pager['last_page'] ?? 1);
        final total = _i(pager['total'] ?? items.length);

        final selectedMap = _selected?.raw;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Support Ticket',
              subtitle:
                  'IT Inbox • ${widget.range} • open → in_progress → solved/closed',
            ),
            const SizedBox(height: 12),

            if (isLoading)
              const _LoadingCardX(title: 'Support Ticket')
            else if (isError)
              _ErrorCardX(
                title: 'Support Ticket',
                message: snap.error.toString(),
                onRetry: () {
                  if (!mounted) return;
                  setState(() => _future = _bootstrap());
                },
              ),

            // ===== FILTER =====
            XCard(
              title: 'Filter',
              subtitle:
                  'Status • Priority • Category • Search (subject/desc/user).',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  final isMid = constraints.maxWidth > 640;

                  final ddW = isWide
                      ? 210.0
                      : (isMid ? 200.0 : double.infinity);

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: ddW,
                        child: _StatusDropdown(
                          value: _normalizeStatus(_status),
                          onChanged: (v) {
                            _debounce?.cancel();
                            setState(() {
                              _status = _normalizeStatus(v);
                              _page = 1;
                              _future = _fetchList();
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: ddW,
                        child: _PriorityDropdown(
                          value: _normalizePriority(_priority),
                          onChanged: (v) {
                            _debounce?.cancel();
                            setState(() {
                              _priority = _normalizePriority(v);
                              _page = 1;
                              _future = _fetchList();
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: ddW,
                        child: _CategoryDropdown(
                          value: _normalizeCategory(_category),
                          onChanged: (v) {
                            _debounce?.cancel();
                            setState(() {
                              _category = _normalizeCategory(v);
                              _page = 1;
                              _future = _fetchList();
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: isWide ? 340 : (isMid ? 300 : double.infinity),
                        child: TextField(
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
                      ),
                      OutlineButtonX(
                        icon: Icons.refresh_rounded,
                        label: 'Reset',
                        onTap: _resetFilters,
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ===== CONTENT (LIST + DETAIL)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: widget.isDesktop ? 6 : 12,
                  child: XCard(
                    title: 'Tickets',
                    subtitle:
                        'Total: $total • page ${currentPage == 0 ? 1 : currentPage}/${lastPage == 0 ? 1 : lastPage}',
                    child: items.isEmpty
                        ? const _EmptyState(
                            text: 'Belum ada ticket sesuai filter.',
                          )
                        : Column(
                            children: [
                              ...items.map((e) {
                                final m = Map<String, dynamic>.from(e as Map);
                                final id = _i(m['id']);
                                final status = _s(m['status'], 'open');
                                final pr = _s(m['priority'], 'medium');
                                final cat = _s(m['category'], 'bug');

                                final reporter = _s(
                                  m['reporter_name'],
                                  _s(
                                    m['user_name'],
                                    _s(
                                      m['username'],
                                      'user_id=${_i(m['user_id'])}',
                                    ),
                                  ),
                                );
                                final assignee = _s(
                                  m['assignee_name'],
                                  _s(m['assigned_to_name'], ''),
                                );

                                final c = _statusColor(status);
                                final isSelected =
                                    widget.isDesktop &&
                                    selectedMap != null &&
                                    _i(selectedMap['id']) == id;

                                final isAssignedOther = _isAssignedToOther(m);
                                final isAssignedMe = _isAssignedToMe(m);

                                return _TicketRow(
                                  title: _titleOf(m),
                                  subtitle:
                                      '$reporter${assignee.isEmpty ? '' : ' • assigned: $assignee'}',
                                  status: status,
                                  priority: pr,
                                  category: cat,
                                  color: c,
                                  icon: _categoryIcon(cat),
                                  selected: isSelected,
                                  isAssignedToOther: isAssignedOther,
                                  isAssignedToMe: isAssignedMe,
                                  assigneeName: assignee,
                                  onTap: () => _openDetail(m),
                                );
                              }).toList(),
                              const SizedBox(height: 10),
                              _PaginationBarNative(
                                page: _page,
                                canPrev: _page > 1,
                                canNext: lastPage == 0
                                    ? false
                                    : _page < lastPage,
                                onPrev: () {
                                  if (_page <= 1) return;
                                  setState(() {
                                    _page -= 1;
                                    _future = _fetchList();
                                  });
                                },
                                onNext: () {
                                  if (lastPage != 0 && _page >= lastPage) {
                                    return;
                                  }
                                  setState(() {
                                    _page += 1;
                                    _future = _fetchList();
                                  });
                                },
                              ),
                            ],
                          ),
                  ),
                ),

                if (widget.isDesktop) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: XCard(
                      title: 'Detail Ticket',
                      subtitle: selectedMap == null
                          ? 'Pilih ticket di kiri.'
                          : 'Aksi IT: assign, status, notes.',
                      child: selectedMap == null
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: Text(
                                'Klik salah satu ticket untuk melihat detail.',
                              ),
                            )
                          : _TicketDetailPanel(
                              ticket: selectedMap,
                              statusColor: _statusColor,
                              categoryIcon: _categoryIcon,
                              notesCtrl: _notesC,
                              myUserId: _myUserId ?? 0,

                              onAssignMe: () {
                                _assignToMe(_i(selectedMap['id']))
                                    .then((_) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ticket di-assign ke kamu.',
                                          ),
                                        ),
                                      );
                                      setState(() {
  _future = _fetchList();
});
                                    })
                                    .catchError((e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Gagal assign: $e'),
                                        ),
                                      );
                                    });
                              },

                              // ✅ FIXED: SYNC callback (bukan async)
                              onSaveNotes: () {
                                _saveNotes(_i(selectedMap['id']))
                                    .then((_) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('IT notes tersimpan.'),
                                        ),
                                      );
                                      setState(() {
  _future = _fetchList();
});
                                    })
                                    .catchError((e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gagal simpan notes: $e',
                                          ),
                                        ),
                                      );
                                    });
                              },

                              // ✅ FIXED: SYNC callback (bukan async)
                              onSetStatus: (st) {
                                _setStatus(_i(selectedMap['id']), st)
                                    .then((_) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Status → $st')),
                                      );
                                      setState(() {
  _future = _fetchList();
});
                                    })
                                    .catchError((e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Gagal ubah status: $e',
                                          ),
                                        ),
                                      );
                                    });
                              },
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

// =============================================================
// Tiny model wrapper (biar gampang simpan selected)
// =============================================================
class SupportTicket {
  final Map<String, dynamic> raw;
  SupportTicket(this.raw);
  factory SupportTicket.fromMap(Map<String, dynamic> m) => SupportTicket(m);
}

// =============================================================
// Widgets - TICKET ROW (✅ DENGAN ASSIGN INDICATOR!)
// =============================================================
class _TicketRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String priority;
  final String category;
  final Color color;
  final IconData icon;
  final bool selected;
  final bool isAssignedToOther;
  final bool isAssignedToMe;
  final String assigneeName;
  final VoidCallback onTap;

  const _TicketRow({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.priority,
    required this.category,
    required this.color,
    required this.icon,
    required this.selected,
    required this.isAssignedToOther,
    required this.isAssignedToMe,
    required this.assigneeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color;
    final isLocked = isAssignedToOther;

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked
                  ? const Color(0xFF94A3B8)
                  : (selected ? c.withOpacity(.35) : const Color(0xFFE2E8F0)),
              width: isLocked ? 2 : 1,
            ),
            color: isLocked
                ? const Color(0xFFF1F5F9)
                : (selected ? c.withOpacity(.06) : const Color(0xFFF8FAFC)),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: c.withOpacity(.12),
                  border: Border.all(color: c.withOpacity(.25)),
                ),
                child: Icon(
                  isLocked ? Icons.lock_outlined : icon,
                  color: c,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
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
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: c.withOpacity(.12),
                              border: Border.all(color: c.withOpacity(.25)),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: c,
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                        fontSize: 11.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniChip(
                          label: priority,
                          icon: Icons.priority_high_rounded,
                        ),
                        _MiniChip(
                          label: category,
                          icon: Icons.category_outlined,
                        ),
                        if (isAssignedToMe)
                          _AssignBadge(
                            label: 'Assigned to You',
                            color: const Color(0xFF16A34A),
                            icon: Icons.person_outlined,
                          ),
                        if (isAssignedToOther && assigneeName.isNotEmpty)
                          _AssignBadge(
                            label: 'By $assigneeName',
                            color: const Color(0xFF64748B),
                            icon: Icons.lock_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _AssignBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(.12),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MiniChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF475569)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                color: Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Detail Panel (desktop) =====
class _TicketDetailPanel extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final Color Function(String status) statusColor;
  final IconData Function(String cat) categoryIcon;
  final TextEditingController notesCtrl;
  final int myUserId;

  final VoidCallback onAssignMe;
  final VoidCallback onSaveNotes;
  final void Function(String status) onSetStatus;

  const _TicketDetailPanel({
    required this.ticket,
    required this.statusColor,
    required this.categoryIcon,
    required this.notesCtrl,
    required this.myUserId,
    required this.onAssignMe,
    required this.onSaveNotes,
    required this.onSetStatus,
  });

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

  @override
  Widget build(BuildContext context) {
    final status = _s(ticket['status'], 'open');
    final priority = _s(ticket['priority'], 'medium');
    final category = _s(ticket['category'], 'bug');
    final reporter = _s(
      ticket['reporter_name'],
      _s(ticket['username'], _s(ticket['user_name'], '-')),
    );
    final subject = _s(ticket['subject'], '(tanpa subject)');
    final desc = _s(ticket['description'], '-');
    final assignee = _s(
      ticket['assignee_name'],
      _s(ticket['assigned_to_name'], ''),
    );
    final c = statusColor(status);

    final assignedId = _i(ticket['assigned_to']);
    final isAssigned = assignedId != 0;
    final isAssignedToMe = assignedId == myUserId;
    final isAssignedToOther = isAssigned && !isAssignedToMe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: c.withOpacity(.12),
                border: Border.all(color: c.withOpacity(.25)),
              ),
              child: Icon(categoryIcon(category), color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by $reporter${assignee.isEmpty ? '' : ' • assigned: $assignee'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: c.withOpacity(.12),
                  border: Border.all(color: c.withOpacity(.25)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: c,
                    fontSize: 10.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (isAssignedToOther)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFFEF3C7),
              border: Border.all(color: const Color(0xFFFBBF24)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outlined,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ticket ini sedang ditangani oleh $assignee',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (isAssignedToMe)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFDCFCE7),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.check_circle_outlined,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ticket ini sedang kamu tangani',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF14532D),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        _InfoLine(label: 'Category', value: category),
        _InfoLine(label: 'Priority', value: priority),
        const SizedBox(height: 10),

        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            color: const Color(0xFFF8FAFC),
          ),
          child: Text(desc),
        ),

        const SizedBox(height: 12),

        const Text('IT Notes', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        TextField(
          controller: notesCtrl,
          maxLines: 4,
          enabled: !isAssignedToOther,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: 'catatan teknis / root cause / langkah fix / link log…',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),

        const SizedBox(height: 12),

        if (!isAssigned)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlineButtonX(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Assign ke Saya',
                onTap: onAssignMe,
              ),
            ],
          ),

        if (isAssignedToMe)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlineButtonX(
                icon: Icons.save_outlined,
                label: 'Simpan Notes',
                onTap: onSaveNotes,
              ),
            ],
          ),

        if (isAssignedToMe) const SizedBox(height: 12),

        if (isAssignedToMe)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlineButtonX(
                icon: Icons.sync_alt_rounded,
                label: 'In Progress',
                onTap: () => onSetStatus('in_progress'),
              ),
              OutlineButtonX(
                icon: Icons.check_circle_outline,
                label: 'Solved',
                onTap: () => onSetStatus('solved'),
              ),
              OutlineButtonX(
                icon: Icons.lock_outline,
                label: 'Closed',
                onTap: () => onSetStatus('closed'),
              ),
              OutlineButtonX(
                icon: Icons.restart_alt_rounded,
                label: 'Re-Open',
                onTap: () => onSetStatus('open'),
              ),
            ],
          ),
      ],
    );
  }
}

// ===== Detail Sheet (mobile) - ✅ FIXED! =====
class _TicketDetailSheet extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final Color Function(String status) statusColor;
  final IconData Function(String cat) categoryIcon;
  final TextEditingController notesCtrl;
  final int myUserId;

  final VoidCallback onAssignMe;
  final VoidCallback onSaveNotes;
  final void Function(String status) onSetStatus;

  const _TicketDetailSheet({
    required this.ticket,
    required this.statusColor,
    required this.categoryIcon,
    required this.notesCtrl,
    required this.myUserId,
    required this.onAssignMe,
    required this.onSaveNotes,
    required this.onSetStatus,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.60,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: _TicketDetailPanel(
                    ticket: ticket,
                    statusColor: statusColor,
                    categoryIcon: categoryIcon,
                    notesCtrl: notesCtrl,
                    myUserId: myUserId,
                    onAssignMe: onAssignMe,
                    onSaveNotes: onSaveNotes,
                    onSetStatus: onSetStatus,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Filter Widgets
class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.flag_outlined, size: 18),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      style: const TextStyle(fontSize: 12.5),
      selectedItemBuilder: (context) =>
          const ['Status: All', 'open', 'in_progress', 'solved', 'closed'].map((
            t,
          ) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Status: All')),
        DropdownMenuItem(value: 'open', child: Text('open')),
        DropdownMenuItem(value: 'in_progress', child: Text('in_progress')),
        DropdownMenuItem(value: 'solved', child: Text('solved')),
        DropdownMenuItem(value: 'closed', child: Text('closed')),
      ],
      onChanged: (v) => onChanged(v ?? 'all'),
    );
  }
}

class _PriorityDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _PriorityDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.priority_high_rounded, size: 18),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      style: const TextStyle(fontSize: 12.5),
      selectedItemBuilder: (context) =>
          const ['Priority: All', 'low', 'medium', 'high'].map((t) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Priority: All')),
        DropdownMenuItem(value: 'low', child: Text('low')),
        DropdownMenuItem(value: 'medium', child: Text('medium')),
        DropdownMenuItem(value: 'high', child: Text('high')),
      ],
      onChanged: (v) => onChanged(v ?? 'all'),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.category_outlined, size: 18),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      style: const TextStyle(fontSize: 12.5),
      selectedItemBuilder: (context) =>
          const [
            'Category: All',
            'bug',
            'error',
            'performance',
            'access',
            'other',
          ].map((t) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5),
              ),
            );
          }).toList(),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Category: All')),
        DropdownMenuItem(value: 'bug', child: Text('bug')),
        DropdownMenuItem(value: 'error', child: Text('error')),
        DropdownMenuItem(value: 'performance', child: Text('performance')),
        DropdownMenuItem(value: 'access', child: Text('access')),
        DropdownMenuItem(value: 'other', child: Text('other')),
      ],
      onChanged: (v) => onChanged(v ?? 'all'),
    );
  }
}

// Pagination / Empty / Loading / Error
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
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: canPrev ? onPrev : null,
          icon: const Icon(Icons.chevron_left_rounded, size: 18),
          label: const Text('Prev', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
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
              fontSize: 11.5,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: canNext ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded, size: 18),
          label: const Text('Next', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
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

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF475569),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

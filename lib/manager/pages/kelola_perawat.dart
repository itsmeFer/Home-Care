import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/ui_components.dart';

class KelolaPerawatPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;

  const KelolaPerawatPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  State<KelolaPerawatPage> createState() => _KelolaPerawatPageState();
}

class _KelolaPerawatPageState extends State<KelolaPerawatPage> {
  static const String kBaseUrl = 'http://192.168.1.6:8000';
  String get kApiBase => '$kBaseUrl/api';

  String get _perawatUrl => '$kApiBase/manager/perawat';
  String get _koordinatorUrl => '$kApiBase/manager/koordinator';
  void _popLoadingIfAny() {
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop(); // pastikan ini dipanggil hanya setelah showDialog loading
    }
  }

  Future<bool> _ensureKoordinatorLoaded() async {
    if (_koorOptions.isNotEmpty) return true;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      _koorOptions = await _fetchList(_koordinatorUrl);

      _popLoadingIfAny();
      return _koorOptions.isNotEmpty;
    } catch (e) {
      _popLoadingIfAny();
      _toastError('Gagal load koordinator', e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>>? _future;

  // search
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _q = '';

  // caches
  List<Map<String, dynamic>> _koorOptions = [];

  // ===== palette (nyambung tema manager)
  static const Color _cPrimary = Color(0xFF06B6D4); // cyan-500
  static const Color _cGreen = Color(0xFF22C55E);
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Color _cRed = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // =========================
  // AUTH + HELPERS
  // =========================
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
        .trim();
  }

  Map<String, dynamic> _map(dynamic v) =>
      (v is Map) ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(dynamic v) =>
      (v is List) ? v.map((e) => _map(e)).toList() : <Map<String, dynamic>>[];

  /// Baca list dari berbagai bentuk:
  /// - [ ... ]
  /// - {data: [ ... ]}
  /// - {data: {data: [ ... ]}} paginate
  /// - {items: [ ... ]} dll
  List<Map<String, dynamic>> _asList(dynamic body) {
    if (body is List) return _list(body);

    if (body is Map) {
      final data = body['data'];

      if (data is List) return _list(data);

      // paginate: data.data
      if (data is Map && data['data'] is List) {
        return _list(data['data']);
      }

      // fallback keys
      for (final k in ['items', 'rows', 'result', 'results']) {
        final v = body[k];
        if (v is List) return _list(v);
        if (v is Map && v['data'] is List) return _list(v['data']);
      }
    }

    return <Map<String, dynamic>>[];
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

  String _s(dynamic v, [String fallback = '-']) {
    if (v == null) return fallback;
    final t = v.toString().trim();
    return t.isEmpty ? fallback : t;
  }

  // =========================
  // FETCH
  // =========================
  Future<List<Map<String, dynamic>>> _fetchList(String url) async {
    final token = await _getToken();
    if (token.isEmpty) throw Exception('Token kosong. Silakan login ulang.');

    final res = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body);
    return _asList(body);
  }

  /// Build URI dengan beberapa kemungkinan query param:
  /// backend kadang pakai q / search / keyword
  Uri _buildPerawatUri() {
    final q = _q.trim();
    if (q.isEmpty) return Uri.parse(_perawatUrl);

    // ✅ pakai q dulu (paling umum)
    return Uri.parse(_perawatUrl).replace(queryParameters: {'q': q});
  }

  Future<Map<String, dynamic>> _fetch() async {
    final token = await _getToken();
    if (token.isEmpty) throw Exception('Token kosong. Silakan login ulang.');

    // 1) coba pakai q
    var uri = _buildPerawatUri();
    var res = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    // 2) fallback kalau backend ternyata pakai "search"
    if (res.statusCode == 200 && _q.trim().isNotEmpty) {
      // ok
    } else if (_q.trim().isNotEmpty) {
      // kalau backend 422/400 karena param q, coba search
      final uri2 = Uri.parse(
        _perawatUrl,
      ).replace(queryParameters: {'search': _q.trim()});
      final res2 = await http.get(
        uri2,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res2.statusCode >= 200 && res2.statusCode < 300) {
        uri = uri2;
        res = res2;
      } else {
        // coba keyword
        final uri3 = Uri.parse(
          _perawatUrl,
        ).replace(queryParameters: {'keyword': _q.trim()});
        final res3 = await http.get(
          uri3,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (res3.statusCode >= 200 && res3.statusCode < 300) {
          uri = uri3;
          res = res3;
        }
      }
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body);

    // 1) normal list / paginate
    var list = _asList(body);

    // 2) fallback kalau format dashboard: {data:{leaderboard:[...]}}
    if (list.isEmpty && body is Map && body['data'] is Map) {
      final d = Map<String, dynamic>.from(body['data']);
      if (d['leaderboard'] is List) {
        list = _list(d['leaderboard']);
      }
    }

    // preload koordinator options sekali
    if (_koorOptions.isEmpty) {
      try {
        _koorOptions = await _fetchList(_koordinatorUrl);
      } catch (_) {
        _koorOptions = [];
      }
    }

    // KPI sederhana dari list
    final total = list.length;

    // aktif/pending hanya valid kalau key tersedia.
    final aktif = list.where((e) {
      if (!e.containsKey('is_active')) return true; // fallback anggap aktif
      return (e['is_active'] == true || e['is_active'] == 1);
    }).length;

    final pending = list.where((e) {
      if (!e.containsKey('status_verifikasi')) return false;
      return _s(e['status_verifikasi']) == 'pending';
    }).length;

    // avg rating fleksibel
    double avgRating = 0;
    if (total > 0) {
      final sum = list.fold<double>(
        0,
        (a, b) => a + _toDouble(b['avg_rating_perawat'] ?? b['rating'] ?? 0),
      );
      avgRating = sum / total;
    }

    return {
      'items': list,
      'kpi': {
        'total': total,
        'aktif': aktif,
        'pending': pending,
        'avg_rating': avgRating,
      },
    };
  }

  void _reload() {
    final f = _fetch(); // jangan await di dalam setState
    if (!mounted) return;
    setState(() => _future = f);
  }

  // =========================
  // SEARCH (debounce)
  // =========================
  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), () {
      final next = v.trim();
      if (next == _q) return;
      setState(() {
        _q = next;
        _future = _fetch();
      });
    });
  }

  // =========================
  // FIELD PICKERS (fleksibel)
  // =========================
  String _pickName(Map<String, dynamic> m) =>
      _s(m['nama_lengkap'] ?? m['name'] ?? m['nama'], '-');

  String _pickKode(Map<String, dynamic> m) => _s(
    m['kode_perawat'] ?? m['kode'] ?? m['kode_nrs'] ?? m['kode_user'],
    '-',
  );

  String _pickPhone(Map<String, dynamic> m) =>
      _s(m['no_hp'] ?? m['phone'] ?? m['hp'] ?? m['telp'], '-');

  String _pickKoorName(Map<String, dynamic> m) => _s(
    m['nama_koordinator'] ??
        m['koordinator'] ??
        m['koordinator_nama'] ??
        (m['koordinator_obj'] is Map
            ? (m['koordinator_obj']['nama_lengkap'])
            : null),
    '—',
  );

  int? _pickKoorId(Map<String, dynamic> m) {
    if (m['koordinator_id'] == null) return null;
    final id = _toInt(m['koordinator_id']);
    return id == 0 ? null : id;
  }

  bool _isActive(Map<String, dynamic> m) {
    if (!m.containsKey('is_active')) return true; // fallback
    return (m['is_active'] == true || m['is_active'] == 1);
  }

  String _pickVerif(Map<String, dynamic> m) =>
      _s(m['status_verifikasi'], 'pending');

  double _rating(Map<String, dynamic> m) =>
      _toDouble(m['avg_rating_perawat'] ?? m['rating'] ?? m['avg_rating'] ?? 0);

  int _ratingCount(Map<String, dynamic> m) => _toInt(
    m['total_rating_perawat'] ??
        m['rating_count'] ??
        m['count_rating'] ??
        m['total_rating'] ??
        0,
  );

  Color _verifColor(String s) {
    switch (s) {
      case 'verified':
        return _cGreen;
      case 'rejected':
        return _cRed;
      default:
        return _cAmber; // pending
    }
  }

  // =========================
  // ACTIONS (assign/toggle)
  // =========================
  Future<void> _assignKoordinator(int perawatId, {int? currentKoorId}) async {
    // ✅ pastikan koordinator sudah ter-load (kalau belum, fetch + loading)
    final ok = await _ensureKoordinatorLoaded();
    if (!ok) return;

    if (_koorOptions.isEmpty) {
      _toastError('Koordinator kosong', 'Data koordinator belum tersedia.');
      return;
    }

    int? selected = currentKoorId;

    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (ctx, setLocal) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Koordinator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pilih koordinator untuk perawat ini.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            isExpanded: true,
                            value: selected,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('— Lepas koordinator (kosong) —'),
                              ),
                              ..._koorOptions.map((k) {
                                final id = _toInt(k['id']);
                                final name = _s(
                                  k['nama_lengkap'] ?? k['name'] ?? k['nama'],
                                  '-',
                                );
                                final kode = _s(k['kode_koordinator'], '');
                                return DropdownMenuItem<int?>(
                                  value: id,
                                  child: Text(
                                    kode.isEmpty ? name : '$name ($kode)',
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (v) => setLocal(() => selected = v),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                Future.microtask(
                                  () => _submitAssign(perawatId, selected),
                                );
                              },

                              child: const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPerawatAndAssignOneDialog(
    List<Map<String, dynamic>> items,
  ) async {
    // ✅ auto fetch koordinator kalau belum ada
    final ok = await _ensureKoordinatorLoaded();
    if (!ok) return;

    if (_koorOptions.isEmpty) {
      _toastError('Koordinator kosong', 'Data koordinator belum tersedia.');
      return;
    }

    int? selectedPerawatId;
    int? selectedKoorId;

    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (ctx, setLocal) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign Koordinator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pilih perawat dan koordinatornya, lalu simpan.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ====== Perawat dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedPerawatId,
                            hint: const Text('Pilih perawat...'),
                            items: items.take(200).map((p) {
                              final id = _toInt(p['id']);
                              final name = _pickName(p);
                              final kode = _pickKode(p);
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text('$name ($kode)'),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setLocal(() => selectedPerawatId = v),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ====== Koordinator dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            isExpanded: true,
                            value: selectedKoorId,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('— Lepas koordinator (kosong) —'),
                              ),
                              ..._koorOptions.map((k) {
                                final id = _toInt(k['id']);
                                final name = _s(
                                  k['nama_lengkap'] ?? k['name'] ?? k['nama'],
                                  '-',
                                );
                                final kode = _s(k['kode_koordinator'], '');
                                return DropdownMenuItem<int?>(
                                  value: id,
                                  child: Text(
                                    kode.isEmpty ? name : '$name ($kode)',
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (v) =>
                                setLocal(() => selectedKoorId = v),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (selectedPerawatId == null) {
                                  _toastError(
                                    'Validasi',
                                    'Pilih perawat dulu.',
                                  );
                                  return;
                                }
                                Navigator.of(ctx).pop();
                                Future.microtask(
                                  () => _submitAssign(
                                    selectedPerawatId!,
                                    selectedKoorId,
                                  ),
                                );
                              },

                              child: const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitAssign(int perawatId, int? koorId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = await _getToken();
      final res = await http.put(
        Uri.parse('$kApiBase/manager/perawat/$perawatId/assign-koordinator'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'koordinator_id': koorId}),
      );

      _popLoadingIfAny();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      _toastSuccess('Berhasil', 'Koordinator diperbarui.');
      _reload();
    } catch (e) {
      _popLoadingIfAny();
      _toastError('Gagal assign', e.toString());
    }
  }

  Future<void> _toggleActive(int perawatId, bool nextActive) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = await _getToken();
      final res = await http.patch(
        Uri.parse('$kApiBase/manager/perawat/$perawatId/toggle-active'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'is_active': nextActive}),
      );

      _popLoadingIfAny();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      _toastSuccess('Berhasil', 'Status aktif diperbarui.');
      _reload();
    } catch (e) {
      _popLoadingIfAny();
      _toastError('Gagal update status', e.toString());
    }
  }

  // =========================
  // TOAST
  // =========================
  void _toastSuccess(String title, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title • $msg'), backgroundColor: _cGreen),
    );
  }

  void _toastError(String title, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title • $msg'), backgroundColor: _cRed),
    );
  }

  // =========================
  // UI PIECES
  // =========================
  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Cari perawat (nama / kode / HP / koordinator)...',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlineButtonX(
            icon: Icons.refresh_outlined,
            label: 'Refresh',
            onTap: _reload,
          ),
        ],
      ),
    );
  }

  // list card (mobile/tablet)
  Widget _cardsList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const XCard(
        title: 'Daftar Perawat',
        subtitle: 'Belum ada data perawat pada pencarian ini.',
        child: _EmptyBox(text: 'Data kosong. Coba ubah kata kunci search.'),
      );
    }

    return XCard(
      title: 'Daftar Perawat',
      subtitle: 'Kelola koordinator, status aktif, dan performa rating.',
      child: Column(
        children: items.take(50).map((m) {
          final id = _toInt(m['id']);
          final name = _pickName(m);
          final kode = _pickKode(m);
          final phone = _pickPhone(m);
          final koor = _pickKoorName(m);
          final verif = _pickVerif(m);
          final active = _isActive(m);
          final r = _rating(m);
          final rc = _ratingCount(m);
          final koorId = _pickKoorId(m);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              color: const Color(0xFFF8FAFC),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    _StatusPill(text: verif, color: _verifColor(verif)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$kode • $phone',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Koordinator: $koor',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniInfo(
                      icon: Icons.star_rounded,
                      text: '${r.toStringAsFixed(2)}  ($rc)',
                      color: _cAmber,
                    ),
                    const SizedBox(width: 10),
                    _MiniInfo(
                      icon: active
                          ? Icons.verified_outlined
                          : Icons.block_outlined,
                      text: active ? 'Aktif' : 'Nonaktif',
                      color: active ? _cGreen : _cRed,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ActionChipX(
                      icon: Icons.swap_horiz_outlined,
                      label: 'Assign Koordinator',
                      onTap: () =>
                          _assignKoordinator(id, currentKoorId: koorId),
                    ),
                    ActionChipX(
                      icon: Icons.swap_horiz_outlined,
                      label: 'Assign Koordinator',
                      onTap: () {
                        _assignKoordinator(id, currentKoorId: koorId);
                      },
                    ),
                    ActionChipX(
                      icon: active
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      label: active ? 'Nonaktifkan' : 'Aktifkan',
                      onTap: () {
                        _toggleActive(id, !active);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // table (desktop)
  Widget _tableList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const XCard(
        title: 'Daftar Perawat',
        subtitle: 'Belum ada data perawat pada pencarian ini.',
        child: _EmptyBox(text: 'Data kosong. Coba ubah kata kunci search.'),
      );
    }

    final rows = items.take(100).map((m) {
      final id = _toInt(m['id']).toString();
      final nama = _pickName(m);
      final kode = _pickKode(m);
      final koor = _pickKoorName(m);
      final hp = _pickPhone(m);
      final verif = _pickVerif(m);
      final active = _isActive(m) ? 'aktif' : 'nonaktif';
      final rating = _rating(m).toStringAsFixed(2);
      final cnt = _ratingCount(m).toString();

      return [id, nama, kode, koor, hp, verif, active, '$rating ($cnt)'];
    }).toList();

    return XCard(
      title: 'Daftar Perawat',
      subtitle: 'Klik aksi untuk assign koordinator / ubah status aktif.',
      child: Column(
        children: [
          TableCard(
            columns: const [
              'ID',
              'Nama',
              'Kode',
              'Koordinator',
              'HP',
              'Verif',
              'Status',
              'Rating',
            ],
            rows: rows,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ActionChipX(
                icon: Icons.swap_horiz_outlined,
                label: 'Assign Koordinator (pilih ID)',
                onTap: () => _pickPerawatAndAssignOneDialog(items),
              ),
              ActionChipX(
                icon: Icons.power_settings_new_outlined,
                label: 'Ubah Status Aktif (pilih ID)',
                onTap: () => _pickPerawatAndToggle(items),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickPerawatAndAssign(List<Map<String, dynamic>> items) async {
    int? selectedId;

    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (ctx, setLocal) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Perawat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedId,
                            hint: const Text('Pilih perawat...'),
                            items: items.take(100).map((p) {
                              final id = _toInt(p['id']);
                              final name = _pickName(p);
                              final kode = _pickKode(p);
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text('$name ($kode)'),
                              );
                            }).toList(),
                            onChanged: (v) => setLocal(() => selectedId = v),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                if (selectedId != null) {
                                  _assignKoordinator(selectedId!);
                                } else {
                                  _toastError(
                                    'Validasi',
                                    'Pilih perawat dulu.',
                                  );
                                }
                              },
                              child: const Text('Lanjut'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPerawatAndToggle(List<Map<String, dynamic>> items) async {
    int? selectedId;
    bool nextActive = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (ctx, setLocal) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ubah Status Aktif',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedId,
                            hint: const Text('Pilih perawat...'),
                            items: items.take(100).map((p) {
                              final id = _toInt(p['id']);
                              final name = _pickName(p);
                              final kode = _pickKode(p);
                              final active = _isActive(p);
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(
                                  '$name ($kode) • ${active ? 'Aktif' : 'Nonaktif'}',
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setLocal(() {
                                selectedId = v;
                                final picked = items.firstWhere(
                                  (e) => _toInt(e['id']) == v,
                                  orElse: () => {},
                                );
                                final cur = _isActive(picked);
                                nextActive = !cur;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Aksi:',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 10),
                          _StatusPill(
                            text: nextActive ? 'Aktifkan' : 'Nonaktifkan',
                            color: nextActive ? _cGreen : _cRed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                if (selectedId != null) {
                                  _toggleActive(selectedId!, nextActive);
                                } else {
                                  _toastError(
                                    'Validasi',
                                    'Pilih perawat dulu.',
                                  );
                                }
                              },
                              child: const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final cols = widget.isDesktop ? 4 : 2;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final isLoading =
            snap.connectionState == ConnectionState.waiting &&
            snap.data == null;
        final isError = snap.hasError && snap.data == null;

        if (isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SectionHeader(
                title: 'Kelola Perawat',
                subtitle: 'Memuat data perawat...',
              ),
              SizedBox(height: 12),
              LoadingCard(title: 'Kelola Perawat'),
            ],
          );
        }

        if (isError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Kelola Perawat',
                subtitle: 'Gagal memuat data.',
              ),
              const SizedBox(height: 12),
              ErrorCard(
                title: 'Kelola Perawat',
                message: 'Gagal memuat data. Coba login ulang / cek token.',
                onRetry: _reload,
              ),
            ],
          );
        }

        final data = snap.data ?? {};
        final items = (data['items'] is List)
            ? _list(data['items'])
            : <Map<String, dynamic>>[];
        final kpi = _map(data['kpi']);

        final total = _toInt(kpi['total']).toString();
        final aktif = _toInt(kpi['aktif']).toString();
        final pending = _toInt(kpi['pending']).toString();
        final avgRating = _toDouble(kpi['avg_rating']).toStringAsFixed(2);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Kelola Perawat',
              subtitle:
                  'Assign koordinator, status aktif, dan monitoring rating.',
            ),
            const SizedBox(height: 12),
            ResponsiveGrid(
              columns: cols,
              gap: 12,
              children: [
                KpiCard(
                  title: 'Total Perawat',
                  value: total,
                  hint: _q.isEmpty ? 'Semua data' : 'Filter: "$_q"',
                  icon: Icons.badge_outlined,
                  accent: _cPrimary,
                ),
                KpiCard(
                  title: 'Perawat Aktif',
                  value: aktif,
                  hint: 'Siap bertugas',
                  icon: Icons.verified_outlined,
                  accent: _cGreen,
                ),
                KpiCard(
                  title: 'Pending Verifikasi',
                  value: pending,
                  hint: 'Perlu review',
                  icon: Icons.hourglass_bottom_outlined,
                  accent: _cAmber,
                ),
                KpiCard(
                  title: 'Avg Rating',
                  value: avgRating,
                  hint: 'Rata-rata penilaian',
                  icon: Icons.star_rate_rounded,
                  accent: _cAmber,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _searchBar(),
            const SizedBox(height: 12),
            if (widget.isDesktop) _tableList(items) else _cardsList(items),
            const SizedBox(height: 12),
            const XCard(
              title: 'Tips',
              subtitle: 'Rekomendasi penggunaan',
              child: _EmptyBox(
                text:
                    'Gunakan Assign Koordinator untuk memindahkan perawat. Gunakan Aktif/Nonaktif untuk mengontrol ketersediaan perawat.',
              ),
            ),
          ],
        );
      },
    );
  }
}

// =========================
// MINI UI helpers
// =========================

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

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

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MiniInfo({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              fontSize: 12.2,
            ),
          ),
        ],
      ),
    );
  }
}

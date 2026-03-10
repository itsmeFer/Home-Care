// ManagerOverviewPage.dart (FULL) ✅
//
// ✅ Desain DISAMAKAN persis seperti OverviewPage Direktur
// ✅ KPI Rupiah (Rp + titik)
// ✅ Chart: prefer cashflow 3 line (Income/Fee/Profit) kalau ada data,
//    fallback ke Trend 1 line kalau backend manager hanya punya trend.
// ✅ Top Layanan (progress bar list)
// ✅ Leaderboard Tim (table)
// ✅ Animasi chart 0 -> nilai tiap buka tab / ganti range
// ✅ Modal "Evaluasi Perawat" -> POST /api/manager/perawat-evaluations
//
// Backend (manager):
// GET  /api/manager/dashboard/overview?range=...
// GET  /api/manager/perawat
// GET  /api/manager/koordinator
// POST /api/manager/perawat-evaluations
//
// Expected keys (fleksibel):
// - kpi / summary
// - cashflow_trend / cashflow / trend_cashflow / trend : [{label, income, fee, profit}]
// - trend (fallback) : [{label, total/order/count/...}]
// - top_layanan / top_services : [{nama, omset}]
// - leaderboard / leaderboard_tim : [{nama, role, order, rating, fee}]

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/ui_components.dart';

class ManagerOverviewPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const ManagerOverviewPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<ManagerOverviewPage> createState() => _ManagerOverviewPageState();
}

class _ManagerOverviewPageState extends State<ManagerOverviewPage>
    with SingleTickerProviderStateMixin {
  static const String kBaseUrl = 'http://192.168.1.6:8000';
  String get kApiBase => '$kBaseUrl/api';

  // ✅ endpoint manager
  String get _url =>
      '$kApiBase/manager/dashboard/overview?range=${Uri.encodeComponent(_rangeParam(widget.range))}';

  Future<Map<String, dynamic>>? _future;

  // ✅ animasi 0 -> nilai (sama seperti direktur)
  late final AnimationController _chartCtrl;
  late final Animation<double> _t;

  // ===== PALETTE (samakan direktur) =====
  static const Color _cIncome = Color(0xFF06B6D4); // cyan-500
  static const Color _cFee = Color(0xFFF59E0B); // amber-500
  static const Color _cProfit = Color(0xFF22C55E); // green-500
  static const Color _grid = Color(0xFFE2E8F0); // slate-200
  static const Color _axis = Color(0xFF64748B); // slate-500

  @override
  void initState() {
    super.initState();

    _chartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _t = CurvedAnimation(parent: _chartCtrl, curve: Curves.easeOutCubic);

    _future = _fetch();
    _replayChart();
  }

  @override
  void didUpdateWidget(covariant ManagerOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      _refresh(); // ✅ BENAR - panggil method async yang sudah ada
    }
  }

  @override
  void dispose() {
    _chartCtrl.dispose();
    super.dispose();
  }

  void _replayChart() {
    if (!mounted) return;
    _chartCtrl.stop();
    _chartCtrl.value = 0;
    _chartCtrl.forward();
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    // Stop animasi dulu sebelum setState
    _chartCtrl.stop();
    _chartCtrl.value = 0;

    // Baru setState
    setState(() {
      _future = _fetch();
    });

    // Tunggu frame berikutnya baru replay
    if (!mounted) return;
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    _chartCtrl.forward();
  }

  // =========================================================
  // ✅ Range mapping: label UI -> param backend
  // =========================================================
  String _rangeParam(String label) {
    switch (label) {
      case 'Hari ini':
        return 'today';
      case '7 hari':
        return '7d';
      case '30 hari':
        return '30d';
      case 'Bulan ini':
        return 'month';
      case 'Tahun ini':
        return 'year';
      default:
        return '7d';
    }
  }

  // =========================
  // AUTH + FETCH
  // =========================
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
        .trim();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final token = await _getToken();
    if (token.isEmpty) throw Exception('Token kosong. Silakan login ulang.');

    final res = await http.get(
      Uri.parse(_url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    // ignore: avoid_print
    print('MANAGER OVERVIEW URL: $_url');
    // ignore: avoid_print
    print('MANAGER OVERVIEW RAW: ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      if (body is Map && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data']);
      }
      if (body is Map) return Map<String, dynamic>.from(body);
      throw Exception('Format response tidak dikenali: ${res.body}');
    }

    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  // =========================
  // FORMAT RUPIAH (tanpa intl) - sama direktur
  // =========================
  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  int _parseMoneyToInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.round();
    final s = v.toString();
    final cleaned = s.replaceAll(RegExp(r'[^0-9\-]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatThousandsId(int n) {
    final neg = n < 0;
    var s = n.abs().toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      out.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) out.write('.');
    }
    final res = out.toString();
    return neg ? '-$res' : res;
  }

  String rupiah(dynamic v, {bool withPrefix = true}) {
    final n = _parseMoneyToInt(v);
    final txt = _formatThousandsId(n);
    return withPrefix ? 'Rp $txt' : txt;
  }

  String rupiahCompact(dynamic v) {
    final n = _parseMoneyToInt(v).toDouble();
    final abs = n.abs();

    String numId(double x) => x.toStringAsFixed(2).replaceAll('.', ',');

    if (abs >= 1e12) return '${numId(n / 1e12)} T';
    if (abs >= 1e9) return '${numId(n / 1e9)} M';
    if (abs >= 1e6) return '${numId(n / 1e6)} Jt';
    if (abs >= 1e3) return '${numId(n / 1e3)} Rb';
    return _formatThousandsId(n.round());
  }

  // =========================
  // SAFE MAP/LIST
  // =========================
  Map<String, dynamic> _map(dynamic v) =>
      (v is Map) ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(dynamic v) =>
      (v is List) ? v.map((e) => _map(e)).toList() : <Map<String, dynamic>>[];

  // =========================
  // EXTRACTORS (fleksibel key) - samakan direktur
  // =========================
  Map<String, dynamic> _getKpi(Map<String, dynamic> data) {
    if (data['kpi'] is Map) return _map(data['kpi']);
    if (data['summary'] is Map) return _map(data['summary']);
    return data;
  }

  List<Map<String, dynamic>> _getCashflow(Map<String, dynamic> data) {
    const keys = [
      'cashflow_trend',
      'trend_cashflow',
      'cashflow',
      'trend',
      'chart_cashflow',
    ];
    for (final k in keys) {
      if (data[k] is List) return _list(data[k]);
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _getTrendFallback(Map<String, dynamic> data) {
    const keys = [
      'trend',
      'tren',
      'order_trend',
      'trend_order',
      'orders_trend',
      'chart_trend',
      'series',
      'chart',
      'grafik',
      'line',
      'data_trend',
      'data_chart',
    ];
    for (final k in keys) {
      final v = data[k];
      if (v is List) return _list(v);
      if (v is Map && v['data'] is List) return _list(v['data']);
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _getTopLayanan(Map<String, dynamic> data) {
    const keys = [
      'top_layanan',
      'top_services',
      'layanan_top',
      'top',
      'profit_per_layanan',
      'omset_per_layanan',
    ];
    for (final k in keys) {
      if (data[k] is List) return _list(data[k]);
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _getLeaderboard(Map<String, dynamic> data) {
    const keys = [
      'leaderboard',
      'leaderboard_tim',
      'top_team',
      'team_leaderboard',
    ];
    for (final k in keys) {
      if (data[k] is List) return _list(data[k]);
    }
    return <Map<String, dynamic>>[];
  }

  // =========================
  // CHART: CASHFLOW 3 LINES
  // + fallback 1 line trend kalau tidak ada cashflow
  // =========================
  Widget _cashflowOrTrendChart(
    List<Map<String, dynamic>> cashflow,
    List<Map<String, dynamic>> trendFallback,
  ) {
    if (cashflow.isNotEmpty) return _cashflowChart(cashflow);
    return _trendFallbackChart(trendFallback);
  }

  Widget _cashflowChart(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const XCard(
        title: 'Grafik Cashflow',
        subtitle: 'Income vs Fee vs Profit.',
        child: ChartPlaceholder(height: 240),
      );
    }

    final labels = <String>[];
    final incomeSpots = <FlSpot>[];
    final feeSpots = <FlSpot>[];
    final profitSpots = <FlSpot>[];

    for (int i = 0; i < items.length; i++) {
      final m = items[i];
      final label =
          (m['label'] ?? m['period'] ?? m['date'] ?? m['bulan'] ?? '${i + 1}')
              .toString();
      labels.add(label);

      final income = _toDouble(m['income'] ?? m['revenue'] ?? m['omset'] ?? 0);
      final fee = _toDouble(m['fee'] ?? m['total_fee'] ?? 0);
      final profit = _toDouble(m['profit'] ?? (income - fee));

      incomeSpots.add(FlSpot(i.toDouble(), income));
      feeSpots.add(FlSpot(i.toDouble(), fee));
      profitSpots.add(FlSpot(i.toDouble(), profit));
    }

    if (incomeSpots.length == 1) {
      incomeSpots.add(FlSpot(1, incomeSpots.first.y));
      feeSpots.add(FlSpot(1, feeSpots.first.y));
      profitSpots.add(FlSpot(1, profitSpots.first.y));
      labels.add('');
    }

    double maxY = 1;
    for (final s in [...incomeSpots, ...feeSpots, ...profitSpots]) {
      maxY = max(maxY, s.y);
    }

    return XCard(
      title: 'Grafik Cashflow',
      subtitle: 'Income vs Fee vs Profit.',
      child: SizedBox(
        height: 260,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final tt = _t.value;

            List<FlSpot> anim(List<FlSpot> src) =>
                src.map((s) => FlSpot(s.x, s.y * tt)).toList();

            return LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: _grid, strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      FlLine(color: _grid.withOpacity(.7), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touched) {
                      return touched.map((t) {
                        final idx = t.x.toInt().clamp(0, labels.length - 1);
                        final label = labels[idx];
                        final v = t.y;

                        final name = t.barIndex == 0
                            ? 'Income'
                            : t.barIndex == 1
                            ? 'Fee'
                            : 'Profit';

                        final color = t.barIndex == 0
                            ? _cIncome
                            : (t.barIndex == 1 ? _cFee : _cProfit);

                        return LineTooltipItem(
                          '$label\n$name: ${rupiah(v, withPrefix: true)}',
                          TextStyle(fontWeight: FontWeight.w900, color: color),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: anim(incomeSpots),
                    isCurved: true,
                    color: _cIncome,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _cIncome.withOpacity(.18),
                    ),
                  ),
                  LineChartBarData(
                    spots: anim(feeSpots),
                    isCurved: true,
                    color: _cFee,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _cFee.withOpacity(.14),
                    ),
                  ),
                  LineChartBarData(
                    spots: anim(profitSpots),
                    isCurved: true,
                    color: _cProfit,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _cProfit.withOpacity(.14),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 64,
                      getTitlesWidget: (v, meta) => Text(
                        rupiahCompact(v),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _axis,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: (labels.length <= 7) ? 1 : 2,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        final s = labels[idx];
                        final short = s.length > 8 ? s.substring(0, 8) : s;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            short,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _axis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _trendFallbackChart(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const XCard(
        title: 'Grafik Aktivitas',
        subtitle: 'Belum ada data grafik pada range ini.',
        child: ChartPlaceholder(height: 240),
      );
    }

    final labels = <String>[];
    final spots = <FlSpot>[];

    for (int i = 0; i < items.length; i++) {
      final m = items[i];
      final label =
          (m['label'] ??
                  m['date'] ??
                  m['tanggal'] ??
                  m['bulan'] ??
                  m['month'] ??
                  m['period'] ??
                  '${i + 1}')
              .toString();
      labels.add(label);

      final y = _toDouble(
        m['total'] ??
            m['order'] ??
            m['orders'] ??
            m['value'] ??
            m['total_order'] ??
            m['count'] ??
            m['jumlah'] ??
            0,
      );
      spots.add(FlSpot(i.toDouble(), y));
    }

    if (spots.length == 1) {
      spots.add(FlSpot(1, spots.first.y));
      labels.add('');
    }

    double maxY = 1;
    for (final s in spots) {
      maxY = max(maxY, s.y);
    }
    if (maxY <= 0) maxY = 1;

    return XCard(
      title: 'Grafik Aktivitas',
      subtitle: 'Trend aktivitas (fallback).',
      child: SizedBox(
        height: 260,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final tt = _t.value;
            final animSpots = spots.map((s) => FlSpot(s.x, s.y * tt)).toList();

            return LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.25,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: _grid, strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      FlLine(color: _grid.withOpacity(.7), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touched) {
                      return touched.map((t) {
                        final idx = t.x.toInt().clamp(0, labels.length - 1);
                        final lab = labels[idx];
                        return LineTooltipItem(
                          '$lab\n${t.y.toStringAsFixed(0)}',
                          const TextStyle(fontWeight: FontWeight.w900),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: animSpots,
                    isCurved: true,
                    color: _cIncome,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _cIncome.withOpacity(.16),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _axis,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: (labels.length <= 7) ? 1 : 2,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        final s = labels[idx];
                        final short = s.length > 8 ? s.substring(0, 8) : s;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            short,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _axis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================
  // TOP LAYANAN (progress list) - sama direktur
  // =========================
  Widget _topLayananCard(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const XCard(
        title: 'Top Layanan',
        subtitle: 'Omset per layanan.',
        child: _EmptyBox(text: 'Belum ada data top layanan pada range ini.'),
      );
    }

    final rows = items.map((m) {
      final nama = (m['nama'] ?? m['name'] ?? m['layanan'] ?? '-').toString();
      final omset = _toDouble(
        m['omset'] ?? m['income'] ?? m['total'] ?? m['value'] ?? 0,
      );
      return {'nama': nama, 'omset': omset};
    }).toList();

    rows.sort((a, b) => (b['omset'] as double).compareTo(a['omset'] as double));
    final top = rows.take(6).toList();
    final maxVal = max(1.0, top.first['omset'] as double);

    return XCard(
      title: 'Top Layanan',
      subtitle: 'Omset per layanan.',
      child: Column(
        children: top.map((m) {
          final nama = m['nama'] as String;
          final v = m['omset'] as double;
          final pct = (v / maxVal).clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      rupiah(v, withPrefix: false),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF334155),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation(_cIncome),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================
  // LEADERBOARD (table) - sama direktur
  // =========================
  Widget _leaderboardCard(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const XCard(
        title: 'Leaderboard Tim',
        subtitle: 'Perawat / Koordinator dengan performa terbaik.',
        child: _EmptyBox(text: 'Belum ada data leaderboard pada range ini.'),
      );
    }

    final rows = items.map((m) {
      final nama = (m['nama'] ?? m['name'] ?? '-').toString();
      final role = (m['role'] ?? m['jabatan'] ?? '-').toString();
      final order = (m['order'] ?? m['orders'] ?? m['total_order'] ?? 0)
          .toString();
      final rating = (_toDouble(
        m['rating'] ?? m['avg_rating'] ?? 0,
      )).toStringAsFixed(0);
      final fee = rupiah(m['fee'] ?? m['total_fee'] ?? 0, withPrefix: false);
      return [nama, role, order, rating, fee];
    }).toList();

    return XCard(
      title: 'Leaderboard Tim',
      subtitle: 'Perawat / Koordinator dengan performa terbaik.',
      child: TableCard(
        columns: const ['Nama', 'Role', 'Order', 'Rating', 'Fee'],
        rows: rows,
      ),
    );
  }

  // =========================
  // ✅ EVALUASI PERAWAT (UI + API)
  // =========================
  Future<List<Map<String, dynamic>>> _fetchList(String url) async {
    final token = await _getToken();
    if (token.isEmpty) throw Exception('Token kosong. Silakan login ulang.');

    final res = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    // ignore: avoid_print
    print('LIST URL: $url');
    // ignore: avoid_print
    print('LIST RAW: ${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body);

    if (body is Map && body['data'] is List) return _list(body['data']);
    if (body is Map && body['data'] is Map && (body['data']['items'] is List)) {
      return _list(body['data']['items']);
    }
    if (body is List) return _list(body);
    if (body is Map && body['items'] is List) return _list(body['items']);

    return <Map<String, dynamic>>[];
  }

  String _pickName(Map<String, dynamic> m) {
    return (m['nama_lengkap'] ??
            m['name'] ??
            m['nama'] ??
            m['full_name'] ??
            '-')
        .toString();
  }

  int _pickId(Map<String, dynamic> m) => _toInt(m['id']);

  void _toastSuccess(String title, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title • $msg'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  void _toastError(String title, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title • $msg'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  // =========================
  // BUILD (sama direktur)
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
                title: 'Ringkasan',
                subtitle: 'Memuat data overview...',
              ),
              SizedBox(height: 12),
              LoadingCard(title: 'Overview'),
            ],
          );
        }

        if (isError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Ringkasan',
                subtitle: 'Gagal memuat data.',
              ),
              const SizedBox(height: 12),
              ErrorCard(title: 'Overview', message: '', onRetry: _refresh),
              const SizedBox(height: 8),
              Text(
                snap.error.toString(),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }

        final data = snap.data ?? {};
        final kpi = _getKpi(data);

        // ✅ KPI manager (fleksibel)
        final revenue =
            kpi['income'] ??
            kpi['revenue'] ??
            kpi['omset'] ??
            kpi['pendapatan'] ??
            0;

        final profit = kpi['profit'] ?? kpi['laba'] ?? 0;

        final totalOrder =
            kpi['total_order'] ??
            kpi['orders'] ??
            kpi['order'] ??
            kpi['jumlah_order'] ??
            0;

        final rating = _toDouble(kpi['rating_avg'] ?? kpi['avg_rating'] ?? 0);

        // ✅ data chart/top/leaderboard
        final cashflow = _getCashflow(data);
        final trendFallback = _getTrendFallback(data);
        final topLayanan = _getTopLayanan(data);
        final leaderboard = _getLeaderboard(data);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Ringkasan',
              subtitle: 'Snapshot performa (Manager) • (${widget.range}).',
            ),
            const SizedBox(height: 12),
            ResponsiveGrid(
              columns: cols,
              gap: 12,
              children: [
                KpiCard(
                  title: 'Revenue ${widget.range}',
                  value: rupiah(revenue),
                  hint: widget.range,
                  icon: Icons.account_balance_wallet_outlined,
                  accent: const Color(0xFF06B6D4),
                ),
                KpiCard(
                  title: 'Profit',
                  value: rupiah(profit),
                  hint: 'Revenue - Fee',
                  icon: Icons.trending_up_rounded,
                  accent: const Color(0xFF22C55E),
                ),
                KpiCard(
                  title: 'Total Order',
                  value: totalOrder.toString(),
                  hint: widget.range,
                  icon: Icons.receipt_long_outlined,
                  accent: const Color(0xFF3B82F6),
                ),
                KpiCard(
                  title: 'Rating',
                  value: rating.toStringAsFixed(2),
                  hint: widget.range,
                  icon: Icons.star_border_rounded,
                  accent: const Color(0xFFF59E0B),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 980;
                if (!wide) {
                  return Column(
                    children: [
                      _cashflowOrTrendChart(cashflow, trendFallback),
                      const SizedBox(height: 12),
                      _topLayananCard(topLayanan),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _cashflowOrTrendChart(cashflow, trendFallback),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _topLayananCard(topLayanan),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _leaderboardCard(leaderboard),
          ],
        );
      },
    );
  }
}

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

// OverviewPage.dart (FULL) ✅
// ✅ KPI Rupiah (Rp + titik)
// ✅ Cashflow chart REAL (fl_chart) 3 line: Income/Fee/Profit
// ✅ Top Layanan (progress bar list)
// ✅ Leaderboard Tim (table)
// ✅ Animasi chart 0 -> nilai tiap buka tab / ganti range
// ✅ WARNA PREMIUM (shadcn-ish): Income=Cyan, Fee=Amber, Profit=Green
//
// Backend (bebas, tapi sebaiknya):
// GET /api/direktur/dashboard/overview?range=...
//
// Expected keys (fleksibel):
// - kpi: { income/revenue, profit, total_order/orders, rating_avg }
// - cashflow_trend / trend_cashflow / cashflow / trend : [{label, income, fee, profit}]
// - top_layanan / top_services / layanan_top : [{nama, omset}]
// - leaderboard / leaderboard_tim : [{nama, role, order, rating, fee}]

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/ui_components.dart';

class OverviewPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const OverviewPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage>
    with SingleTickerProviderStateMixin {
  static const String kBaseUrl = 'http://192.168.1.5:8000';
  String get kApiBase => '$kBaseUrl/api';
  String get _url =>
      '$kApiBase/direktur/dashboard/overview?range=${Uri.encodeComponent(widget.range)}';
  Future<Map<String, dynamic>>? _future;

  // ✅ animasi 0 -> nilai
  late final AnimationController _chartCtrl;
  late final Animation<double> _t;

  // ===== PALETTE (shadcn-ish) =====
  static const Color _cIncome = Color(0xFF06B6D4); // cyan-500
  static const Color _cFee = Color(0xFFF59E0B); // amber-500
  static const Color _cProfit = Color(0xFF22C55E); // green-500
  static const Color _grid = Color(0xFFE2E8F0); // slate-200
  static const Color _axis = Color(0xFF64748B); // slate-500

  @override
  void initState() {
    super.initState();
    _future = _fetch();

    _chartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _t = CurvedAnimation(parent: _chartCtrl, curve: Curves.easeOutCubic);

    _replayChart();
  }

  @override
  void didUpdateWidget(covariant OverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      setState(() => _future = _fetch());
      _replayChart();
    }
  }

  @override
  void dispose() {
    _chartCtrl.dispose();
    super.dispose();
  }

  void _replayChart() {
    _chartCtrl.stop();
    _chartCtrl.value = 0;
    _chartCtrl.forward();
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
  // FORMAT RUPIAH (tanpa intl)
  // =========================
  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
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
  // EXTRACTORS (fleksibel key)
  // =========================
  Map<String, dynamic> _map(dynamic v) =>
      (v is Map) ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(dynamic v) => (v is List)
      ? v.map((e) => _map(e)).toList()
      : <Map<String, dynamic>>[];

  Map<String, dynamic> _getKpi(Map<String, dynamic> data) {
    if (data['kpi'] is Map) return _map(data['kpi']);
    if (data['summary'] is Map) return _map(data['summary']);
    return <String, dynamic>{};
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
      'team_leaderboard'
    ];
    for (final k in keys) {
      if (data[k] is List) return _list(data[k]);
    }
    return <Map<String, dynamic>>[];
  }

  // =========================
  // CHART: CASHFLOW 3 LINES
  // =========================
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

    // handle 1 titik (biar chart gak error)
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
                  getDrawingHorizontalLine: (v) =>
                      const FlLine(color: _grid, strokeWidth: 1),
                  getDrawingVerticalLine: (v) => FlLine(
                    color: _grid.withOpacity(.7),
                    strokeWidth: 1,
                  ),
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
                          TextStyle(
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Income
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
                  // Fee
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
                  // Profit
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

  // =========================
  // TOP LAYANAN (progress list)
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
      final omset =
          _toDouble(m['omset'] ?? m['income'] ?? m['total'] ?? m['value'] ?? 0);
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
  // LEADERBOARD (table)
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
      final order =
          (m['order'] ?? m['orders'] ?? m['total_order'] ?? 0).toString();
      final rating =
          (_toDouble(m['rating'] ?? m['avg_rating'] ?? 0)).toStringAsFixed(0);
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
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final cols = widget.isDesktop ? 4 : 2;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final isLoading =
            snap.connectionState == ConnectionState.waiting && snap.data == null;
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
              SectionHeader(
                title: 'Ringkasan',
                subtitle: 'Gagal memuat data (${widget.range}).',
              ),
              const SizedBox(height: 12),
              ErrorCard(
                title: 'Overview',
                message: '',
                onRetry: () {
                  setState(() => _future = _fetch());
                  _replayChart();
                },
              ),
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

        final revenue = kpi['income'] ?? kpi['revenue'] ?? kpi['omset'] ?? 0;
        final profit = kpi['profit'] ?? 0;
        final totalOrder = kpi['total_order'] ?? kpi['orders'] ?? 0;
        final rating = _toDouble(kpi['rating_avg'] ?? kpi['avg_rating'] ?? 0);

        final cashflow = _getCashflow(data);
        final topLayanan = _getTopLayanan(data);
        final leaderboard = _getLeaderboard(data);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Ringkasan',
              subtitle: 'Snapshot performa bisnis (${widget.range}).',
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
                  title: 'Profit Bersih',
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
                  title: 'Rating Layanan',
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
                      _cashflowChart(cashflow),
                      const SizedBox(height: 12),
                      _topLayananCard(topLayanan),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _cashflowChart(cashflow)),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _topLayananCard(topLayanan)),
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

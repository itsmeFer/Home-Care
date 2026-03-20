// manager/pages/pasien_page.dart (FULL) ✅
// ✅ Style & komponen shadcn-ish (pakai ui_components.dart)
// ✅ KPI cards rapi
// ✅ Pie Segmen Pasien REAL (fl_chart)
// ✅ Tren Order REAL (fl_chart line)
// ✅ Table VIP (TableCard)
// ✅ Animasi chart (0 -> nilai) saat buka tab / ganti range
//
// Backend sebaiknya:
// GET /api/manager/dashboard/pasien?range=...

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/ui_components.dart';

class PasienPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const PasienPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<PasienPage> createState() => _PasienPageState();
}

class _PasienPageState extends State<PasienPage>
    with SingleTickerProviderStateMixin {
  static const String kBaseUrl = 'http://147.93.81.243';
  String get kApiBase => '$kBaseUrl/api';

  // ✅ MANAGER endpoint
  String get _url =>
      '$kApiBase/manager/dashboard/pasien?range=${Uri.encodeComponent(widget.range)}';

  Future<Map<String, dynamic>>? _future;

  // ✅ animasi 0 -> nilai
  late final AnimationController _chartCtrl;
  late final Animation<double> _t;

  // ===== PALETTE (samakan nuansa Overview) =====
  static const Color _cPrimary = Color(0xFF06B6D4); // cyan-500
  static const Color _cGreen = Color(0xFF22C55E); // green-500
  static const Color _cAmber = Color(0xFFF59E0B); // amber-500
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
  void didUpdateWidget(covariant PasienPage oldWidget) {
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
  // SAFE PARSERS
  // =========================
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> _map(dynamic v) =>
      (v is Map) ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(dynamic v) =>
      (v is List) ? v.map((e) => _map(e)).toList() : <Map<String, dynamic>>[];

  // =========================
  // MONEY FORMAT (simple)
  // =========================
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

  // =========================
  // EXTRACTORS (fleksibel key)
  // =========================
  Map<String, dynamic> _getKpi(Map<String, dynamic> data) {
    if (data['kpi'] is Map) return _map(data['kpi']);
    if (data['summary'] is Map) return _map(data['summary']);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _getSegmen(Map<String, dynamic> data) {
    const keys = ['segmen', 'segments', 'segment_pasien', 'pie', 'segmentation'];
    for (final k in keys) {
      if (data[k] is List) return _list(data[k]);
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _getTrenOrder(Map<String, dynamic> data) {
    const keys = ['tren_order', 'trend_order', 'orders_trend', 'trend'];
    for (final k in keys) {
      if (data[k] is List) return _list(data[k]);
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _getVip(Map<String, dynamic> data) {
    const keys = ['vip_pasien', 'vip', 'top_vip', 'top_pasien'];
    for (final k in keys) {
      if (data[k] is List) return _list(data[k]);
    }
    return <Map<String, dynamic>>[];
  }

  // =========================
  // PIE: SEGMENT PASIEN
  // =========================
  Widget _segmenPie(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const XCard(
        title: 'Segmen Pasien',
        subtitle: 'Komposisi segmen pasien.',
        child: _EmptyBox(text: 'Belum ada data segmen pada range ini.'),
      );
    }

    final rows = items
        .map((m) {
          final name = (m['name'] ?? m['segmen'] ?? m['label'] ?? '-')
              .toString();
          final total = _toDouble(m['total'] ?? m['value'] ?? m['count'] ?? 0);
          return {'name': name, 'total': total};
        })
        .where((e) => (e['total'] as double) > 0)
        .toList();

    if (rows.isEmpty) {
      return const XCard(
        title: 'Segmen Pasien',
        subtitle: 'Komposisi segmen pasien.',
        child: _EmptyBox(text: 'Data segmen kosong (total = 0).'),
      );
    }

    rows.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    final top = rows.take(6).toList();

    final totalSum = top.fold<double>(0, (a, b) => a + (b['total'] as double));
    final palette = <Color>[
      const Color(0xFF06B6D4), // cyan
      const Color(0xFF3B82F6), // blue
      const Color(0xFF22C55E), // green
      const Color(0xFFF59E0B), // amber
      const Color(0xFF8B5CF6), // violet
      const Color(0xFFEC4899), // pink
    ];

    return XCard(
      title: 'Segmen Pasien',
      subtitle: 'Komposisi segmen pasien.',
      child: SizedBox(
        height: 240,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final tt = _t.value;

            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 42,
                      sections: List.generate(top.length, (i) {
                        final v = (top[i]['total'] as double) * tt;
                        final pct = totalSum <= 0 ? 0 : (v / totalSum) * 100;

                        return PieChartSectionData(
                          value: max(0.0001, v),
                          color: palette[i % palette.length],
                          radius: 64,
                          title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                          titleStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        );
                      }),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(top.length, (i) {
                        final name = top[i]['name'] as String;
                        final v = top[i]['total'] as double;
                        final pct =
                            totalSum <= 0 ? 0 : (v / totalSum) * 100.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: palette[i % palette.length],
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _axis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================
  // LINE: TREN ORDER
  // =========================
  Widget _trenOrderChart(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const XCard(
        title: 'Tren Order',
        subtitle: 'Perubahan total order pada periode.',
        child: ChartPlaceholder(height: 220),
      );
    }

    final labels = <String>[];
    final spots = <FlSpot>[];

    for (int i = 0; i < items.length; i++) {
      final m = items[i];
      final label = (m['label'] ?? m['date'] ?? m['d'] ?? '${i + 1}')
          .toString();
      labels.add(label);

      final total =
          _toDouble(m['total'] ?? m['total_order'] ?? m['order'] ?? 0);
      spots.add(FlSpot(i.toDouble(), total));
    }

    if (spots.length == 1) {
      spots.add(FlSpot(1, spots.first.y));
      labels.add('');
    }

    double maxY = 1;
    for (final s in spots) {
      maxY = max(maxY, s.y);
    }

    return XCard(
      title: 'Tren Order',
      subtitle: 'Perubahan total order pada periode.',
      child: SizedBox(
        height: 240,
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
                        final label = labels[idx];
                        return LineTooltipItem(
                          '$label\nOrder: ${t.y.toStringAsFixed(0)}',
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
                    color: _cPrimary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _cPrimary.withOpacity(.16),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(0),
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
  // VIP TABLE
  // =========================
  Widget _vipCard(List<Map<String, dynamic>> vip) {
    if (vip.isEmpty) {
      return const XCard(
        title: 'Pasien VIP (Top Omset)',
        subtitle: 'Siapa yang menyumbang omset terbesar.',
        child: _EmptyBox(text: 'Belum ada data VIP pada range ini.'),
      );
    }

    final rows = vip.take(10).map((m) {
      final nama = (m['nama'] ?? m['name'] ?? '-').toString();
      final totalOrder = (m['total_order'] ?? m['order'] ?? 0).toString();
      final omset = rupiah(m['omset'] ?? m['income'] ?? m['total'] ?? 0);
      final status = (m['status'] ?? '-').toString();
      return [nama, totalOrder, omset, status];
    }).toList();

    return XCard(
      title: 'Pasien VIP (Top Omset)',
      subtitle: 'Siapa yang menyumbang omset terbesar.',
      child: TableCard(
        columns: const ['Nama', 'Total Order', 'Omset', 'Status'],
        rows: rows,
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final cols = widget.isDesktop ? 3 : 2;

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
                title: 'Pasien & Insight',
                subtitle: 'Memuat data pasien...',
              ),
              SizedBox(height: 12),
              LoadingCard(title: 'Pasien & Insight'),
            ],
          );
        }

        if (isError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Pasien & Insight',
                subtitle: 'Gagal memuat data (${widget.range}).',
              ),
              const SizedBox(height: 12),
              ErrorCard(
                title: 'Pasien & Insight',
                message: snap.error.toString(),
                onRetry: () => setState(() => _future = _fetch()),
              ),
            ],
          );
        }

        final data = snap.data ?? {};
        final kpi = _getKpi(data);

        final pasienAktif = _toInt(kpi['pasien_aktif']).toString();
        final pasienBaru = _toInt(kpi['pasien_baru']).toString();
        final retensi =
            '${_toDouble(kpi['retensi_percent']).toStringAsFixed(2)}%';

        final segmen = _getSegmen(data);
        final tren = _getTrenOrder(data);
        final vip = _getVip(data);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Pasien & Insight',
              subtitle:
                  'Statistik pasien, retensi, dan tren layanan (${widget.range}).',
            ),
            const SizedBox(height: 12),

            ResponsiveGrid(
              columns: cols,
              gap: 12,
              children: [
                KpiCard(
                  title: 'Pasien Aktif',
                  value: pasienAktif,
                  hint: widget.range,
                  icon: Icons.people_outline,
                  accent: _cPrimary,
                ),
                KpiCard(
                  title: 'Pasien Baru',
                  value: pasienBaru,
                  hint: widget.range,
                  icon: Icons.person_add_alt_1_outlined,
                  accent: _cGreen,
                ),
                KpiCard(
                  title: 'Retensi',
                  value: retensi,
                  hint: 'Kembali order',
                  icon: Icons.refresh_outlined,
                  accent: _cAmber,
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
                      _segmenPie(segmen),
                      const SizedBox(height: 12),
                      _trenOrderChart(tren),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _segmenPie(segmen)),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: _trenOrderChart(tren)),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            _vipCard(vip),
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

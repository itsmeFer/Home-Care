// KeuanganPage.dart (FIXED TOKEN) ✅
// ✅ Token diambil dari 'auth_token' (sesuai login.dart)
// ✅ KPI Rupiah (Rp + titik)
// ✅ Table Rupiah
// ✅ 3 Chart mode (Line/Pie/Bar)
// ✅ Pie donut + legend responsif (rapih, tidak numpuk tulisan)
// ✅ Animasi chart 0 -> nilai tiap buka tab / ganti tab / ganti range
// ✅ Export CSV (Web & Mobile)

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart' as uio;
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

import '../widgets/ui_components.dart';

enum KeuanganChartMode { lineRevenue, pieFee, barProfitLayanan }

class KeuanganPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const KeuanganPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

class _KeuanganPageState extends State<KeuanganPage>
    with SingleTickerProviderStateMixin {
  static const String kBaseUrl = 'http://192.168.1.5:8000';
  String get kApiBase => '$kBaseUrl/api';
  String get _url =>
      '$kApiBase/direktur/dashboard/keuangan?range=${Uri.encodeComponent(widget.range)}';

  Future<Map<String, dynamic>>? _future;

  KeuanganChartMode _mode = KeuanganChartMode.lineRevenue;

  // ✅ animasi nilai chart 0 -> nilai
  late final AnimationController _chartCtrl;
  late final Animation<double> _t;

  // ✅ animasi masuk (fade/slide) saat ganti chart/range
  Key _chartAnimKey = UniqueKey();

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
  void didUpdateWidget(covariant KeuanganPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      setState(() {
        _future = _fetch();
        _chartAnimKey = UniqueKey();
      });
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

  Widget _animateIn(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (w, anim) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: w),
        );
      },
      child: KeyedSubtree(key: _chartAnimKey, child: child),
    );
  }

  // =========================
  // AUTH + FETCH
  // =========================
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ FIX: Cek auth_token dulu (sesuai login.dart), fallback ke token
    return prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
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

  // =========================================================
  // ✅ FORMAT RUPIAH PINTAR (tanpa intl)
  // =========================================================
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

  String rupiahCompact(dynamic v, {bool withPrefix = false}) {
    final n = _parseMoneyToInt(v).toDouble();
    final abs = n.abs();

    String numId(double x) => x.toStringAsFixed(2).replaceAll('.', ',');

    final prefix = withPrefix ? 'Rp ' : '';

    if (abs >= 1e12) return '$prefix${numId(n / 1e12)} T';
    if (abs >= 1e9) return '$prefix${numId(n / 1e9)} M';
    if (abs >= 1e6) return '$prefix${numId(n / 1e6)} Jt';
    if (abs >= 1e3) return '$prefix${numId(n / 1e3)} Rb';
    return '$prefix${_formatThousandsId(n.round())}';
  }

  String _shortServiceLabel(String name) {
    final n = name.trim();
    if (n.isEmpty) return '-';

    final m = RegExp(r'(\d+)\s*$').firstMatch(n);
    final suffix = m != null ? m.group(1)! : '';

    final parts = n.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final base = parts.take(2).join(' '); // "Layanan Demo"

    if (suffix.isNotEmpty) return '$base $suffix';
    return n.length > 14 ? '${n.substring(0, 14)}…' : n;
  }

  // =========================
  // EXPORT CSV
  // =========================
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

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _exportKeuangan(Map<String, dynamic> data) async {
    try {
      final kpi = (data['kpi'] is Map)
          ? Map<String, dynamic>.from(data['kpi'])
          : <String, dynamic>{};

      final List perLayanan = (data['profit_per_layanan'] is List)
          ? data['profit_per_layanan']
          : const [];

      final trend = _extractTrend(data);
      final feePie = _extractFeeComposition(data);

      final income = rupiah(kpi['income'], withPrefix: true);
      final fee = rupiah(kpi['fee'], withPrefix: true);
      final profit = rupiah(kpi['profit'], withPrefix: true);

      final margin = _toDouble(kpi['margin_percent']).toStringAsFixed(2);

      final sb = StringBuffer();

      sb.writeln('sep=;');

      sb.writeln('KPI;Key;Value');
      sb.writeln('KPI;range;${_esc(widget.range)}');
      sb.writeln('KPI;income;$income');
      sb.writeln('KPI;fee;$fee');
      sb.writeln('KPI;profit;$profit');
      sb.writeln('KPI;margin_percent;${_esc(margin)}');

      sb.writeln('');
      sb.writeln('TREND_REVENUE;label;income');
      for (final m in trend) {
        final label =
            (m['label'] ??
                    m['period'] ??
                    m['date'] ??
                    m['bulan'] ??
                    m['month'] ??
                    '-')
                .toString();
        final val =
            (m['value'] ?? m['income'] ?? m['revenue'] ?? m['omset'] ?? 0);

        sb.writeln(
          'TREND_REVENUE;${_esc(label)};${_esc(rupiah(val, withPrefix: true))}',
        );
      }

      sb.writeln('');
      sb.writeln('FEE_COMPOSITION;name;total');
      for (final m in feePie) {
        final name = (m['name'] ?? m['label'] ?? m['tipe'] ?? m['role'] ?? '-')
            .toString();
        final val =
            (m['total'] ?? m['value'] ?? m['amount'] ?? m['nominal'] ?? 0);

        sb.writeln(
          'FEE_COMPOSITION;${_esc(name)};${_esc(rupiah(val, withPrefix: true))}',
        );
      }

      sb.writeln('');
      sb.writeln('PROFIT_PER_LAYANAN;nama;omset;fee;profit');
      for (final e in perLayanan) {
        final m = (e is Map)
            ? Map<String, dynamic>.from(e)
            : <String, dynamic>{};

        sb.writeln(
          'PROFIT_PER_LAYANAN;'
          '${_esc((m['nama'] ?? '-').toString())};'
          '${_esc(rupiah(m['omset'], withPrefix: true))};'
          '${_esc(rupiah(m['fee'], withPrefix: true))};'
          '${_esc(rupiah(m['profit'], withPrefix: true))}',
        );
      }

      final bytes = _utf8WithBom(sb.toString());

      final safeRange = widget.range.replaceAll(' ', '_');
      final safeTime = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'keuangan_${safeRange}_$safeTime.csv';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: blobUrl)
          ..download = fileName
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
        _toast('Export keuangan berhasil (CSV).');
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
  // DATA EXTRACT
  // =========================
  List<Map<String, dynamic>> _extractTrend(Map<String, dynamic> data) {
    final keys = [
      'trend',
      'trend_revenue',
      'revenue_trend',
      'chart_trend',
      'tren',
    ];
    for (final k in keys) {
      final v = data[k];
      if (v is List) {
        return v
            .map(
              (e) => (e is Map)
                  ? Map<String, dynamic>.from(e)
                  : <String, dynamic>{},
            )
            .toList();
      }
    }
    return const [];
  }

  List<Map<String, dynamic>> _extractFeeComposition(Map<String, dynamic> data) {
    final keys = ['fee_composition', 'komposisi_fee', 'fee_pie', 'pie_fee'];
    for (final k in keys) {
      final v = data[k];
      if (v is List) {
        return v
            .map(
              (e) => (e is Map)
                  ? Map<String, dynamic>.from(e)
                  : <String, dynamic>{},
            )
            .toList();
      }
    }
    return const [];
  }

  ({List<FlSpot> spots, List<String> labels}) _buildTrendSeries(
    List<Map<String, dynamic>> trend,
  ) {
    final spots = <FlSpot>[];
    final labels = <String>[];

    for (var i = 0; i < trend.length; i++) {
      final m = trend[i];
      final label =
          (m['label'] ??
                  m['period'] ??
                  m['date'] ??
                  m['bulan'] ??
                  m['month'] ??
                  '')
              .toString();
      labels.add(label.isEmpty ? '${i + 1}' : label);

      final val = _toDouble(
        m['value'] ?? m['income'] ?? m['revenue'] ?? m['omset'] ?? 0,
      );
      spots.add(FlSpot(i.toDouble(), val));
    }

    if (spots.length == 1) {
      spots.add(FlSpot(1, spots.first.y));
      labels.add('');
    }

    return (spots: spots, labels: labels);
  }

  // =========================
  // UI: SWITCHER
  // =========================
  Widget _chartSwitcher() {
    String label(KeuanganChartMode m) {
      switch (m) {
        case KeuanganChartMode.lineRevenue:
          return 'Tren Revenue';
        case KeuanganChartMode.pieFee:
          return 'Komposisi Fee';
        case KeuanganChartMode.barProfitLayanan:
          return 'Profit per Layanan';
      }
    }

    IconData icon(KeuanganChartMode m) {
      switch (m) {
        case KeuanganChartMode.lineRevenue:
          return Icons.show_chart_rounded;
        case KeuanganChartMode.pieFee:
          return Icons.pie_chart_rounded;
        case KeuanganChartMode.barProfitLayanan:
          return Icons.bar_chart_rounded;
      }
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: KeuanganChartMode.values.map((m) {
        final active = _mode == m;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() {
            _mode = m;
            _chartAnimKey = UniqueKey();
            _replayChart(); // ✅ animasi 0->nilai tiap ganti tab
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
                width: active ? 1.4 : 1,
              ),
              color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon(m),
                  size: 18,
                  color: active
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  label(m),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.8,
                    color: active
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================
  // UI: PIE LEGEND
  // =========================
  Widget _pieLegend(List<Map<String, dynamic>> data, {required bool isWide}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        children: List.generate(data.length, (i) {
          final name = (data[i]['name'] ?? '-').toString();
          final value = (data[i]['value'] ?? 0) as double;
          final percent = (data[i]['percent'] ?? 0) as double;
          final color = (data[i]['color'] ?? const Color(0xFF06B6D4)) as Color;

          final short = name.length > 18 ? '${name.substring(0, 18)}…' : name;

          return SizedBox(
            width: isWide ? 260 : 180,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        short,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          fontSize: 12.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${percent.toStringAsFixed(0)}% • ${rupiah(value, withPrefix: true)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          fontSize: 12.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // =========================
  // CHARTS (Line, Pie, Bar - code tetap sama, tidak perlu diubah)
  // =========================
  Widget _lineRevenueChart(List<Map<String, dynamic>> trend) {
    if (trend.isEmpty) {
      return const XCard(
        title: 'Tren Revenue',
        subtitle: 'Belum ada data chart untuk range ini.',
        child: ChartPlaceholder(height: 240),
      );
    }

    final series = _buildTrendSeries(trend);
    final spots = series.spots;
    final labels = series.labels;

    double maxY = 0;
    for (final s in spots) {
      if (s.y > maxY) maxY = s.y;
    }
    if (maxY <= 0) maxY = 1;

    return XCard(
      title: 'Tren Revenue',
      subtitle: 'Sesuai range: ${widget.range}',
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
                maxY: maxY * 1.15,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: animSpots,
                    isCurved: true,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true),
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
                      getTitlesWidget: (v, meta) {
                        return Text(
                          rupiahCompact(v, withPrefix: false),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        );
                      },
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
                        final label = labels[idx];
                        final short = label.length > 8
                            ? label.substring(0, 8)
                            : label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            short,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
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

  Widget _pieFeeChart(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const XCard(
        title: 'Komposisi Fee',
        subtitle: 'Belum ada data chart untuk range ini.',
        child: PiePlaceholder(height: 240),
      );
    }

    // normalize + sort
    final data = items
        .map(
          (e) =>
              (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{},
        )
        .map((m) {
          final name =
              (m['name'] ?? m['label'] ?? m['tipe'] ?? m['role'] ?? '-')
                  .toString();
          final val = _toDouble(
            m['total'] ?? m['value'] ?? m['amount'] ?? m['nominal'] ?? 0,
          );
          return {'name': name, 'value': val};
        })
        .where((m) => (m['value'] as double) > 0)
        .toList();

    data.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    final total = data.fold<double>(0, (p, m) => p + (m['value'] as double));
    final safeTotal = total <= 0 ? 1.0 : total;

    const palette = <Color>[
      Color(0xFF06B6D4),
      Color(0xFF3B82F6),
      Color(0xFF22C55E),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFFEF4444),
      Color(0xFF14B8A6),
      Color(0xFF64748B),
    ];

    int touchedIndex = -1;

    return XCard(
      title: 'Komposisi Fee',
      subtitle: 'Sesuai range: ${widget.range}',
      child: StatefulBuilder(
        builder: (context, setInner) {
          return LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final isWide = w >= 780;
              final chartSize = isWide ? 260.0 : 240.0;

              // build sections base (tanpa text di slice)
              final baseSections = <PieChartSectionData>[];
              for (var i = 0; i < data.length; i++) {
                final v = data[i]['value'] as double;
                final percent = (v / safeTotal) * 100;
                final color = palette[i % palette.length];

                data[i]['percent'] = percent;
                data[i]['color'] = color;

                final isTouched = i == touchedIndex;

                baseSections.add(
                  PieChartSectionData(
                    color: color,
                    value: v,
                    radius: isTouched ? 78 : 70,
                    title: '',
                  ),
                );
              }

              final legend = _pieLegend(data, isWide: isWide);

              Widget chart = SizedBox(
                width: chartSize,
                height: chartSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _t,
                      builder: (context, _) {
                        final tt = _t.value;

                        final sections = baseSections.map((s) {
                          final v = s.value * tt;
                          return s.copyWith(value: v <= 0 ? 0.0001 : v);
                        }).toList();

                        return PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: 62,
                            sectionsSpace: 3,
                            pieTouchData: PieTouchData(
                              enabled: true,
                              touchCallback: (event, resp) {
                                if (!event.isInterestedForInteractions ||
                                    resp?.touchedSection == null) {
                                  setInner(() => touchedIndex = -1);
                                  return;
                                }
                                setInner(
                                  () => touchedIndex =
                                      resp!.touchedSection!.touchedSectionIndex,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total Fee',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rupiah(safeTotal, withPrefix: true),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            fontSize: 16.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    chart,
                    const SizedBox(width: 18),
                    Expanded(child: legend),
                  ],
                );
              }

              return Column(
                children: [chart, const SizedBox(height: 12), legend],
              );
            },
          );
        },
      ),
    );
  }

  Widget _barProfitLayananChart(List<Map<String, dynamic>> perLayanan) {
    if (perLayanan.isEmpty) {
      return const XCard(
        title: 'Profit per Layanan',
        subtitle: 'Belum ada data chart untuk range ini.',
        child: ChartPlaceholder(height: 240),
      );
    }

    final items = perLayanan
        .map(
          (e) =>
              (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{},
        )
        .toList();

    items.sort(
      (a, b) => _toDouble(b['profit']).compareTo(_toDouble(a['profit'])),
    );
    final top = items.take(8).toList();

    final maxY = max(
      1,
      top
          .map((m) => _toDouble(m['profit']))
          .fold<double>(0, (p, v) => max(p, v)),
    );

    return XCard(
      title: 'Profit per Layanan',
      subtitle: 'Top layanan paling menghasilkan (${widget.range})',
      child: SizedBox(
        height: 240,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final tt = _t.value;

            return BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final nama = (top[group.x]['nama'] ?? '-').toString();
                      // tooltip pakai nilai asli (bukan yg ter-animasi)
                      final raw = _toDouble(top[group.x]['profit']);
                      return BarTooltipItem(
                        '$nama\n${rupiah(raw, withPrefix: true)}',
                        const TextStyle(fontWeight: FontWeight.w800),
                      );
                    },
                  ),
                ),
                minY: 0,
                maxY: maxY * 1.15,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < top.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _toDouble(top[i]['profit']) * tt, // ✅ 0 -> nilai
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
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
                      getTitlesWidget: (v, meta) {
                        return Text(
                          rupiahCompact(v, withPrefix: false),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= top.length)
                          return const SizedBox.shrink();
                        final name = (top[idx]['nama'] ?? '-').toString();
                        final short = _shortServiceLabel(name);
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            short,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
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

  Widget _chartByMode({
    required KeuanganChartMode mode,
    required Map<String, dynamic> data,
  }) {
    final trend = _extractTrend(data);
    final feePie = _extractFeeComposition(data);
    final perLayanan = (data['profit_per_layanan'] is List)
        ? (data['profit_per_layanan'] as List)
              .map(
                (e) => (e is Map)
                    ? Map<String, dynamic>.from(e)
                    : <String, dynamic>{},
              )
              .toList()
        : <Map<String, dynamic>>[];

    switch (mode) {
      case KeuanganChartMode.lineRevenue:
        return _lineRevenueChart(trend);
      case KeuanganChartMode.pieFee:
        return _pieFeeChart(feePie);
      case KeuanganChartMode.barProfitLayanan:
        return _barProfitLayananChart(perLayanan);
    }
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
            snap.connectionState == ConnectionState.waiting &&
            snap.data == null;
        final isError = snap.hasError && snap.data == null;

        final data = snap.data ?? {};
        final kpi = (data['kpi'] is Map)
            ? Map<String, dynamic>.from(data['kpi'])
            : <String, dynamic>{};

        final incomeTxt = rupiah(kpi['income']);
        final feeTxt = rupiah(kpi['fee']);
        final profitTxt = rupiah(kpi['profit']);
        final margin = _toDouble(kpi['margin_percent']).toStringAsFixed(2);

        final List perLayanan = (data['profit_per_layanan'] is List)
            ? data['profit_per_layanan']
            : const [];

        final rows = perLayanan.isNotEmpty
            ? perLayanan.take(10).map((e) {
                final m = (e is Map)
                    ? Map<String, dynamic>.from(e)
                    : <String, dynamic>{};
                return [
                  (m['nama'] ?? '-').toString(),
                  rupiah(m['omset'], withPrefix: false),
                  rupiah(m['fee'], withPrefix: false),
                  rupiah(m['profit'], withPrefix: false),
                ];
              }).toList()
            : const <List<String>>[];

        if (isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SectionHeader(title: 'Keuangan', subtitle: 'Memuat data...'),
              SizedBox(height: 12),
              LoadingCard(title: 'Keuangan'),
            ],
          );
        }

        if (isError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Keuangan',
                subtitle: 'Gagal memuat data (${widget.range}).',
              ),
              const SizedBox(height: 12),
              ErrorCard(
                title: 'Keuangan',
                message: snap.error.toString(),
                onRetry: () {
                  setState(() {
                    _future = _fetch();
                    _chartAnimKey = UniqueKey();
                  });
                  _replayChart();
                },
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Keuangan',
              subtitle:
                  'Ringkasan revenue, fee, dan profitabilitas (${widget.range}).',
            ),
            const SizedBox(height: 12),

            ResponsiveGrid(
              columns: cols,
              gap: 12,
              children: [
                KpiCard(
                  title: 'Total Income',
                  value: incomeTxt,
                  hint: widget.range,
                  icon: Icons.account_balance_wallet_outlined,
                  accent: const Color(0xFF0EA5E9),
                ),
                KpiCard(
                  title: 'Total Fee Dibayar',
                  value: feeTxt,
                  hint: 'Perawat/Koordinator/Dokter',
                  icon: Icons.groups_outlined,
                  accent: const Color(0xFFF59E0B),
                ),
                KpiCard(
                  title: 'Profit Bersih',
                  value: profitTxt,
                  hint: 'Margin $margin%',
                  icon: Icons.savings_outlined,
                  accent: const Color(0xFF16A34A),
                ),
              ],
            ),

            const SizedBox(height: 12),

            XCard(
              title: 'Visualisasi',
              subtitle: 'Pilih jenis chart sesuai kebutuhan (${widget.range}).',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _chartSwitcher(),
                  const SizedBox(height: 12),
                  _animateIn(_chartByMode(mode: _mode, data: data)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            XCard(
              title: 'Profitabilitas per Layanan',
              subtitle:
                  'Omset vs fee, supaya direktur tahu layanan yang paling menghasilkan.',
              child: rows.isEmpty
                  ? const _EmptyBox(
                      text: 'Belum ada data profit per layanan pada range ini.',
                    )
                  : Column(
                      children: [
                        TableCard(
                          columns: const ['Layanan', 'Omset', 'Fee', 'Profit'],
                          rows: rows,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlineButtonX(
                            icon: Icons.download_outlined,
                            label: 'Export Keuangan',
                            onTap: () => _exportKeuangan(data),
                          ),
                        ),
                      ],
                    ),
            ),
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
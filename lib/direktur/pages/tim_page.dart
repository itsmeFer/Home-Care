// TimPage.dart (FULL) ✅ FIX
// ✅ KPI tim (angka)
// ✅ Leaderboard perawat + Fee format Rupiah (Rp + titik)
// ✅ Rating FIX: normalisasi skala 0..5 (support 0..1, 0..5, 0..100) + tampil bintang + angka
// ✅ 3 pilihan chart (Line/Bar/Pie) + animasi 0 -> nilai tiap buka tab / ganti tab / ganti range
// ✅ Legend pie responsif + donut modern
// ✅ Export CSV (Web & Mobile) - kolom konsisten (tidak geser) + fee "Rp ..."
// ✅ TOKEN FIX: cek 'auth_token' dulu (sesuai login.dart), fallback 'token'
// Dependencies:
// - fl_chart, http, shared_preferences, universal_html, universal_io, path_provider
//
// Backend:
// GET /api/direktur/dashboard/tim?range=...
//
// Expected keys (fleksibel):
// kpi: perawat_aktif, koordinator_aktif, dokter_aktif, komplain
// leaderboard_perawat: [{nama, order, rating/rating_avg/avg_rating/nilai_rating/score, fee}]
// tim_trend (atau trend / chart_trend / trend_kinerja):
//   [{label/period/date/bulan/month, order/total_order/value/count}]
// komplain_composition (atau komplain_pie / pie_komplain):
//   [{name/label/tipe, total/value/amount}]

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

enum TimChartMode { lineOrders, barTopNurse, pieComplaints }

class TimPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const TimPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<TimPage> createState() => _TimPageState();
}

class _TimPageState extends State<TimPage> with SingleTickerProviderStateMixin {
  static const String kBaseUrl = 'http://147.93.81.243';
  String get kApiBase => '$kBaseUrl/api';
  String get _url =>
      '$kApiBase/direktur/dashboard/tim?range=${Uri.encodeComponent(widget.range)}';

  Future<Map<String, dynamic>>? _future;

  TimChartMode _mode = TimChartMode.lineOrders;

  // ✅ animasi nilai chart 0 -> nilai
  late final AnimationController _chartCtrl;
  late final Animation<double> _t;

  // ✅ animasi masuk saat ganti chart / range
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
  void dispose() {
    _chartCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TimPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      setState(() {
        _future = _fetch();
        _chartAnimKey = UniqueKey();
      });
      _replayChart();
    }
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
    // ✅ Cek auth_token dulu (sesuai login.dart), fallback ke token
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
  // HELPERS
  // =========================================================
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

  // ✅ Normalisasi rating ke 0..5:
  // - 0..1 => *5
  // - 0..5 => 그대로
  // - 0..100 => /20
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

  double? _readRating(Map<String, dynamic> m) {
    final raw = m['rating'] ??
        m['rating_avg'] ??
        m['avg_rating'] ??
        m['nilai_rating'] ??
        m['score'];
    return _normalizeRating(raw);
  }

  String _ratingText(double? r) {
    if (r == null) return '-';
    final full = r.floor();
    final hasHalf = (r - full) >= 0.5;

    final buf = StringBuffer();
    for (int i = 0; i < 5; i++) {
      if (i < full) {
        buf.write('★');
      } else if (i == full && hasHalf) {
        buf.write('⯨'); // simbol half (biar beda dari ½)
      } else {
        buf.write('☆');
      }
    }
    return '${buf.toString()}  ${r.toStringAsFixed(1)}';
  }

  // =========================================================
  // DATA EXTRACT (fleksibel)
  // =========================================================
  List<Map<String, dynamic>> _extractTrend(Map<String, dynamic> data) {
    final keys = [
      'tim_trend',
      'trend',
      'trend_kinerja',
      'chart_trend',
      'kinerja_trend',
    ];
    for (final k in keys) {
      final v = data[k];
      if (v is List) {
        return v
            .map((e) => (e is Map)
                ? Map<String, dynamic>.from(e)
                : <String, dynamic>{})
            .toList();
      }
    }
    return const [];
  }

  List<Map<String, dynamic>> _extractComplaintsPie(Map<String, dynamic> data) {
    final keys = [
      'komplain_composition',
      'komplain_pie',
      'pie_komplain',
      'complaints_pie',
    ];
    for (final k in keys) {
      final v = data[k];
      if (v is List) {
        return v
            .map((e) => (e is Map)
                ? Map<String, dynamic>.from(e)
                : <String, dynamic>{})
            .toList();
      }
    }
    return const [];
  }

  ({List<FlSpot> spots, List<String> labels}) _buildOrderTrendSeries(
    List<Map<String, dynamic>> trend,
  ) {
    final spots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < trend.length; i++) {
      final m = trend[i];
      final label = (m['label'] ??
              m['period'] ??
              m['date'] ??
              m['bulan'] ??
              m['month'] ??
              '')
          .toString();
      labels.add(label.isEmpty ? '${i + 1}' : label);

      final y = _toDouble(
        m['order'] ?? m['total_order'] ?? m['value'] ?? m['count'] ?? 0,
      );
      spots.add(FlSpot(i.toDouble(), y));
    }

    if (spots.length == 1) {
      spots.add(FlSpot(1, spots.first.y));
      labels.add('');
    }

    return (spots: spots, labels: labels);
  }

  // =========================================================
  // EXPORT CSV
  // =========================================================
  Uint8List _utf8WithBom(String s) {
    final b = utf8.encode(s);
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...b]);
  }

  String _esc(String s) {
    final needsQuote =
        s.contains(';') || s.contains('\n') || s.contains('\r') || s.contains('"');
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

  Future<void> _exportTim(Map<String, dynamic> data) async {
    try {
      final kpi = (data['kpi'] is Map)
          ? Map<String, dynamic>.from(data['kpi'])
          : <String, dynamic>{};

      final trend = _extractTrend(data);

      final List lb = (data['leaderboard_perawat'] is List)
          ? data['leaderboard_perawat']
          : const [];

      final sb = StringBuffer();
      sb.writeln('sep=;');

      // ✅ KPI: 3 kolom konsisten SECTION;Key;Value
      sb.writeln('KPI;Key;Value');
      sb.writeln('KPI;range;${_esc(widget.range)}');
      sb.writeln('KPI;perawat_aktif;${_toInt(kpi['perawat_aktif'])}');
      sb.writeln('KPI;koordinator_aktif;${_toInt(kpi['koordinator_aktif'])}');
      sb.writeln('KPI;dokter_aktif;${_toInt(kpi['dokter_aktif'])}');
      sb.writeln('KPI;komplain;${_toInt(kpi['komplain'])}');

      sb.writeln('');

      // ✅ TREND: 3 kolom konsisten SECTION;label;order
      sb.writeln('TREND;label;order');
      for (final m in trend) {
        final label = (m['label'] ??
                m['period'] ??
                m['date'] ??
                m['bulan'] ??
                m['month'] ??
                '-')
            .toString();
        final val = _toDouble(
          m['order'] ?? m['total_order'] ?? m['value'] ?? m['count'] ?? 0,
        );
        sb.writeln('TREND;${_esc(label)};${val.toStringAsFixed(0)}');
      }

      sb.writeln('');

      // ✅ LEADERBOARD: 5 kolom konsisten SECTION;nama;order;rating;fee
      sb.writeln('LEADERBOARD_PERAWAT;nama;order;rating;fee');
      for (final e in lb) {
        final m = (e is Map)
            ? Map<String, dynamic>.from(e)
            : <String, dynamic>{};

        final rating = _readRating(m);
        final ratingTxt = rating == null ? '' : rating.toStringAsFixed(2);

        sb.writeln(
          'LEADERBOARD_PERAWAT;'
          '${_esc((m['nama'] ?? '-').toString())};'
          '${_toInt(m['order'])};'
          '${_esc(ratingTxt)};'
          '${_esc(rupiah(m['fee'], withPrefix: true))}',
        );
      }

      final bytes = _utf8WithBom(sb.toString());

      final safeRange = widget.range.replaceAll(' ', '_');
      final safeTime = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'kinerja_tim_${safeRange}_$safeTime.csv';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: blobUrl)
          ..download = fileName
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
        _toast('Export kinerja tim berhasil (CSV).');
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

  // =========================================================
  // UI: SWITCHER
  // =========================================================
  Widget _chartSwitcher() {
    String label(TimChartMode m) {
      switch (m) {
        case TimChartMode.lineOrders:
          return 'Tren Order';
        case TimChartMode.barTopNurse:
          return 'Top Perawat';
        case TimChartMode.pieComplaints:
          return 'Komplain';
      }
    }

    IconData icon(TimChartMode m) {
      switch (m) {
        case TimChartMode.lineOrders:
          return Icons.show_chart_rounded;
        case TimChartMode.barTopNurse:
          return Icons.bar_chart_rounded;
        case TimChartMode.pieComplaints:
          return Icons.pie_chart_rounded;
      }
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: TimChartMode.values.map((m) {
        final active = _mode == m;
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() {
            _mode = m;
            _chartAnimKey = UniqueKey();
            _replayChart();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
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
                  color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  label(m),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.8,
                    color: active ? const Color(0xFF2563EB) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================
  // CHARTS
  // =========================================================
  Widget _lineOrdersChart(List<Map<String, dynamic>> trend) {
    if (trend.isEmpty) {
      return const XCard(
        title: 'Tren Order',
        subtitle: 'Belum ada data chart untuk range ini.',
        child: ChartPlaceholder(height: 240),
      );
    }

    final series = _buildOrderTrendSeries(trend);
    final spots = series.spots;
    final labels = series.labels;

    double maxY = 0;
    for (final s in spots) {
      if (s.y > maxY) maxY = s.y;
    }
    if (maxY <= 0) maxY = 1;

    return XCard(
      title: 'Tren Order',
      subtitle: 'Jumlah order per periode (${widget.range})',
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
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, meta) {
                        return Text(
                          v.toStringAsFixed(0),
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
                        final short = label.length > 8 ? '${label.substring(0, 8)}…' : label;
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

  Widget _barTopNurseChart(List<Map<String, dynamic>> lb) {
    if (lb.isEmpty) {
      return const XCard(
        title: 'Top Perawat',
        subtitle: 'Belum ada data leaderboard pada range ini.',
        child: ChartPlaceholder(height: 240),
      );
    }

    final items = lb
        .map((e) => (e is Map)
            ? Map<String, dynamic>.from(e)
            : <String, dynamic>{})
        .toList();

    // ✅ sort by order desc, tie-break by rating desc
    items.sort((a, b) {
      final ao = _toInt(a['order']);
      final bo = _toInt(b['order']);
      if (bo != ao) return bo.compareTo(ao);

      final ar = _readRating(a) ?? 0;
      final br = _readRating(b) ?? 0;
      return br.compareTo(ar);
    });

    final top = items.take(8).toList();
    final maxY = max(
      1,
      top.map((m) => _toDouble(m['order'])).fold<double>(0, (p, v) => max(p, v)),
    );

    return XCard(
      title: 'Top Perawat',
      subtitle: 'Perawat paling produktif (berdasarkan order)',
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
                      final row = Map<String, dynamic>.from(top[group.x]);
                      final nama = (row['nama'] ?? '-').toString();
                      final order = _toInt(row['order']);
                      final rating = _readRating(row) ?? 0;
                      final ratingTxt = rating.toStringAsFixed(2);
                      final fee = rupiah(row['fee'], withPrefix: true);

                      return BarTooltipItem(
                        '$nama\nOrder: $order\nRating: $ratingTxt / 5\nFee: $fee',
                        const TextStyle(fontWeight: FontWeight.w800),
                      );
                    },
                  ),
                ),
                minY: 0,
                maxY: maxY * 1.2,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (int i = 0; i < top.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _toDouble(top[i]['order']) * tt,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, meta) {
                        return Text(
                          v.toStringAsFixed(0),
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
                        if (idx < 0 || idx >= top.length) return const SizedBox.shrink();
                        final name = (top[idx]['nama'] ?? '-').toString();
                        final short = name.length > 10 ? '${name.substring(0, 10)}…' : name;
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

  Widget _pieComplaintsChart(Map<String, dynamic> dataRoot) {
    final raw = _extractComplaintsPie(dataRoot);

    final list = raw.isNotEmpty
        ? raw
        : [
            {
              'name': 'Komplain',
              'total': _toDouble(
                ((dataRoot['kpi'] ?? {}) is Map)
                    ? (Map<String, dynamic>.from(dataRoot['kpi'])['komplain'] ?? 0)
                    : 0,
              ),
            }
          ];

    final data = list
        .map((m) {
          final name = (m['name'] ?? m['label'] ?? m['tipe'] ?? 'Komplain').toString();
          final val = _toDouble(m['total'] ?? m['value'] ?? m['amount'] ?? 0);
          return {'name': name, 'value': val};
        })
        .where((m) => (m['value'] as double) > 0)
        .toList();

    if (data.isEmpty) {
      return const XCard(
        title: 'Komplain',
        subtitle: 'Belum ada data komplain pada range ini.',
        child: PiePlaceholder(height: 240),
      );
    }

    data.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    final total = data.fold<double>(0, (p, m) => p + (m['value'] as double));
    final safeTotal = total <= 0 ? 1.0 : total;

    const palette = <Color>[
      Color(0xFFEF4444),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
      Color(0xFF22C55E),
      Color(0xFF8B5CF6),
      Color(0xFF64748B),
    ];

    int touchedIndex = -1;

    return XCard(
      title: 'Komplain',
      subtitle: 'Komposisi komplain (${widget.range})',
      child: StatefulBuilder(
        builder: (context, setInner) {
          return LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 780;
              final size = isWide ? 260.0 : 240.0;

              final baseSections = <PieChartSectionData>[];
              for (int i = 0; i < data.length; i++) {
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

              final chart = SizedBox(
                width: size,
                height: size,
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
                                setInner(() => touchedIndex =
                                    resp!.touchedSection!.touchedSectionIndex);
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
                          'Total Komplain',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _toInt(safeTotal).toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  children: [
                    chart,
                    const SizedBox(width: 18),
                    Expanded(child: legend),
                  ],
                );
              }
              return Column(children: [chart, const SizedBox(height: 12), legend]);
            },
          );
        },
      ),
    );
  }

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
          final color = (data[i]['color'] ?? const Color(0xFF64748B)) as Color;

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
                        '${percent.toStringAsFixed(0)}% • ${_toInt(value)}',
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

  Widget _chartByMode({
    required TimChartMode mode,
    required Map<String, dynamic> data,
  }) {
    final trend = _extractTrend(data);

    final lb = (data['leaderboard_perawat'] is List)
        ? (data['leaderboard_perawat'] as List)
            .map((e) => (e is Map)
                ? Map<String, dynamic>.from(e)
                : <String, dynamic>{})
            .toList()
        : <Map<String, dynamic>>[];

    switch (mode) {
      case TimChartMode.lineOrders:
        return _lineOrdersChart(trend);
      case TimChartMode.barTopNurse:
        return _barTopNurseChart(lb);
      case TimChartMode.pieComplaints:
        return _pieComplaintsChart(data);
    }
  }

  // =========================================================
  // BUILD
  // =========================================================
  @override
  Widget build(BuildContext context) {
    final cols = widget.isDesktop ? 4 : 2;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final isLoading =
            snap.connectionState == ConnectionState.waiting && snap.data == null;
        final isError = snap.hasError && snap.data == null;

        final data = snap.data ?? {};
        final kpi = (data['kpi'] is Map)
            ? Map<String, dynamic>.from(data['kpi'])
            : <String, dynamic>{};

        final perawatAktif = _toInt(kpi['perawat_aktif']).toString();
        final koordinatorAktif = _toInt(kpi['koordinator_aktif']).toString();
        final dokterAktif = _toInt(kpi['dokter_aktif']).toString();
        final komplain = _toInt(kpi['komplain']).toString();

        final List lb = (data['leaderboard_perawat'] is List)
            ? data['leaderboard_perawat']
            : const [];

        final rows = lb.isNotEmpty
            ? lb.take(8).map((e) {
                final m = (e is Map)
                    ? Map<String, dynamic>.from(e)
                    : <String, dynamic>{};

                final r = _readRating(m);

                return [
                  (m['nama'] ?? '-').toString(),
                  _toInt(m['order']).toString(),
                  _ratingText(r), // ✅ bintang + angka (0..5)
                  rupiah(m['fee'], withPrefix: true), // ✅ Rp
                ];
              }).toList()
            : const <List<String>>[];

        if (isLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SectionHeader(
                title: 'Kinerja Tim',
                subtitle: 'Memuat data...',
              ),
              SizedBox(height: 12),
              LoadingCard(title: 'Kinerja Tim'),
            ],
          );
        }

        if (isError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Kinerja Tim',
                subtitle: 'Gagal memuat data (${widget.range}).',
              ),
              const SizedBox(height: 12),
              ErrorCard(
                title: 'Kinerja Tim',
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
              title: 'Kinerja Tim',
              subtitle: 'Performa perawat/koordinator/dokter (${widget.range}).',
            ),
            const SizedBox(height: 12),

            ResponsiveGrid(
              columns: cols,
              gap: 12,
              children: [
                KpiCard(
                  title: 'Perawat Aktif',
                  value: perawatAktif,
                  hint: widget.range,
                  icon: Icons.health_and_safety_outlined,
                  accent: const Color(0xFF0EA5E9),
                ),
                KpiCard(
                  title: 'Koordinator Aktif',
                  value: koordinatorAktif,
                  hint: widget.range,
                  icon: Icons.badge_outlined,
                  accent: const Color(0xFF0EA5E9),
                ),
                KpiCard(
                  title: 'Dokter Aktif',
                  value: dokterAktif,
                  hint: widget.range,
                  icon: Icons.medical_services_outlined,
                  accent: const Color(0xFF0EA5E9),
                ),
                KpiCard(
                  title: 'Komplain',
                  value: komplain,
                  hint: 'Butuh follow-up',
                  icon: Icons.report_outlined,
                  accent: const Color(0xFFDC2626),
                ),
              ],
            ),

            const SizedBox(height: 12),

            XCard(
              title: 'Visualisasi Kinerja',
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
              title: 'Leaderboard Perawat',
              subtitle: 'Produktivitas & rating (${widget.range}).',
              child: rows.isEmpty
                  ? const _EmptyBox(text: 'Belum ada data leaderboard pada range ini.')
                  : Column(
                      children: [
                        TableCard(
                          columns: const ['Nama', 'Order', 'Rating', 'Fee'],
                          rows: rows,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlineButtonX(
                            icon: Icons.download_outlined,
                            label: 'Export Kinerja Tim',
                            onTap: () => _exportTim(data),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 12),

            XCard(
              title: 'Aksi Manajerial',
              subtitle: 'Tombol aksi (nanti disambungkan).',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlineButtonX(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Bonus Tim',
                    onTap: () {},
                  ),
                  OutlineButtonX(
                    icon: Icons.rate_review_outlined,
                    label: 'Evaluasi Rating',
                    onTap: () {},
                  ),
                  OutlineButtonX(
                    icon: Icons.support_agent_outlined,
                    label: 'Follow-up Komplain',
                    onTap: () {},
                  ),
                  OutlineButtonX(
                    icon: Icons.schedule_outlined,
                    label: 'Atur Jadwal',
                    onTap: () {},
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
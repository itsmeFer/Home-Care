import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_care/ITDev/pages/system_maintenance_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/ui_components.dart';

class DashboardITPage extends StatefulWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const DashboardITPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<DashboardITPage> createState() => _DashboardITPageState();
}

class _DashboardITPageState extends State<DashboardITPage> {
  static const String kBaseUrl = 'http://192.168.1.5:8000';
  String get kApiBase => '$kBaseUrl/api';
  Timer? _timer;
  Future<Map<String, dynamic>>? _metricsFuture;

  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    _metricsFuture = _fetchMetrics();

    // optional live refresh tiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _metricsFuture = _fetchMetrics();
      });
    });
  }

  @override
  void didUpdateWidget(covariant DashboardITPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) {
      setState(() {
        _future = _fetch();
        _metricsFuture = _fetchMetrics();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _fetch();
      _metricsFuture = _fetchMetrics();
    });
  }

  // =========================
  // FETCH
  // =========================
  String _buildUrl() {
    return Uri.parse(
      '$kApiBase/it/dashboard/overview',
    ).replace(queryParameters: {'range': widget.range}).toString();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
            .trim();
    if (token.isEmpty) throw Exception('Token kosong. Silakan login ulang.');

    final res = await http.get(
      Uri.parse(_buildUrl()),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data'] as Map);
    }

    throw Exception('Format response tidak sesuai.');
  }

  String _buildMetricsUrl() {
    return Uri.parse(
      '$kApiBase/it/dashboard/metrics',
    ).replace(queryParameters: {'range': widget.range}).toString();
  }

  Future<Map<String, dynamic>> _fetchMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
            .trim();
    if (token.isEmpty) throw Exception('Token kosong. Silakan login ulang.');

    final res = await http.get(
      Uri.parse(_buildMetricsUrl()),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data'] as Map);
    }
    throw Exception('Format response metrics tidak sesuai.');
  }

  // =========================
  // HELPERS
  // =========================
  String _s(dynamic v, [String fb = '-']) {
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

  String _fmtInt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final left = s.length - i;
      buf.write(s[i]);
      if (left > 1 && left % 3 == 1) buf.write('.');
    }
    return buf.toString();
  }

  String _fmtBytes(dynamic bytes) {
    final b = (bytes is num) ? bytes.toDouble() : double.tryParse('$bytes');
    if (b == null) return '-';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double x = b;
    int u = 0;
    while (x >= 1024 && u < units.length - 1) {
      x /= 1024;
      u++;
    }
    final v = x >= 100 ? x.toStringAsFixed(0) : x.toStringAsFixed(1);
    return '$v ${units[u]}';
  }

  double? _pct(dynamic used, dynamic total) {
    final u = (used is num) ? used.toDouble() : double.tryParse('$used');
    final t = (total is num) ? total.toDouble() : double.tryParse('$total');
    if (u == null || t == null || t <= 0) return null;
    return (u / t) * 100.0;
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final cols = widget.isDesktop ? 3 : 2;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final loading =
            snap.connectionState != ConnectionState.done && snap.data == null;
        final error = snap.hasError && snap.data == null;

        if (loading) {
          return const _LoadingCardX(title: 'System Health');
        }

        if (error) {
          return _ErrorCardX(
            title: 'System Health',
            message: snap.error.toString(),
            onRetry: _reload,
          );
        }

        final data = snap.data ?? {};
        final rangeLabel = _s(data['range'], widget.range);

        final sys = (data['system_health'] is Map)
            ? Map<String, dynamic>.from(data['system_health'])
            : <String, dynamic>{};

        final api = (sys['api'] is Map)
            ? Map<String, dynamic>.from(sys['api'])
            : <String, dynamic>{};

        final storage = (sys['storage'] is Map)
            ? Map<String, dynamic>.from(sys['storage'])
            : <String, dynamic>{};

        final queue = (sys['queue'] is Map)
            ? Map<String, dynamic>.from(sys['queue'])
            : <String, dynamic>{};

        final maintenance = (sys['maintenance'] is Map)
            ? Map<String, dynamic>.from(sys['maintenance'])
            : <String, dynamic>{};

        final stats = (data['stats'] is Map)
            ? Map<String, dynamic>.from(data['stats'])
            : <String, dynamic>{};

        final apiStatus = _s(api['status'], 'up').toLowerCase() == 'up';
        final apiName = _s(api['app_name'], 'HomeCare API');
        final apiEnv = _s(api['env'], 'production');
        final apiVersion = _s(api['version'], 'unknown');
        final serverTime = _s(api['server_time'], '-');

        final reqCount = _i(
          stats['sessions_total'],
        ); // fallback (kalau belum ada request_count)
        final err5xx = _i(
          queue['failed_jobs'],
        ); // queue failed sebagai indikator error berat
        final err4xx = _i(
          stats['audit_medium'],
        ); // indikator (bukan real 4xx), nanti bisa kamu ganti

        final frozenUsers = _i(stats['frozen_users']);
        final tokensTotal = _i(stats['tokens_total']);
        final sessionsTotal = _i(stats['sessions_total']);

        final diskTotal = storage['disk_total_bytes'];
        final diskUsed = storage['disk_used_bytes'];
        final diskFree = storage['disk_free_bytes'];

        final pct = _pct(diskUsed, diskTotal);
        final storagePctLabel = (pct == null)
            ? '-'
            : '${pct.toStringAsFixed(0)}%';

        final maintEnabled = maintenance['enabled'] == true;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'System Health',
              subtitle: 'Status teknis sistem • $rangeLabel',
            ),
            const SizedBox(height: 12),

            ResponsiveGrid(
              columns: cols,
              gap: 12,
              children: [
                KpiCard(
                  title: 'API Status',
                  value: apiStatus ? 'UP' : 'DOWN',
                  hint: apiName,
                  icon: apiStatus
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  accent: apiStatus
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                KpiCard(
                  title: 'Sessions',
                  value: _fmtInt(sessionsTotal),
                  hint: 'Estimasi aktivitas',
                  icon: Icons.swap_horiz_rounded,
                  accent: const Color(0xFF0EA5E9),
                ),
                KpiCard(
                  title: 'Queue Failed',
                  value: _fmtInt(_i(queue['failed_jobs'])),
                  hint: 'failed_jobs',
                  icon: Icons.queue_play_next_outlined,
                  accent: const Color(0xFF7C3AED),
                ),
                KpiCard(
                  title: 'Audit (High)',
                  value: _fmtInt(_i(stats['audit_high'])),
                  hint: 'risk high',
                  icon: Icons.policy_outlined,
                  accent: const Color(0xFFDC2626),
                ),
                KpiCard(
                  title: 'Frozen Users',
                  value: _fmtInt(frozenUsers),
                  hint: 'emergency freeze',
                  icon: Icons.lock_outline,
                  accent: const Color(0xFFF59E0B),
                ),
                KpiCard(
                  title: 'Storage Usage',
                  value: storagePctLabel,
                  hint: '${_fmtBytes(diskUsed)} / ${_fmtBytes(diskTotal)}',
                  icon: Icons.storage_outlined,
                  accent: const Color(0xFF334155),
                ),
              ],
            ),
            const SizedBox(height: 12),

            XCard(
              title: 'Grafik Server',
              subtitle: 'Live (auto refresh 5 detik)',
              child: FutureBuilder<Map<String, dynamic>>(
                future: _metricsFuture,
                builder: (context, s) {
                  if (s.connectionState != ConnectionState.done &&
                      s.data == null) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Memuat grafik...'),
                    );
                  }
                  if (s.hasError && s.data == null) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Error: ${s.error}'),
                    );
                  }

                  final m = s.data ?? {};
                  final points = (m['points'] is List)
                      ? (m['points'] as List)
                      : const [];
                  if (points.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Belum ada data grafik (points kosong).'),
                    );
                  }

                  // contoh parsing: [{label, request_count, error_4xx, error_5xx}]
                  final req = <FlSpot>[];
                  final e4 = <FlSpot>[];
                  final e5 = <FlSpot>[];

                  for (int i = 0; i < points.length; i++) {
                    final row = Map<String, dynamic>.from(points[i] as Map);
                    req.add(
                      FlSpot(i.toDouble(), _i(row['traffic']).toDouble()),
                    );
                    e4.add(
                      FlSpot(i.toDouble(), _i(row['risk_medium']).toDouble()),
                    );
                    e5.add(
                      FlSpot(i.toDouble(), _i(row['risk_high']).toDouble()),
                    );
                  }
                  final showDots =
                      req.length < 2; // kalau cuma 1 titik, tampilkan dot

                  return SizedBox(
                    height: 240,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: req,
                            isCurved: true,
                            barWidth: 3,
                            color: const Color(0xFF0EA5E9), // biru
                            dotData: FlDotData(show: showDots),
                          ),
                          LineChartBarData(
                            spots: e4,
                            isCurved: true,
                            barWidth: 2,
                            color: const Color(0xFFF59E0B), // kuning
                            dotData: FlDotData(show: showDots),
                          ),
                          LineChartBarData(
                            spots: e5,
                            isCurved: true,
                            barWidth: 2,
                            color: const Color(0xFFDC2626), // merah
                            dotData: FlDotData(show: showDots),
                          ),
                        ],

                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            XCard(
              title: 'Versi Aplikasi',
              subtitle: 'Info build dari server.',
              child: Column(
                children: [
                  _InfoRow(k: 'App Name', v: apiName),
                  _InfoRow(k: 'Environment', v: apiEnv),
                  _InfoRow(k: 'API Version', v: apiVersion),
                  _InfoRow(k: 'Server Time', v: serverTime),
                  _InfoRow(k: 'Maintenance', v: maintEnabled ? 'ON' : 'OFF'),
                  _InfoRow(k: 'Disk Free', v: _fmtBytes(diskFree)),
                  _InfoRow(k: 'Tokens Total', v: _fmtInt(tokensTotal)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            XCard(
              title: 'Quick Actions',
              subtitle: 'Aksi IT (sementara read-only).',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlineButtonX(
                    icon: Icons.refresh_rounded,
                    label: 'Refresh',
                    onTap: _reload,
                  ),
                  OutlineButtonX(
                    icon: Icons.health_and_safety_outlined,
                    label: maintEnabled
                        ? 'Maintenance: ON'
                        : 'Maintenance: OFF',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            body: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SystemMaintenancePage(
                                isDesktop: widget.isDesktop,
                                isTablet: widget.isTablet,
                                range: widget.range,
                              ),
                            ),
                          ),
                        ),
                      );

                      // setelah balik dari halaman maintenance, refresh biar status dashboard update
                      _reload();
                    },
                  ),

                  OutlineButtonX(
                    icon: Icons.search_rounded,
                    label: 'Open Audit',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Buka tab Audit Sistem (menu).'),
                        ),
                      );
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
}

class _InfoRow extends StatelessWidget {
  final String k;
  final String v;
  const _InfoRow({required this.k, required this.v});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            v,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== local loading & error =====
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

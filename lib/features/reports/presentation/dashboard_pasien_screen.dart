import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/direktur/widgets/ui_components.dart';

class DashboardPasienScreen extends StatefulWidget {
  final String role;
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const DashboardPasienScreen({
    super.key,
    required this.role,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  State<DashboardPasienScreen> createState() => _DashboardPasienScreenState();
}

class _DashboardPasienScreenState extends State<DashboardPasienScreen>
    with SingleTickerProviderStateMixin {
  String get kBaseUrl => ApiConstants.baseUrl;
  String get kApiBase => ApiConstants.apiBase;

  String get _url =>
      '$kApiBase/${widget.role}/dashboard/pasien?range=${Uri.encodeComponent(widget.range)}';

  Future<Map<String, dynamic>>? _future;

  late final AnimationController _chartCtrl;
  late final Animation<double> _t;

  static const Color _cPrimary = Color(0xFF06B6D4);
  static const Color _cGreen = Color(0xFF22C55E);
  static const Color _cAmber = Color(0xFFF59E0B);
  static const Color _grid = Color(0xFFE2E8F0);
  static const Color _axis = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _future = _fetch();

    _chartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _t = CurvedAnimation(parent: _chartCtrl, curve: Curves.easeOutCubic);
    _chartCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant DashboardPasienScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range || oldWidget.role != widget.role) {
      setState(() {
        _future = _fetch();
        _chartCtrl.forward(from: 0.0);
      });
    }
  }

  @override
  void dispose() {
    _chartCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
        .trim();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse(_url),
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      final j = jsonDecode(res.body);
      if (j is Map<String, dynamic>) {
        if (j['data'] is Map<String, dynamic>) {
          return j['data'] as Map<String, dynamic>;
        }
        return j;
      }
    }
    throw Exception('Gagal memuat data (${res.statusCode})');
  }

  num _n(dynamic v) => (v is num) ? v : (num.tryParse(v?.toString() ?? '') ?? 0);

  String _formatK(num val) {
    final n = val.toDouble();
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toStringAsFixed(0);
  }

  Widget _loading() => const Center(
        child: Padding(
          padding: EdgeInsets.all(28.0),
          child: CircularProgressIndicator(),
        ),
      );

  Widget _error(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 10),
              Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => setState(() => _future = _fetch()),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _loading();
        }
        if (snap.hasError) {
          return _error(snap.error.toString());
        }

        final data = snap.data ?? {};
        final kpi = (data['kpi'] is Map)
            ? Map<String, dynamic>.from(data['kpi'] as Map)
            : <String, dynamic>{};
        final charts = (data['charts'] is Map)
            ? Map<String, dynamic>.from(data['charts'] as Map)
            : <String, dynamic>{};
        final lists = (data['lists'] is Map)
            ? Map<String, dynamic>.from(data['lists'] as Map)
            : <String, dynamic>{};

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Demografi & Pola Pasien',
                subtitle:
                    'Analisis pertumbuhan, demografi usia, dan segmentasi pasien (${widget.range}).',
              ),
              const SizedBox(height: 16),

              _buildKpiGrid(kpi),
              const SizedBox(height: 20),

              _buildCharts(charts),
              const SizedBox(height: 20),

              _buildLists(lists),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> kpi) {
    final total = _n(kpi['total_pasien']);
    final baru = _n(kpi['pasien_baru']);
    final aktif = _n(kpi['pasien_aktif']);
    final retention = _n(kpi['retention_rate']);

    final cards = [
      KpiCard(
        title: 'Total Pasien',
        value: _formatK(total),
        hint: 'Terdaftar di sistem',
        icon: Icons.groups_outlined,
        accent: _cPrimary,
      ),
      KpiCard(
        title: 'Pasien Baru',
        value: _formatK(baru),
        hint: 'Dalam periode ini',
        icon: Icons.person_add_alt_1_outlined,
        accent: _cGreen,
      ),
      KpiCard(
        title: 'Pasien Aktif',
        value: _formatK(aktif),
        hint: 'Memiliki kunjungan',
        icon: Icons.how_to_reg_outlined,
        accent: _cAmber,
      ),
      KpiCard(
        title: 'Retention Rate',
        value: '${retention.toStringAsFixed(1)}%',
        hint: 'Pasien repeat order',
        icon: Icons.repeat_rounded,
        accent: const Color(0xFF8B5CF6),
      ),
    ];

    final crossAxisCount = widget.isDesktop
        ? 4
        : (widget.isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: widget.isDesktop ? 1.8 : 2.2,
      children: cards,
    );
  }

  Widget _buildCharts(Map<String, dynamic> charts) {
    final trendRaw = charts['trend_pendaftaran'];
    final genderRaw = charts['gender_distribution'];
    final ageRaw = charts['age_distribution'];

    final trend = (trendRaw is List)
        ? trendRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final gender = (genderRaw is Map)
        ? Map<String, dynamic>.from(genderRaw)
        : <String, dynamic>{};

    final age = (ageRaw is List)
        ? ageRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    final chartA = XCard(
      title: 'Tren Pertumbuhan Pasien',
      subtitle: 'Grafik penambahan pasien baru per periode',
      child: SizedBox(
        height: 240,
        child: trend.isEmpty
            ? const Center(child: Text('Data tren belum tersedia.'))
            : AnimatedBuilder(
                animation: _t,
                builder: (context, _) => LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          const FlLine(color: _grid, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, meta) => Text(
                            v.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: _axis),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx >= 0 && idx < trend.length) {
                              final label = trend[idx]['label'] ?? '';
                              return Text(
                                label.toString(),
                                style: const TextStyle(fontSize: 10, color: _axis),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: _cPrimary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        spots: List.generate(trend.length, (i) {
                          final val = _n(trend[i]['total']).toDouble();
                          return FlSpot(i.toDouble(), val * _t.value);
                        }),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );

    final chartB = XCard(
      title: 'Distribusi Gender',
      subtitle: 'Perbandingan pasien pria & wanita',
      child: SizedBox(
        height: 240,
        child: gender.isEmpty
            ? const Center(child: Text('Data gender belum tersedia.'))
            : PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: _n(gender['L']).toDouble(),
                      title: 'Pria',
                      color: _cPrimary,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: _n(gender['P']).toDouble(),
                      title: 'Wanita',
                      color: const Color(0xFFEC4899),
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );

    final chartC = XCard(
      title: 'Kelompok Usia Pasien',
      subtitle: 'Kategori usia penerima layanan',
      child: SizedBox(
        height: 240,
        child: age.isEmpty
            ? const Center(child: Text('Data kelompok usia belum tersedia.'))
            : BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx >= 0 && idx < age.length) {
                            return Text(
                              age[idx]['range']?.toString() ?? '',
                              style: const TextStyle(fontSize: 10, color: _axis),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(age.length, (i) {
                    final val = _n(age[i]['total']).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          color: _cAmber,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
      ),
    );

    if (widget.isDesktop) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: chartA),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: chartB),
            ],
          ),
          const SizedBox(height: 16),
          chartC,
        ],
      );
    }

    return Column(
      children: [
        chartA,
        const SizedBox(height: 14),
        chartB,
        const SizedBox(height: 14),
        chartC,
      ],
    );
  }

  Widget _buildLists(Map<String, dynamic> lists) {
    final topFrequentRaw = lists['top_frequent_patients'];
    final topFrequent = (topFrequentRaw is List)
        ? topFrequentRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    return XCard(
      title: 'Pasien Paling Sering Berkunjung (Top Patients)',
      subtitle: 'Pasien dengan total kunjungan / pesanan terbanyak',
      child: topFrequent.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Belum ada data kunjungan pasien.')),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(topFrequent.length, 10),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final p = topFrequent[idx];
                final nama = p['nama']?.toString() ?? 'Pasien #${idx + 1}';
                final totalOrder = _n(p['total_order']);
                final totalSpent = _n(p['total_biaya']);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _cPrimary.withOpacity(0.12),
                    child: Text(
                      '#${idx + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _cPrimary,
                      ),
                    ),
                  ),
                  title: Text(
                    nama,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('$totalOrder kunjungan tercatat'),
                  trailing: Text(
                    'Rp ${totalSpent.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _cGreen,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/kordinator/lihatDetailOrderanMasuk.dart';

const String kBaseUrl = 'http://147.93.81.243/api';

class OrderKoordinator {
  final int id;
  final String kodeOrder;
  final String statusOrder;
  final String namaLayanan;
  final String? tanggalMulai;
  final String? jamMulai;
  final Map<String, dynamic>? pasien;
  final Map<String, dynamic>? perawat;

  OrderKoordinator({
    required this.id,
    required this.kodeOrder,
    required this.statusOrder,
    required this.namaLayanan,
    this.tanggalMulai,
    this.jamMulai,
    this.pasien,
    this.perawat,
  });

  factory OrderKoordinator.fromJson(Map<String, dynamic> json) {
    return OrderKoordinator(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      kodeOrder: json['kode_order']?.toString() ?? '-',
      statusOrder: json['status_order']?.toString() ?? 'pending',
      namaLayanan: json['nama_layanan']?.toString() ??
          (json['layanan']?['nama_layanan']?.toString() ?? '-'),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      jamMulai: json['jam_mulai']?.toString(),
      pasien: json['pasien'] is Map<String, dynamic>
          ? json['pasien'] as Map<String, dynamic>
          : null,
      perawat: json['perawat'] is Map<String, dynamic>
          ? json['perawat'] as Map<String, dynamic>
          : null,
    );
  }
}

class LihatOrderanMasukKoordinatorPage extends StatefulWidget {
  const LihatOrderanMasukKoordinatorPage({super.key});

  @override
  State<LihatOrderanMasukKoordinatorPage> createState() =>
      _LihatOrderanMasukKoordinatorPageState();
}

class _LihatOrderanMasukKoordinatorPageState
    extends State<LihatOrderanMasukKoordinatorPage> {
  bool _isLoading = true;
  String? _error;
  List<OrderKoordinator> _orders = [];

  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _tanggalDari;
  DateTime? _tanggalSampai;

  final List<String> _statusOptions = const [
    'pending',
    'menunggu_penugasan',
    'mendapatkan_perawat',
    'selesai',
    'dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Token tidak ditemukan. Silakan login sebagai koordinator.';
        });
        return;
      }

      final Map<String, String> queryParams = {};

      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        queryParams['status'] = _selectedStatus!;
      }

      final keyword = _searchController.text.trim();
      if (keyword.isNotEmpty) {
        queryParams['search'] = keyword;
      }

      if (_tanggalDari != null) {
        queryParams['tanggal_mulai_dari'] =
            DateFormat('yyyy-MM-dd').format(_tanggalDari!);
      }

      if (_tanggalSampai != null) {
        queryParams['tanggal_mulai_sampai'] =
            DateFormat('yyyy-MM-dd').format(_tanggalSampai!);
      }

      final uri = Uri.parse('$kBaseUrl/koordinator/order-layanan')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final success = decoded['success'] == true;

        if (!success) {
          setState(() {
            _isLoading = false;
            _error =
                decoded['message']?.toString() ?? 'Gagal memuat data order.';
          });
          return;
        }

        final List<dynamic> data = decoded['data'] ?? [];
        final list = data
            .whereType<Map>()
            .map((e) => OrderKoordinator.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        setState(() {
          _isLoading = false;
          _orders = list;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login koordinator berakhir. Silakan login ulang.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _error =
              'Gagal memuat data. Kode: ${response.statusCode} ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  String _formatTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return iso;
    }
  }

  String _formatJam(String? jam) {
    if (jam == null || jam.isEmpty) return '-';
    if (jam.length >= 5) return jam.substring(0, 5);
    return jam;
  }

  String _getNama(Map<String, dynamic>? obj) {
    if (obj == null) return '-';
    return obj['nama']?.toString() ??
        obj['nama_lengkap']?.toString() ??
        obj['full_name']?.toString() ??
        '-';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'menunggu_penugasan':
        return Colors.deepOrange;
      case 'mendapatkan_perawat':
        return Colors.blue;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'menunggu_penugasan':
        return 'Menunggu Penugasan';
      case 'mendapatkan_perawat':
        return 'Mendapatkan Perawat';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _tanggalFilterLabel() {
    if (_tanggalDari == null && _tanggalSampai == null) {
      return 'Semua tanggal';
    }

    final fmt = DateFormat('dd MMM yyyy');

    if (_tanggalDari != null && _tanggalSampai != null) {
      return '${fmt.format(_tanggalDari!)} - ${fmt.format(_tanggalSampai!)}';
    }
    if (_tanggalDari != null) {
      return 'Mulai ${fmt.format(_tanggalDari!)}';
    }
    return 'Sampai ${fmt.format(_tanggalSampai!)}';
  }

  Future<void> _pickTanggalRange() async {
    final now = DateTime.now();
    final initialStart = _tanggalDari ?? now.subtract(const Duration(days: 7));
    final initialEnd = _tanggalSampai ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Pilih rentang tanggal order',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null) {
      setState(() {
        _tanggalDari = picked.start;
        _tanggalSampai = picked.end;
      });
      _fetchOrders();
    }
  }

  void _clearTanggalFilter() {
    setState(() {
      _tanggalDari = null;
      _tanggalSampai = null;
    });
    _fetchOrders();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
    _fetchOrders();
  }

  int get _totalPending =>
      _orders.where((e) => e.statusOrder == 'pending').length;

  int get _totalAktif => _orders
      .where((e) =>
          e.statusOrder == 'menunggu_penugasan' ||
          e.statusOrder == 'mendapatkan_perawat')
      .length;

  int get _totalSelesai =>
      _orders.where((e) => e.statusOrder == 'selesai').length;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width >= 900 ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Order Masuk'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            20,
          ),
          children: [
            _buildStatsSection(),
            const SizedBox(height: 14),
            _buildFilterSection(),
            const SizedBox(height: 14),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;

        final cards = [
          _MiniStatCard(
            title: 'Pending',
            value: _totalPending.toString(),
            icon: Icons.pending_actions_outlined,
            color: Colors.orange,
          ),
          _MiniStatCard(
            title: 'Aktif',
            value: _totalAktif.toString(),
            icon: Icons.assignment_turned_in_outlined,
            color: Colors.blue,
          ),
          _MiniStatCard(
            title: 'Selesai',
            value: _totalSelesai.toString(),
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ]
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 12),
            cards[2],
          ],
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;

          final searchField = TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF4F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              hintText: 'Cari kode order / pasien / perawat / layanan',
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _fetchOrders(),
          );

          final dateButton = OutlinedButton.icon(
            onPressed: _pickTanggalRange,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _tanggalFilterLabel(),
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          final statusDropdown = DropdownButtonFormField<String>(
            value: _selectedStatus,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF4F7FA),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            hint: const Text('Semua status'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua status'),
              ),
              ..._statusOptions.map(
                (s) => DropdownMenuItem<String>(
                  value: s,
                  child: Text(_statusLabel(s)),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
              _fetchOrders();
            },
          );

          if (isWide) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 2, child: searchField),
                    const SizedBox(width: 12),
                    Expanded(child: dateButton),
                    if (_tanggalDari != null || _tanggalSampai != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Hapus filter tanggal',
                        onPressed: _clearTanggalFilter,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: statusDropdown),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _fetchOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0BA5A7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Column(
            children: [
              searchField,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: dateButton),
                  if (_tanggalDari != null || _tanggalSampai != null)
                    IconButton(
                      tooltip: 'Hapus filter tanggal',
                      onPressed: _clearTanggalFilter,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              statusDropdown,
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _fetchOrders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0BA5A7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _fetchOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0BA5A7),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 52,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Belum ada order masuk untuk koordinator ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isGrid = constraints.maxWidth >= 900;

        if (isGrid) {
          return GridView.builder(
            itemCount: _orders.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (context, index) {
              return _buildOrderCard(_orders[index]);
            },
          );
        }

        return ListView.builder(
          itemCount: _orders.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderCard(_orders[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderCard(OrderKoordinator order) {
    final tanggal = _formatTanggal(order.tanggalMulai);
    final jam = _formatJam(order.jamMulai);
    final pasienNama = _getNama(order.pasien);
    final perawatNama = _getNama(order.perawat);
    final statusColor = _statusColor(order.statusOrder);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailOrderKoordinatorPage(orderId: order.id),
            ),
          );

          if (result == true) {
            _fetchOrders();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.kodeOrder,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(order.statusOrder),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                order.namaLayanan,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _metaChip(Icons.calendar_today_outlined, tanggal),
                  _metaChip(Icons.access_time_outlined, jam),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 1,
                color: Colors.black.withValues(alpha: 0.06),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Pasien', pasienNama),
              const SizedBox(height: 6),
              _buildInfoRow('Perawat', perawatNama),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
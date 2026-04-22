import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/admin/lihatDetailLayananMasuk.dart';

const String kBaseUrl = 'http://192.168.1.5:8000/api';

class HCColor {
  static const primary = Color(0xFF0BA5A7);
  static const primaryDark = Color(0xFF088088);
  static const bg = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textMuted = Colors.black54;
  static const lightTeal = Color(0xFFE0F7F7);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

class OrderLayananAdmin {
  final int id;
  final String kodeOrder;
  final String statusOrder;
  final String namaLayanan;

  final String? tanggalMulai;
  final String? jamMulai;

  final Map<String, dynamic>? pasien;
  final Map<String, dynamic>? koordinator;
  final Map<String, dynamic>? perawat;

  OrderLayananAdmin({
    required this.id,
    required this.kodeOrder,
    required this.statusOrder,
    required this.namaLayanan,
    this.tanggalMulai,
    this.jamMulai,
    this.pasien,
    this.koordinator,
    this.perawat,
  });

  factory OrderLayananAdmin.fromJson(Map<String, dynamic> json) {
    return OrderLayananAdmin(
      id: json['id'] as int,
      kodeOrder: json['kode_order']?.toString() ?? '-',
      statusOrder: json['status_order']?.toString() ?? 'pending',
      namaLayanan: json['nama_layanan']?.toString() ??
          (json['layanan']?['nama_layanan']?.toString() ?? '-'),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      jamMulai: json['jam_mulai']?.toString(),
      pasien: json['pasien'] as Map<String, dynamic>?,
      koordinator: json['koordinator'] as Map<String, dynamic>?,
      perawat: json['perawat'] as Map<String, dynamic>?,
    );
  }
}

class LihatLayananMasukPage extends StatefulWidget {
  const LihatLayananMasukPage({Key? key}) : super(key: key);

  @override
  State<LihatLayananMasukPage> createState() => _LihatLayananMasukPageState();
}

class _LihatLayananMasukPageState extends State<LihatLayananMasukPage> {
  bool _isLoading = true;
  String? _error;
  List<OrderLayananAdmin> _orders = [];

  String? _selectedStatus;

  final List<String> _statusOptions = const [
    'pending',
    'menunggu_penugasan',
    'mendapatkan_perawat',
    'sedang_dalam_perjalanan',
    'sampai_ditempat',
    'sedang_berjalan',
    'selesai',
    'dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Token tidak ditemukan. Silakan login sebagai admin.';
        });
        return;
      }

      String url = '$kBaseUrl/admin/order-layanan';
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        url += '?status=$_selectedStatus';
      }

      final uri = Uri.parse(url);

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
            _error = decoded['message']?.toString() ??
                'Gagal memuat data order layanan.';
          });
          return;
        }

        final List<dynamic> data = decoded['data'] ?? [];
        final list = data.map((e) => OrderLayananAdmin.fromJson(e)).toList();

        setState(() {
          _isLoading = false;
          _orders = list;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login admin berakhir. Silakan login ulang.';
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

  String _fmtTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return iso;
    }
  }

  String _fmtJam(String? jam) {
    if (jam == null || jam.isEmpty) return '-';
    if (jam.length >= 5) {
      return jam.substring(0, 5);
    }
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
        return HCColor.warning;
      case 'menunggu_penugasan':
        return Colors.deepOrange;
      case 'mendapatkan_perawat':
        return Colors.blue;
      case 'sedang_dalam_perjalanan':
        return Colors.teal;
      case 'sampai_ditempat':
        return Colors.indigo;
      case 'sedang_berjalan':
        return Colors.purple;
      case 'selesai':
        return HCColor.success;
      case 'dibatalkan':
        return HCColor.error;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'menunggu_penugasan':
        return 'Belum Ditugaskan';
      case 'mendapatkan_perawat':
        return 'Menunggu Respon';
      case 'sedang_dalam_perjalanan':
        return 'Dalam Perjalanan';
      case 'sampai_ditempat':
        return 'Sudah Sampai';
      case 'sedang_berjalan':
        return 'Sedang Berjalan';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildFilters()),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: HCColor.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Layanan Masuk',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [HCColor.primary, HCColor.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh',
          onPressed: _fetchOrders,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 20, color: HCColor.primary),
              const SizedBox(width: 8),
              const Text(
                'Filter Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: HCColor.lightTeal.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(Icons.assignment, color: HCColor.primary, size: 20),
            ),
            hint: const Text('Semua Status'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua status'),
              ),
              ..._statusOptions.map(
                (s) => DropdownMenuItem<String>(
                  value: s,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor(s),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_statusLabel(s)),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
              _fetchOrders();
            },
          ),
          const SizedBox(height: 12),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _orders.length;
    final pending = _orders.where((o) => o.statusOrder == 'pending').length;
    final selesai = _orders.where((o) => o.statusOrder == 'selesai').length;

    return Row(
      children: [
        _buildStatCard('Total', total.toString(), HCColor.primary),
        const SizedBox(width: 8),
        _buildStatCard('Pending', pending.toString(), HCColor.warning),
        const SizedBox(width: 8),
        _buildStatCard('Selesai', selesai.toString(), HCColor.success),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: HCColor.primary),
              SizedBox(height: 16),
              Text('Memuat data...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: _buildError(),
      );
    }

    if (_orders.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmpty(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderCard(_orders[index]),
            );
          },
          childCount: _orders.length,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: HCColor.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HCColor.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: HCColor.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada order layanan',
            style: TextStyle(
              fontSize: 16,
              color: HCColor.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus != null
                ? 'Tidak ada order dengan status ini'
                : 'Order akan muncul di sini',
            style: TextStyle(
              fontSize: 13,
              color: HCColor.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderLayananAdmin order) {
    final tanggal = _fmtTanggal(order.tanggalMulai);
    final jam = _fmtJam(order.jamMulai);

    final pasienNama = _getNama(order.pasien);
    final koordinatorNama = _getNama(order.koordinator);
    final perawatNama = _getNama(order.perawat);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final needRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailOrderLayananAdminPage(orderId: order.id),
              ),
            );

            if (needRefresh == true) {
              _fetchOrders();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: HCColor.lightTeal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.medical_services,
                        color: HCColor.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.kodeOrder,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.namaLayanan,
                            style: TextStyle(
                              fontSize: 13,
                              color: HCColor.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(order.statusOrder).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _statusColor(order.statusOrder).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _statusLabel(order.statusOrder),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(order.statusOrder),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Date & Time
                Row(
                  children: [
                    _buildMetaChip(Icons.calendar_today, tanggal),
                    const SizedBox(width: 8),
                    _buildMetaChip(Icons.access_time, jam),
                  ],
                ),

                const SizedBox(height: 12),

                // Info rows
                _buildInfoRow(Icons.person, 'Pasien', pasienNama),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.supervisor_account, 'Koordinator',
                    koordinatorNama),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.local_hospital, 'Perawat', perawatNama),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: HCColor.lightTeal.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: HCColor.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: HCColor.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 12,
            color: HCColor.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
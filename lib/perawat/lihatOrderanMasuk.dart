import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/perawat/lihatDetailOrderanMasuk.dart';

const String kBaseUrl = 'http://192.168.1.6:8000/api';

/// Model order untuk perawat
class OrderLayananPerawat {
  final int id;
  final String kodeOrder;
  final String statusOrder;
  final String namaLayanan;

  final String? tanggalMulai; // yyyy-MM-dd
  final String? jamMulai; // HH:mm:ss / HH:mm

  final Map<String, dynamic>? pasien;
  final Map<String, dynamic>? koordinator;

  OrderLayananPerawat({
    required this.id,
    required this.kodeOrder,
    required this.statusOrder,
    required this.namaLayanan,
    this.tanggalMulai,
    this.jamMulai,
    this.pasien,
    this.koordinator,
  });

  factory OrderLayananPerawat.fromJson(Map<String, dynamic> json) {
    return OrderLayananPerawat(
      id: json['id'] as int,
      kodeOrder: json['kode_order']?.toString() ?? '-',
      statusOrder: json['status_order']?.toString() ?? 'pending',
      namaLayanan: json['nama_layanan']?.toString() ??
          (json['layanan']?['nama_layanan']?.toString() ?? '-'),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      jamMulai: json['jam_mulai']?.toString(),
      pasien: json['pasien'] as Map<String, dynamic>?,
      koordinator: json['koordinator'] as Map<String, dynamic>?,
    );
  }
}

class LihatOrderanMasukPerawatPage extends StatefulWidget {
  const LihatOrderanMasukPerawatPage({Key? key}) : super(key: key);

  @override
  State<LihatOrderanMasukPerawatPage> createState() =>
      _LihatOrderanMasukPerawatPageState();
}

class _LihatOrderanMasukPerawatPageState
    extends State<LihatOrderanMasukPerawatPage> {
  bool _isLoading = true;
  String? _error;
  List<OrderLayananPerawat> _orders = [];

  // filter status
  String? _selectedStatus;

  // 🔍 keyword search
  final TextEditingController _searchController = TextEditingController();

  // 📅 filter tanggal (range)
  DateTime? _tanggalDari;
  DateTime? _tanggalSampai;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Token tidak ditemukan. Silakan login sebagai perawat.';
        });
        return;
      }

      // 🔥 susun query parameter dinamis
      final Map<String, String> queryParams = {};

      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        queryParams['status'] = _selectedStatus!;
      }

      final keyword = _searchController.text.trim();
      if (keyword.isNotEmpty) {
        // pastikan backend index() perawat sudah support ?search=
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

      Uri uri;
      if (queryParams.isEmpty) {
        uri = Uri.parse('$kBaseUrl/perawat/order-layanan');
      } else {
        uri = Uri.parse('$kBaseUrl/perawat/order-layanan')
            .replace(queryParameters: queryParams);
      }

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
                'Gagal memuat orderan untuk perawat.';
          });
          return;
        }

        final List<dynamic> data = decoded['data'] ?? [];
        final list = data
            .map((e) => OrderLayananPerawat.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _isLoading = false;
          _orders = list;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login perawat berakhir. Silakan login ulang.';
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
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return iso;
    }
  }

  String _formatJam(String? jam) {
    if (jam == null || jam.isEmpty) return '-';
    if (jam.length >= 5) {
      return jam.substring(0, 5);
    }
    return jam;
  }

  String _getNama(Map<String, dynamic>? obj) {
    if (obj == null) return '-';
    return obj['nama_lengkap']?.toString() ??
        obj['nama']?.toString() ??
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
      case 'sedang_dalam_perjalanan':
        return Colors.teal;
      case 'sampai_ditempat':
        return Colors.indigo;
      case 'sedang_berjalan':
        return Colors.purple;
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
        return 'Menunggu Konfirmasi';
      case 'menunggu_penugasan':
        return 'Menunggu Penugasan';
      case 'mendapatkan_perawat':
        return 'Menunggu Respon Perawat';
      case 'sedang_dalam_perjalanan':
        return 'Dalam Perjalanan';
      case 'sampai_ditempat':
        return 'Sudah Sampai di Lokasi';
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

  /// 📅 Label ringkas untuk filter tanggal
  String _tanggalFilterLabel() {
    if (_tanggalDari == null && _tanggalSampai == null) {
      return 'Semua tanggal';
    }
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');
    if (_tanggalDari != null && _tanggalSampai != null) {
      return '${fmt.format(_tanggalDari!)} - ${fmt.format(_tanggalSampai!)}';
    }
    if (_tanggalDari != null) {
      return 'Mulai ${fmt.format(_tanggalDari!)}';
    }
    return 'Sampai ${fmt.format(_tanggalSampai!)}';
  }

  /// 📅 Pilih rentang tanggal
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orderan Masuk')),
      body: Column(
        children: [
          // 🔍 Search + filter tanggal
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                TextField(
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
                    border: const OutlineInputBorder(),
                    hintText:
                        'Cari kode order / nama pasien / koordinator / layanan...',
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _fetchOrders(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTanggalRange,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _tanggalFilterLabel(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_tanggalDari != null || _tanggalSampai != null)
                      IconButton(
                        tooltip: 'Hapus filter tanggal',
                        onPressed: _clearTanggalFilter,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Filter status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Semua'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Semua status'),
                      ),
                      ..._statusOptions.map(
                        (s) => DropdownMenuItem<String>(
                          value: s,
                          child: Text(s),
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
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _fetchOrders,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchOrders,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Text('Belum ada order yang ditugaskan ke Anda.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderLayananPerawat order) {
    final tanggal = _formatTanggal(order.tanggalMulai);
    final jam = _formatJam(order.jamMulai);

    final pasienNama = _getNama(order.pasien);
    final koordinatorNama = _getNama(order.koordinator);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final needRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DetailOrderanMasukPerawatPage(orderId: order.id),
            ),
          );
          if (needRefresh == true) {
            _fetchOrders();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: kode + status
              Row(
                children: [
                  Text(
                    order.kodeOrder,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(order.statusOrder).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(order.statusOrder),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(order.statusOrder),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.namaLayanan,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 4),
                  Text(tanggal, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 14),
                  const SizedBox(width: 4),
                  Text(jam, style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              _buildInfoRow('Pasien', pasienNama),
              const SizedBox(height: 2),
              _buildInfoRow('Koordinator', koordinatorNama),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const Text(':  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

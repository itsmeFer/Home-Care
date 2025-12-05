import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/users/lihatDetailHistoriPemesanan.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sesuaikan dengan base URL API kamu
const String kBaseUrl = 'http://192.168.1.6:8000/api';

/// Model sederhana untuk histori order pasien
class PasienOrderHistory {
  final int id;
  final String kodeOrder;
  final String statusOrder;
  final String statusPembayaran;
  final String? tanggalMulai; // yyyy-MM-dd
  final String? jamMulai;     // HH:mm:ss
  final String namaLayanan;
  final double totalBayar;

  PasienOrderHistory({
    required this.id,
    required this.kodeOrder,
    required this.statusOrder,
    required this.statusPembayaran,
    required this.namaLayanan,
    required this.totalBayar,
    this.tanggalMulai,
    this.jamMulai,
  });

  factory PasienOrderHistory.fromJson(Map<String, dynamic> json) {
    // total_bayar bisa num/string/null
    double parseTotal(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return PasienOrderHistory(
      id: json['id'] as int,
      kodeOrder: json['kode_order']?.toString() ?? '-',
      statusOrder: json['status_order']?.toString() ?? 'pending',
      statusPembayaran: json['status_pembayaran']?.toString() ?? 'belum_bayar',
      namaLayanan: json['nama_layanan']?.toString() ??
          (json['layanan']?['nama_layanan']?.toString() ?? '-'),
      totalBayar: parseTotal(json['total_bayar']),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      jamMulai: json['jam_mulai']?.toString(),
    );
  }
}

class LihatHistoriPemesananPage extends StatefulWidget {
  const LihatHistoriPemesananPage({Key? key}) : super(key: key);

  @override
  State<LihatHistoriPemesananPage> createState() =>
      _LihatHistoriPemesananPageState();
}

class _LihatHistoriPemesananPageState extends State<LihatHistoriPemesananPage> {
  bool _isLoading = true;
  String? _error;
  List<PasienOrderHistory> _orders = [];

  /// optional filter status (riwayat biasanya semua, tapi kalau mau bisa difilter)
  String? _selectedStatus; // null = semua
  final List<String> _statusOptions = const [
    'pending',
    'menunggu_penugasan',
    'mendapatkan_perawat',
    'sedang_dalam_perjalanan',
    'sampai_ditempat',
    'mendapatkan_perawat',
    'selesai',
    'dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Token tidak ditemukan. Silakan login ulang.';
      });
      return;
    }

    try {
      // 🔥 endpoint histori pasien:
      // kalau kamu pakai controller khusus, ganti path di bawah,
      // misal: '$kBaseUrl/pasien/histori-order-layanan'
      String url = '$kBaseUrl/pasien/order-layanan';

      // kalau mau filter status tertentu (opsional)
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        url += '?status=${_selectedStatus}';
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
                'Gagal memuat histori pemesanan.';
          });
          return;
        }

        final List<dynamic> data = decoded['data'] ?? [];
        final list = data
            .map((e) => PasienOrderHistory.fromJson(
                e as Map<String, dynamic>))
            .toList();

        setState(() {
          _isLoading = false;
          _orders = list;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login berakhir. Silakan login ulang.';
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
    if (jam.length >= 5) return jam.substring(0, 5);
    return jam;
  }

  String _formatRupiah(double nilai) {
    // simpel saja, kalau mau lebih rapi bisa pakai NumberFormat
    return 'Rp ${nilai.toStringAsFixed(0)}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'menunggu_penugasan':
        return Colors.deepOrange;
      case 'mendapatkan_perawat':
        return Colors.blueGrey;
      case 'sedang_dalam_perjalanan':
        return Colors.blue;
      case 'sampai_ditempat':
        return Colors.indigo;
      case 'mendapatkan_perawat':
        return Colors.teal;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histori Pemesanan'),
      ),
      body: Column(
        children: [
          // Filter status (opsional)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      _fetchHistory();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _fetchHistory,
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
                onPressed: _fetchHistory,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Text('Belum ada histori pemesanan.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
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

  Widget _buildOrderCard(PasienOrderHistory order) {
    final tgl = _formatTanggal(order.tanggalMulai);
    final jam = _formatJam(order.jamMulai);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
onTap: () {
  final id = order.id; // <-- pakai .id, bukan ['id']
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LihatDetailHistoriPemesananPage(orderId: id),
    ),
  );
},


        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kode + status order
              Row(
                children: [
                  Text(
                    order.kodeOrder,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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
                      order.statusOrder,
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
                  Text(
                    tgl,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    jam,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatRupiah(order.totalBayar),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Pembayaran: ${order.statusPembayaran}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

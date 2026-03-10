import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/users/lihatDetailHistoriPemesanan.dart';
import 'package:home_care/users/payment_method_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'http://192.168.1.6:8000/api';

// ===== COLOR SCHEME =====
class HCColors {
  static const primary = Color(0xFF0BA5A7);
  static const primaryDark = Color(0xFF088088);
  static const accent = Color(0xFF6C63FF);
  static const bg = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textDark = Color(0xFF2D3436);
  static const textMuted = Color(0xFF636E72);
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFFDAA2E);
  static const danger = Color(0xFFFF6B6B);
  static const pending = Color(0xFFFF9F43);
}

class OrderHistory {
  final int id;
  final String kodeOrder;
  final String statusOrder;
  final String statusPembayaran;
  final String? tanggalMulai;
  final String? jamMulai;
  final String namaLayanan;
  final String? tipeLayanan;
  final double totalBayar;
  final String? metodePembayaran;
  final int? qty;
  final String? gambarLayanan;
  final bool isDraft; // ✅ TAMBAH
  final int? draftId; // ✅ TAMBAH

  OrderHistory({
    required this.id,
    required this.kodeOrder,
    required this.statusOrder,
    required this.statusPembayaran,
    required this.namaLayanan,
    required this.totalBayar,
    this.tanggalMulai,
    this.jamMulai,
    this.tipeLayanan,
    this.metodePembayaran,
    this.qty,
    this.gambarLayanan,
    this.isDraft = false, // ✅ DEFAULT
    this.draftId, // ✅ TAMBAH
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    double parseTotal(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    String? gambar;
    if (json['layanan'] != null && json['layanan'] is Map) {
      gambar = json['layanan']['gambar_url']?.toString();
    }

    // ✅ CEK APAKAH INI DRAFT
    final isDraft = json['is_draft'] == true;
    final draftId = json['draft_id'] != null
        ? int.tryParse(json['draft_id'].toString())
        : null;

    return OrderHistory(
      id: json['id'] as int,
      kodeOrder: json['kode_order']?.toString() ?? '-',
      statusOrder: json['status_order']?.toString() ?? 'pending',
      statusPembayaran: json['status_pembayaran']?.toString() ?? 'belum_bayar',
      namaLayanan: json['nama_layanan']?.toString() ?? '-',
      totalBayar: parseTotal(json['total_bayar']),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      jamMulai: json['jam_mulai']?.toString(),
      tipeLayanan: json['tipe_layanan']?.toString(),
      metodePembayaran: json['metode_pembayaran']?.toString(),
      qty: json['qty'] != null ? int.tryParse(json['qty'].toString()) : 1,
      gambarLayanan: gambar,
      isDraft: isDraft, // ✅ TAMBAH FIELD
      draftId: draftId, // ✅ TAMBAH FIELD
    );
  }
}

class LihatHistoriPemesananPage extends StatefulWidget {
  const LihatHistoriPemesananPage({Key? key}) : super(key: key);

  @override
  State<LihatHistoriPemesananPage> createState() =>
      _LihatHistoriPemesananPageState();
}

class _LihatHistoriPemesananPageState extends State<LihatHistoriPemesananPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  List<OrderHistory> _allOrders = [];
  List<OrderHistory> _unpaidOrders = [];

  // ✅ Filter orders by category
  List<OrderHistory> get _activeOrders => _allOrders
      .where(
        (o) =>
            o.statusPembayaran != 'belum_bayar' &&
            !['selesai', 'dibatalkan'].contains(o.statusOrder),
      )
      .toList();

  List<OrderHistory> get _historyOrders => _allOrders
      .where(
        (o) =>
            o.statusPembayaran != 'belum_bayar' &&
            ['selesai', 'dibatalkan'].contains(o.statusOrder),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchHistory();
    _fetchUnpaidOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ✅ FETCH UNPAID ORDERS
  Future<void> _fetchUnpaidOrders() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final uri = Uri.parse('$kBaseUrl/pasien/order-layanan/belum-bayar');

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

        if (success) {
          final List<dynamic> data = decoded['data'] ?? [];
          final list = data
              .map((e) => OrderHistory.fromJson(e as Map<String, dynamic>))
              .toList();

          setState(() {
            _unpaidOrders = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching unpaid orders: $e');
    }
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
      final uri = Uri.parse('$kBaseUrl/pasien/order-layanan');

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
                decoded['message']?.toString() ??
                'Gagal memuat histori pemesanan.';
          });
          return;
        }

        final List<dynamic> data = decoded['data'] ?? [];
        final list = data
            .map((e) => OrderHistory.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _isLoading = false;
          _allOrders = list;
        });

        await _fetchUnpaidOrders();
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login berakhir. Silakan login ulang.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat data. Kode: ${response.statusCode}';
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
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(nilai);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return HCColors.pending;
      case 'menunggu_penugasan':
        return HCColors.warning;
      case 'mendapatkan_perawat':
        return Colors.blue;
      case 'sedang_dalam_perjalanan':
        return Colors.indigo;
      case 'sampai_ditempat':
        return Colors.deepPurple;
      case 'selesai':
        return HCColors.success;
      case 'dibatalkan':
        return HCColors.danger;
      default:
        return HCColors.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'menunggu_penugasan':
        return 'Penugasan';
      case 'mendapatkan_perawat':
        return 'Ditugaskan';
      case 'sedang_dalam_perjalanan':
        return 'Perjalanan';
      case 'sampai_ditempat':
        return 'Di Lokasi';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  // ✅ PAYMENT COD CONFIRMATION
  Future<void> _confirmPaymentCod(OrderHistory order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HCColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payment,
                  color: HCColors.warning,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Konfirmasi Pembayaran COD',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Total: ${_formatRupiah(order.totalBayar)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: HCColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pesanan ini menggunakan metode Bayar di Tempat (COD). Pembayaran akan dilakukan saat perawat datang.',
                style: TextStyle(
                  fontSize: 14,
                  color: HCColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: HCColors.textMuted.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 15,
                          color: HCColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HCColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'OK, Mengerti',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: HCColors.primary),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login berakhir. Silakan login ulang.'),
            backgroundColor: HCColors.danger,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$kBaseUrl/pasien/order-layanan/${order.id}/bayar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'method': 'cod'}),
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pesanan dikonfirmasi! Pembayaran akan dilakukan di tempat.',
              ),
              backgroundColor: HCColors.success,
              duration: Duration(seconds: 3),
            ),
          );

          _fetchHistory();
          _fetchUnpaidOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                body['message']?.toString() ?? 'Gagal konfirmasi pembayaran',
              ),
              backgroundColor: HCColors.danger,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode}'),
            backgroundColor: HCColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: HCColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Responsive check for small screens
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: HCColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HCColors.primary,
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              _fetchHistory();
              _fetchUnpaidOrders();
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            // ✅ PENTING: HAPUS isScrollable, LANGSUNG CENTER
            tabAlignment: TabAlignment.center,
            tabs: [
              // ✅ TAB BELUM BAYAR
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Belum Bayar'),
                    if (_unpaidOrders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: HCColors.danger,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_unpaidOrders.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // TAB AKTIF
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Aktif'),
                    if (_activeOrders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_activeOrders.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Riwayat'),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: HCColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: HCColors.danger.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: HCColors.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _fetchHistory();
                  _fetchUnpaidOrders();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOrderList(
          _unpaidOrders,
          isEmpty: 'Semua pesanan sudah dibayar',
          isUnpaid: true,
        ),
        _buildOrderList(_activeOrders, isEmpty: 'Belum ada pesanan aktif'),
        _buildOrderList(_historyOrders, isEmpty: 'Belum ada riwayat pesanan'),
      ],
    );
  }

  Widget _buildOrderList(
    List<OrderHistory> orders, {
    required String isEmpty,
    bool isUnpaid = false,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: HCColors.textMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isEmpty,
              style: TextStyle(
                color: HCColors.textMuted.withOpacity(0.6),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchHistory();
        await _fetchUnpaidOrders();
      },
      color: HCColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, isUnpaid: isUnpaid);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderHistory order, {bool isUnpaid = false}) {
    final tgl = _formatTanggal(order.tanggalMulai);
    final jam = _formatJam(order.jamMulai);
    final isCod = order.metodePembayaran?.toLowerCase() == 'cod';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        border: isUnpaid ? Border.all(color: HCColors.danger, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LihatDetailHistoriPemesananPage(orderId: order.id),
              ),
            ).then((_) {
              _fetchHistory();
              _fetchUnpaidOrders();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER =====
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isUnpaid
                            ? HCColors.danger.withOpacity(0.1)
                            : HCColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          order.gambarLayanan != null &&
                              order.gambarLayanan!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                order.gambarLayanan!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.medical_services_rounded,
                                  color: isUnpaid
                                      ? HCColors.danger
                                      : HCColors.primary,
                                  size: 20,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.medical_services_rounded,
                              color: isUnpaid
                                  ? HCColors.danger
                                  : HCColors.primary,
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        order.kodeOrder,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: HCColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✅ RESPONSIVE BADGE
                    Flexible(
                      child: isUnpaid
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: HCColors.danger.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: HCColors.danger.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Belum Bayar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: HCColors.danger,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  order.statusOrder,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusColor(
                                    order.statusOrder,
                                  ).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _statusLabel(order.statusOrder),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor(order.statusOrder),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ===== LAYANAN =====
                Text(
                  order.namaLayanan,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: HCColors.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                // ===== INFO ROW - RESPONSIVE =====
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (order.tipeLayanan != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: HCColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.tipeLayanan!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: HCColors.primary.withOpacity(0.8),
                          ),
                        ),
                      ),
                    Text(
                      'Qty: ${order.qty ?? 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: HCColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ===== JADWAL - RESPONSIVE =====
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.today_outlined,
                          size: 14,
                          color: HCColors.textMuted.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tgl,
                          style: const TextStyle(
                            fontSize: 13,
                            color: HCColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: HCColors.textMuted.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          jam,
                          style: const TextStyle(
                            fontSize: 13,
                            color: HCColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ===== FOOTER - RESPONSIVE =====
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Bayar',
                            style: TextStyle(
                              fontSize: 11,
                              color: HCColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatRupiah(order.totalBayar),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isUnpaid
                                  ? HCColors.danger
                                  : HCColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ✅ BUTTON - RESPONSIVE
                    if (isUnpaid && isCod)
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (order.isDraft && order.draftId != null) {
                              // ✅ DRAFT: Navigate ke PaymentMethodPage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentMethodPage(
                                    draftId: order.draftId!,
                                    totalBayar: order.totalBayar.toInt(),
                                  ),
                                ),
                              ).then((_) {
                                _fetchHistory();
                                _fetchUnpaidOrders();
                              });
                            } else {
                              // ✅ ORDER FINAL: Konfirmasi COD
                              _confirmPaymentCod(order);
                            }
                          },
                          icon: const Icon(Icons.payment, size: 16),
                          label: Text(
                            order.isDraft ? 'Bayar Sekarang' : 'Konfirmasi COD',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HCColors.warning,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      )
                    else if (isUnpaid)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: HCColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Bayar Manual',
                            style: TextStyle(
                              color: HCColors.danger,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [HCColors.primary, HCColors.primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: HCColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Detail',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/users/LihatDetailDraftPemesananPage.dart';
import 'package:home_care/users/lihatDetailHistoriPemesanan.dart';
import 'package:home_care/users/payment_method_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'http://192.168.1.5:8000/api';

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
  final bool isDraft;
  final int? draftId;
  final bool hasRating;
  final String? expiredAt;

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
    this.isDraft = false,
    this.draftId,
    this.hasRating = false,
    this.expiredAt,
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

    final isDraft = json['is_draft'] == true;
    final draftId = json['draft_id'] != null
        ? int.tryParse(json['draft_id'].toString())
        : null;

    bool hasRating = false;
    if (json.containsKey('has_rating') && json['has_rating'] != null) {
      hasRating = json['has_rating'] == true || json['has_rating'] == 1;
    }

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
      isDraft: isDraft,
      draftId: draftId,
      hasRating: hasRating,
      expiredAt: json['expired_at']?.toString(),
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

  bool _isUnpaidPaymentStatus(String status) {
    final s = status.toLowerCase().trim();
    return s == 'belum_bayar' || s == 'expired' || s == 'gagal';
  }

  bool _isCodOrder(OrderHistory o) {
    final method = (o.metodePembayaran ?? '').toLowerCase().trim();
    return method == 'cash' || method == 'cod';
  }

  bool _isDraftExpired(OrderHistory o) {
    if (!o.isDraft) return false;

    final paymentStatus = o.statusPembayaran.toLowerCase().trim();
    final orderStatus = o.statusOrder.toLowerCase().trim();

    if (paymentStatus == 'expired' || orderStatus == 'expired') {
      return true;
    }

    if (o.expiredAt == null || o.expiredAt!.isEmpty) return false;

    try {
      final exp = DateTime.parse(o.expiredAt!).toLocal();
      return DateTime.now().isAfter(exp);
    } catch (_) {
      return false;
    }
  }

  List<OrderHistory> get _unpaidOrders => _allOrders.where((o) {
    final statusOrder = o.statusOrder.toLowerCase().trim();
    final isDone = ['selesai', 'dibatalkan', 'expired'].contains(statusOrder);

    if (isDone) return false;

    if (o.isDraft) {
      return !_isDraftExpired(o) &&
          ['belum_bayar', 'pending', 'menunggu_pembayaran'].contains(
            o.statusPembayaran.toLowerCase().trim(),
          );
    }

    if (_isCodOrder(o)) return false;

    return _isUnpaidPaymentStatus(o.statusPembayaran);
  }).toList();

  List<OrderHistory> get _activeOrders => _allOrders.where((o) {
    final statusOrder = o.statusOrder.toLowerCase().trim();
    final isDone = ['selesai', 'dibatalkan', 'expired'].contains(statusOrder);

    if (isDone) return false;

    if (o.isDraft) return false;

    if (_isCodOrder(o)) return true;

    return !_isUnpaidPaymentStatus(o.statusPembayaran);
  }).toList();

  List<OrderHistory> get _historyOrders => _allOrders.where((o) {
    final statusOrder = o.statusOrder.toLowerCase().trim();

    if (['selesai', 'dibatalkan', 'expired'].contains(statusOrder)) {
      return true;
    }

    if (o.isDraft && _isDraftExpired(o)) {
      return true;
    }

    return false;
  }).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchHistory();
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
      final orderUri = Uri.parse('$kBaseUrl/pasien/order-layanan');
      final draftUri = Uri.parse('$kBaseUrl/pasien/order-drafts');

      final responses = await Future.wait([
        http.get(
          orderUri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        http.get(
          draftUri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      ]);

      if (!mounted) return;

      final orderResponse = responses[0];
      final draftResponse = responses[1];

      if (orderResponse.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat order. Kode: ${orderResponse.statusCode}';
        });
        return;
      }

      if (draftResponse.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat draft. Kode: ${draftResponse.statusCode}';
        });
        return;
      }

      final orderDecoded =
          json.decode(orderResponse.body) as Map<String, dynamic>;
      final draftDecoded =
          json.decode(draftResponse.body) as Map<String, dynamic>;

      if (orderDecoded['success'] != true) {
        setState(() {
          _isLoading = false;
          _error =
              orderDecoded['message']?.toString() ?? 'Gagal memuat data order.';
        });
        return;
      }

      if (draftDecoded['success'] != true) {
        setState(() {
          _isLoading = false;
          _error =
              draftDecoded['message']?.toString() ?? 'Gagal memuat data draft.';
        });
        return;
      }

      final List<dynamic> orderData = orderDecoded['data'] ?? [];
      final List<dynamic> draftData = draftDecoded['data'] ?? [];

      if (orderData.isNotEmpty) {
        debugPrint('🔍 [DEBUG] Sample order data: ${orderData[0]}');
        debugPrint('🔍 [DEBUG] has_rating value: ${orderData[0]['has_rating']}');
      }

      final finalOrders = orderData
          .map((e) => OrderHistory.fromJson(e as Map<String, dynamic>))
          .toList();

      if (finalOrders.isNotEmpty) {
        debugPrint('🔍 [DEBUG] Parsed hasRating: ${finalOrders[0].hasRating}');
      }

      final draftOrders = draftData.map((e) {
        final draft = Map<String, dynamic>.from(e as Map<String, dynamic>);
        final draftStatus =
            draft['status']?.toString().toLowerCase().trim() ?? 'draft';

        String paymentStatus;
        switch (draftStatus) {
          case 'expired':
            paymentStatus = 'expired';
            break;
          case 'dibayar':
            paymentStatus = 'dibayar';
            break;
          case 'dibatalkan':
            paymentStatus = 'gagal';
            break;
          case 'menunggu_pembayaran':
          case 'draft':
          default:
            paymentStatus = 'belum_bayar';
            break;
        }

        return OrderHistory(
          id: draft['id'] as int,
          kodeOrder: draft['draft_code']?.toString() ?? '-',
          statusOrder: draftStatus,
          statusPembayaran: paymentStatus,
          namaLayanan: draft['nama_layanan']?.toString() ?? '-',
          totalBayar: double.tryParse(draft['total_bayar'].toString()) ?? 0,
          tanggalMulai: draft['tanggal_mulai']?.toString(),
          jamMulai: draft['jam_mulai']?.toString(),
          tipeLayanan: draft['tipe_layanan']?.toString(),
          metodePembayaran: null,
          qty: draft['qty'] != null ? int.tryParse(draft['qty'].toString()) : 1,
          gambarLayanan: null,
          isDraft: true,
          draftId: draft['id'] as int,
          hasRating: false,
          expiredAt: draft['expired_at']?.toString(),
        );
      }).toList();

      setState(() {
        _isLoading = false;
        _allOrders = [...draftOrders, ...finalOrders];
      });
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
      case 'menunggu_pembayaran':
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
      case 'expired':
        return HCColors.textMuted;
      default:
        return HCColors.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'menunggu_pembayaran':
        return 'Belum Bayar';
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
      case 'expired':
        return 'Kadaluarsa';
      default:
        return status;
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'belum_bayar':
      case 'gagal':
      case 'expired':
        return HCColors.danger;
      case 'pending':
      case 'menunggu_pembayaran':
        return HCColors.warning;
      case 'dibayar':
      case 'lunas':
        return HCColors.success;
      default:
        return HCColors.textMuted;
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'belum_bayar':
        return 'Belum Bayar';
      case 'pending':
      case 'menunggu_pembayaran':
        return 'Menunggu Verifikasi';
      case 'dibayar':
        return 'Sudah Dibayar';
      case 'lunas':
        return 'Lunas';
      case 'gagal':
        return 'Gagal';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  Widget _buildExpiredInfo(OrderHistory order) {
    if (!order.isDraft || order.expiredAt == null || order.expiredAt!.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      final exp = DateTime.parse(order.expiredAt!).toLocal();
      final text = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(exp);

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: (_isDraftExpired(order) ? HCColors.danger : HCColors.warning)
              .withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              _isDraftExpired(order) ? Icons.timer_off_outlined : Icons.timer_outlined,
              size: 14,
              color: _isDraftExpired(order) ? HCColors.danger : HCColors.warning,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _isDraftExpired(order)
                    ? 'Draft kadaluarsa pada $text'
                    : 'Selesaikan pembayaran sebelum $text',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      _isDraftExpired(order) ? HCColors.danger : HCColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

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
            tabAlignment: TabAlignment.center,
            tabs: [
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
        _buildOrderList(
          _historyOrders,
          isEmpty: 'Belum ada riwayat pesanan',
          isHistory: true,
        ),
      ],
    );
  }

  Widget _buildOrderList(
    List<OrderHistory> orders, {
    required String isEmpty,
    bool isUnpaid = false,
    bool isHistory = false,
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
      },
      color: HCColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(
            order,
            isUnpaid: isUnpaid,
            isHistory: isHistory,
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
    OrderHistory order, {
    bool isUnpaid = false,
    bool isHistory = false,
  }) {
    final tgl = _formatTanggal(order.tanggalMulai);
    final jam = _formatJam(order.jamMulai);
    final isCod =
        order.metodePembayaran?.toLowerCase() == 'cod' ||
        order.metodePembayaran?.toLowerCase() == 'cash';
    final isSelesai = order.statusOrder.toLowerCase() == 'selesai';
    final needsRating = isHistory && isSelesai && !order.hasRating;
    final isDraftExpired = _isDraftExpired(order);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(12),
        border: isUnpaid
            ? Border.all(color: HCColors.danger.withOpacity(0.3), width: 1.5)
            : needsRating
                ? Border.all(color: HCColors.accent.withOpacity(0.3), width: 1.5)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            if (order.isDraft && isDraftExpired) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Draft transaksi sudah expired. Silakan buat pesanan baru.',
                  ),
                  backgroundColor: HCColors.danger,
                ),
              );
              return;
            }

            if (order.isDraft && order.draftId != null) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LihatDetailDraftPemesananPage(draftId: order.draftId!),
                ),
              );
              if (result == true && mounted) {
                await _fetchHistory();
              }
            } else {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LihatDetailHistoriPemesananPage(orderId: order.id),
                ),
              );
              if (mounted) {
                await _fetchHistory();
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isUnpaid
                            ? HCColors.danger.withOpacity(0.08)
                            : needsRating
                                ? HCColors.accent.withOpacity(0.08)
                                : HCColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          order.gambarLayanan != null &&
                                  order.gambarLayanan!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    order.gambarLayanan!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.medical_services_rounded,
                                      color: isUnpaid
                                          ? HCColors.danger
                                          : needsRating
                                              ? HCColors.accent
                                              : HCColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.medical_services_rounded,
                                  color: isUnpaid
                                      ? HCColors.danger
                                      : needsRating
                                          ? HCColors.accent
                                          : HCColors.primary,
                                  size: 24,
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
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: HCColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _paymentStatusColor(
                                    order.statusPembayaran,
                                  ).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _paymentStatusLabel(order.statusPembayaran),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _paymentStatusColor(
                                      order.statusPembayaran,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(order.statusOrder)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _statusLabel(order.statusOrder),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _statusColor(order.statusOrder),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),

                Text(
                  order.namaLayanan,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: HCColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                Row(
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: HCColors.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      'Qty: ${order.qty ?? 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: HCColors.textMuted.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Icon(
                      Icons.today_outlined,
                      size: 14,
                      color: HCColors.textMuted.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tgl,
                      style: TextStyle(
                        fontSize: 12,
                        color: HCColors.textMuted.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: HCColors.textMuted.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      jam,
                      style: TextStyle(
                        fontSize: 12,
                        color: HCColors.textMuted.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),

                _buildExpiredInfo(order),

                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Bayar',
                          style: TextStyle(
                            fontSize: 11,
                            color: HCColors.textMuted.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRupiah(order.totalBayar),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: isUnpaid
                                ? HCColors.danger
                                : HCColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (order.isDraft && !isDraftExpired)
                      ElevatedButton(
                        onPressed: () {
                          if (order.draftId != null) {
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
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HCColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Bayar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (order.isDraft && isDraftExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: HCColors.textMuted.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Draft Expired',
                          style: TextStyle(
                            color: HCColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else if (isUnpaid && isCod)
                      ElevatedButton(
                        onPressed: () {
                          _confirmPaymentCod(order);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HCColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Konfirmasi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (isUnpaid)
                      Container(
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
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: HCColors.textMuted.withOpacity(0.5),
                      ),
                  ],
                ),

                if (needsRating) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 12),
                  _buildRatingPrompt(order),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingPrompt(OrderHistory order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HCColors.accent.withOpacity(0.08),
            HCColors.primary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: HCColors.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color.fromARGB(255, 248, 179, 76),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bagaimana pengalaman Anda?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HCColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bantu kami meningkatkan layanan',
                  style: TextStyle(
                    fontSize: 11,
                    color: HCColors.textMuted.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LihatDetailHistoriPemesananPage(orderId: order.id),
                ),
              );
              if (mounted) {
                await _fetchHistory();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 252, 177, 17),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Beri Rating',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
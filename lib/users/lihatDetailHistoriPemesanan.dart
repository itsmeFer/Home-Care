import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import halaman rating - sesuaikan dengan path project Anda
// import 'lihat_rating_page.dart';

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

class LihatDetailHistoriPemesananPage extends StatefulWidget {
  final int orderId;

  const LihatDetailHistoriPemesananPage({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<LihatDetailHistoriPemesananPage> createState() =>
      _LihatDetailHistoriPemesananPageState();
}

class _LihatDetailHistoriPemesananPageState
    extends State<LihatDetailHistoriPemesananPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _order;

  // Rating state
  bool _isLoadingRating = false;
  bool _isSubmittingRating = false;
  Map<String, dynamic>? _ratingData;
  bool _hasRating = false;
  int _ratingLayanan = 0;
  int _ratingPerawat = 0;
  final _komentarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }

  IconData _getFotoIcon(String title) {
    switch (title) {
      case 'Kondisi Pasien':
        return Icons.health_and_safety_rounded;
      case 'Bukti Kehadiran':
        return Icons.location_on_rounded;
      case 'Setelah Tindakan':
        return Icons.verified_rounded;
      default:
        return Icons.image_rounded;
    }
  }

  bool _canCancelOrder() {
    final status = _order?['status_order']?.toString().toLowerCase() ?? '';
    return [
      'pending',
      'menunggu_penugasan',
      'mendapatkan_perawat',
    ].contains(status);
  }

  bool _canRate() {
    final status = _order?['status_order']?.toString().toLowerCase() ?? '';
    return status == 'selesai';
  }

  Future<void> _cancelOrder(String alasan) async {
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

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login tidak ditemukan. Silakan login ulang.'),
            backgroundColor: HCColors.danger,
          ),
        );
        return;
      }

      final uri = Uri.parse(
        '$kBaseUrl/pasien/order-layanan/${widget.orderId}/cancel',
      );

      debugPrint('🔵 [CANCEL] Mengirim request ke: $uri');
      debugPrint('🔵 [CANCEL] Alasan: $alasan');

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'alasan_batal': alasan}),
      );

      if (!mounted) return;
      Navigator.pop(context);

      debugPrint('🔵 [CANCEL] Status Code: ${response.statusCode}');
      debugPrint('🔵 [CANCEL] Response Body: ${response.body}');

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message']?.toString() ?? 'Pesanan berhasil dibatalkan',
            ),
            backgroundColor: HCColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        await _fetchDetail();
      } else if (response.statusCode == 422) {
        String errorMsg = 'Gagal membatalkan pesanan';

        if (body['errors'] != null && body['errors'] is Map) {
          final errors = body['errors'] as Map;
          final errorList = <String>[];

          errors.forEach((key, value) {
            if (value is List) {
              errorList.addAll(value.map((e) => e.toString()));
            } else {
              errorList.add(value.toString());
            }
          });

          errorMsg = errorList.join('\n');
        } else if (body['message'] != null) {
          errorMsg = body['message'].toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: HCColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message']?.toString() ??
                  'Anda tidak memiliki izin untuk membatalkan pesanan ini',
            ),
            backgroundColor: HCColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message']?.toString() ??
                  'Gagal membatalkan pesanan. Kode: ${response.statusCode}',
            ),
            backgroundColor: HCColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [CANCEL] Error: $e');
      debugPrint('❌ [CANCEL] Stack Trace: $stackTrace');

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: HCColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showCancelDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: HCColors.danger.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: HCColors.danger,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Batalkan Pesanan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: HCColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pesanan hanya bisa dibatalkan sebelum perawat berangkat. Tuliskan alasan pembatalan agar pesanan dapat diproses dengan benar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: HCColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: HCColors.bg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: HCColors.danger.withOpacity(0.25),
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      maxLines: 5,
                      minLines: 3,
                      style: const TextStyle(
                        fontSize: 15,
                        color: HCColors.textDark,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Contoh: Jadwal berubah, pasien sudah membaik, atau tidak jadi menggunakan layanan.',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: HCColors.textMuted.withOpacity(0.8),
                          height: 1.5,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: HCColors.textMuted.withOpacity(0.25),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(
                              color: HCColors.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HCColors.danger,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            final alasan = controller.text.trim();

                            if (alasan.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Alasan pembatalan wajib diisi'),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(context);
                            await _cancelOrder(alasan);
                          },
                          child: const Text(
                            'Batalkan Pesanan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
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
      },
    );
  }

  num _getAddonsTotal() {
    final backendTotal =
        num.tryParse(_order?['addons_total']?.toString() ?? '0') ?? 0;

    if (backendTotal > 0) return backendTotal;

    final addons = _getOrderAddons();
    num calculatedTotal = 0;

    for (final addon in addons) {
      final subtotal = num.tryParse(addon['subtotal']?.toString() ?? '0') ?? 0;
      calculatedTotal += subtotal;
    }

    return calculatedTotal;
  }

  List<Map<String, dynamic>> _getOrderAddons() {
    final raw = _order?['order_addons'];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Token tidak ditemukan. Silakan login ulang.';
        });
        return;
      }

      final uri = Uri.parse('$kBaseUrl/pasien/order-layanan/${widget.orderId}');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody is Map && jsonBody['success'] == true) {
          final data = (jsonBody['data'] ?? {}) as Map<String, dynamic>;

          debugPrint('✅ ORDER DATA LOADED');
          debugPrint('Status Order: ${data['status_order']}');
          debugPrint('Status Pembayaran: ${data['status_pembayaran']}');

          setState(() {
            _order = data;
            _isLoading = false;
          });

          // Fetch rating jika status selesai
          if (_canRate()) {
            _fetchRating();
          }
        } else {
          setState(() {
            _error =
                jsonBody['message']?.toString() ??
                'Gagal mengambil detail order.';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Sesi login berakhir. Silakan login ulang.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal mengambil detail order. Kode: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRating() async {
    setState(() => _isLoadingRating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) return;

      final uri = Uri.parse(
        '$kBaseUrl/pasien/order-layanan/${widget.orderId}/rating',
      );

      debugPrint('🔵 [RATING] Fetching dari: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🔵 [RATING] Status Code: ${response.statusCode}');
      debugPrint('🔵 [RATING] Response Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody is Map && jsonBody['success'] == true) {
          final data = (jsonBody['data'] ?? {}) as Map<String, dynamic>;
          final rating = data['rating'];

          setState(() {
            _ratingData = data;
            _hasRating = rating != null;

            if (_hasRating && rating is Map) {
              _ratingLayanan =
                  int.tryParse(rating['rating_layanan']?.toString() ?? '0') ??
                      0;
              _ratingPerawat =
                  int.tryParse(rating['rating_perawat']?.toString() ?? '0') ??
                      0;
              _komentarController.text = rating['komentar']?.toString() ?? '';
            }

            _isLoadingRating = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [RATING] Error: $e');
      if (mounted) {
        setState(() => _isLoadingRating = false);
      }
    }
  }

  Future<void> _submitRating() async {
    // Validasi
    if (_ratingLayanan == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon berikan rating untuk layanan'),
          backgroundColor: HCColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmittingRating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login tidak ditemukan. Silakan login ulang.'),
            backgroundColor: HCColors.danger,
          ),
        );
        setState(() => _isSubmittingRating = false);
        return;
      }

      final uri = Uri.parse(
        '$kBaseUrl/pasien/order-layanan/${widget.orderId}/rating',
      );

      debugPrint('🔵 [RATING] Submitting ke: $uri');

      final payload = {
        'rating_layanan': _ratingLayanan,
        'rating_perawat': _ratingPerawat > 0 ? _ratingPerawat : null,
        'komentar': _komentarController.text.trim(),
      };

      debugPrint('🔵 [RATING] Payload: $payload');

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('🔵 [RATING] Status Code: ${response.statusCode}');
      debugPrint('🔵 [RATING] Response Body: ${response.body}');

      if (!mounted) return;

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message']?.toString() ?? 'Rating berhasil disimpan',
            ),
            backgroundColor: HCColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh data rating
        await _fetchRating();
      } else if (response.statusCode == 422) {
        String errorMsg = 'Validasi gagal';

        if (body['errors'] != null && body['errors'] is Map) {
          final errors = body['errors'] as Map;
          final errorList = <String>[];

          errors.forEach((key, value) {
            if (value is List) {
              errorList.addAll(value.map((e) => e.toString()));
            } else {
              errorList.add(value.toString());
            }
          });

          errorMsg = errorList.join('\n');
        } else if (body['message'] != null) {
          errorMsg = body['message'].toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: HCColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message']?.toString() ??
                  'Rating untuk order ini sudah pernah dikirim',
            ),
            backgroundColor: HCColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message']?.toString() ??
                  'Gagal menyimpan rating. Kode: ${response.statusCode}',
            ),
            backgroundColor: HCColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [RATING] Error: $e');
      debugPrint('❌ [RATING] Stack Trace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: HCColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
      }
    }
  }

  String _formatTanggal(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy', 'id_ID').format(d);
    } catch (_) {
      return raw;
    }
  }

  String _formatJam(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      if (raw.length == 5) return raw;
      final t = DateFormat('HH:mm:ss').parse(raw);
      return DateFormat('HH:mm').format(t);
    } catch (_) {
      return raw;
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(d);
    } catch (_) {
      return raw;
    }
  }

  String _formatRupiah(num? n) {
    if (n == null) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(n);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return HCColors.pending;
      case 'menunggu_penugasan':
      case 'mendapatkan_perawat':
        return HCColors.warning;
      case 'sedang_dalam_perjalanan':
        return Colors.blue;
      case 'sampai_ditempat':
        return Colors.indigo;
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
        return 'Menunggu Verifikasi';
      case 'menunggu_penugasan':
        return 'Menunggu Penugasan';
      case 'mendapatkan_perawat':
        return 'Perawat Ditugaskan';
      case 'sedang_dalam_perjalanan':
        return 'Dalam Perjalanan';
      case 'sampai_ditempat':
        return 'Sudah Sampai';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'belum_bayar':
        return 'Belum Dibayar';
      case 'menunggu_pembayaran':
        return 'Menunggu Pembayaran';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'dibayar':
        return 'Sudah Dibayar';
      case 'lunas':
        return 'Lunas';
      case 'gagal':
        return 'Pembayaran Gagal';
      case 'expired':
        return 'Pembayaran Kedaluwarsa';
      case 'dikembalikan':
        return 'Dana Dikembalikan';
      case 'refund':
        return 'Refund';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  String _paymentMethodLabel(String? method) {
    if (method == null || method.isEmpty) return '-';

    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'qris':
        return 'QRIS';
      case 'ewallet':
        return 'E-Wallet';
      case 'cod':
        return 'Bayar di Tempat';
      default:
        return method;
    }
  }

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    return '$kBaseUrl/media/$raw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColors.bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: HCColors.primary),
            )
          : _error != null
              ? _buildErrorState()
              : _order == null
                  ? const Center(child: Text('Data order tidak ditemukan.'))
                  : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              style: const TextStyle(color: HCColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchDetail,
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

  Widget _buildContent() {
    final status = _order!['status_order']?.toString() ?? '';
    final statusPayment = _order!['status_pembayaran']?.toString() ?? '';

    String? gambarLayanan;
    if (_order!['layanan'] != null && _order!['layanan'] is Map) {
      gambarLayanan = _order!['layanan']['gambar_url']?.toString();
    }

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      color: HCColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: HCColors.primary,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (gambarLayanan != null && gambarLayanan.isNotEmpty)
                      Image.network(
                        gambarLayanan,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [HCColors.primary, HCColors.primaryDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.medical_services_rounded,
                              size: 64,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [HCColors.primary, HCColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.medical_services_rounded,
                            size: 64,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.88),
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.35, 0.85],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                _order!['kode_order']?.toString() ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatusCard(status, statusPayment),
                if (_canCancelOrder()) ...[
                  const SizedBox(height: 12),
                  _buildCancelButton(),
                ],
                // ✅ RATING CARD (hanya untuk status selesai)
                if (_canRate()) ...[
                  const SizedBox(height: 12),
                  _buildRatingCard(),
                ],
                if ((_order?['status_order']?.toString().toLowerCase() ?? '') ==
                        'dibatalkan' &&
                    (_order?['alasan_batal']?.toString().trim() ?? '')
                        .isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildAlasanBatalCard(),
                ],
                const SizedBox(height: 16),
                _buildLayananCard(),
                const SizedBox(height: 16),
                _buildAddonsCard(),
                const SizedBox(height: 16),
                _buildJadwalLokasiCard(),
                const SizedBox(height: 16),
                _buildPetugasCard(),
                const SizedBox(height: 16),
                if ((_order!['catatan_pasien']?.toString() ?? '').isNotEmpty)
                  _buildCatatanCard(),
                const SizedBox(height: 16),
                _buildPembayaranCard(),
                _buildFotoSection(),
                const SizedBox(height: 16),
                _buildBuktiTransaksiCard(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showCancelDialog,
        icon: const Icon(Icons.cancel_outlined, color: HCColors.danger),
        label: const Text(
          'Batalkan Pesanan',
          style: TextStyle(color: HCColors.danger, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: HCColors.danger),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ✅ RATING CARD - INLINE TANPA NAVIGASI
  Widget _buildRatingCard() {
    if (_isLoadingRating) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: HCColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: HCColors.primary),
        ),
      );
    }

    final avgData = _ratingData?['avg'] ?? {};
    final avgLayanan = avgData['layanan'];
    final avgPerawat = avgData['perawat'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Icon(
                _hasRating ? Icons.check_circle_rounded : Icons.star_rounded,
                color: _hasRating ? HCColors.success : HCColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _hasRating ? 'Rating Anda' : 'Beri Rating & Ulasan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_hasRating) ...[
            // TAMPILAN RATING YANG SUDAH DIBERIKAN
            _buildSubmittedRatingDisplay(),
            
            // Rating Rata-rata
            if (avgLayanan != null || avgPerawat != null) ...[
              const Divider(height: 24),
              const Text(
                'Rating Rata-rata',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HCColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              if (avgLayanan != null)
                _buildAverageRatingRow(
                  icon: Icons.medical_services_rounded,
                  label: 'Layanan',
                  average: avgLayanan,
                ),
              if (avgLayanan != null && avgPerawat != null)
                const SizedBox(height: 8),
              if (avgPerawat != null)
                _buildAverageRatingRow(
                  icon: Icons.person_rounded,
                  label: 'Perawat',
                  average: avgPerawat,
                ),
            ],
          ] else ...[
            // FORM RATING
            const Text(
              'Bagaimana pengalaman Anda dengan layanan kami?',
              style: TextStyle(
                fontSize: 14,
                color: HCColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            // Rating Layanan
            _buildRatingSection(
              icon: Icons.medical_services_rounded,
              label: 'Rating Layanan',
              required: true,
              rating: _ratingLayanan,
              onRatingChanged: (rating) {
                setState(() => _ratingLayanan = rating);
              },
            ),

            const SizedBox(height: 16),

            // Rating Perawat
            _buildRatingSection(
              icon: Icons.person_rounded,
              label: 'Rating Perawat',
              required: false,
              rating: _ratingPerawat,
              onRatingChanged: (rating) {
                setState(() => _ratingPerawat = rating);
              },
            ),

            const SizedBox(height: 16),

            // Komentar
            const Row(
              children: [
                Icon(Icons.comment_rounded,
                    size: 16, color: HCColors.textMuted),
                SizedBox(width: 6),
                Text(
                  'Komentar (Opsional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HCColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: HCColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: HCColors.primary.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _komentarController,
                maxLines: 3,
                maxLength: 500,
                style: const TextStyle(
                  fontSize: 13,
                  color: HCColors.textDark,
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ceritakan pengalaman Anda...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: HCColors.textMuted,
                  ),
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmittingRating ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColors.primary,
                  disabledBackgroundColor: HCColors.textMuted,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmittingRating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Kirim Rating',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmittedRatingDisplay() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HCColors.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HCColors.success.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_rounded,
                  size: 16, color: HCColors.textMuted),
              const SizedBox(width: 6),
              const Text(
                'Rating Layanan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HCColors.textMuted,
                ),
              ),
              const Spacer(),
              _buildStarDisplay(_ratingLayanan),
            ],
          ),
          if (_ratingPerawat > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_rounded,
                    size: 16, color: HCColors.textMuted),
                const SizedBox(width: 6),
                const Text(
                  'Rating Perawat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HCColors.textMuted,
                  ),
                ),
                const Spacer(),
                _buildStarDisplay(_ratingPerawat),
              ],
            ),
          ],
          if (_komentarController.text.trim().isNotEmpty) ...[
            const Divider(height: 20),
            const Text(
              'Komentar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: HCColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _komentarController.text.trim(),
              style: const TextStyle(
                fontSize: 13,
                color: HCColors.textDark,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarDisplay(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildRatingSection({
    required IconData icon,
    required String label,
    required bool required,
    required int rating,
    required ValueChanged<int> onRatingChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: HCColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HCColors.textDark,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 2),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 13,
                  color: HCColors.danger,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () => onRatingChanged(starValue),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  rating >= starValue
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: rating >= starValue ? Colors.amber : HCColors.textMuted,
                  size: 32,
                ),
              ),
            );
          }),
        ),
        if (rating > 0) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              _getRatingLabel(rating),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getRatingColor(rating),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Baik';
      case 5:
        return 'Sangat Baik';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) return HCColors.danger;
    if (rating == 3) return HCColors.warning;
    return HCColors.success;
  }

  Widget _buildAverageRatingRow({
    required IconData icon,
    required String label,
    required dynamic average,
  }) {
    final avgDouble = double.tryParse(average.toString()) ?? 0.0;
    final fullStars = avgDouble.floor();
    final hasHalfStar = (avgDouble - fullStars) >= 0.5;

    return Row(
      children: [
        Icon(icon, size: 16, color: HCColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HCColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    if (index < fullStars) {
                      return const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 14,
                      );
                    } else if (index == fullStars && hasHalfStar) {
                      return const Icon(
                        Icons.star_half_rounded,
                        color: Colors.amber,
                        size: 14,
                      );
                    } else {
                      return const Icon(
                        Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 14,
                      );
                    }
                  }),
                  const SizedBox(width: 6),
                  Text(
                    avgDouble.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: HCColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlasanBatalCard() {
    final alasan = _order?['alasan_batal']?.toString().trim() ?? '';
    final dibatalkanAt = _order?['dibatalkan_at']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HCColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HCColors.danger.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: HCColors.danger,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Alasan Pembatalan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alasan.isEmpty ? '-' : alasan,
            style: const TextStyle(
              fontSize: 14,
              color: HCColors.textDark,
              height: 1.5,
            ),
          ),
          if (dibatalkanAt != null && dibatalkanAt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Dibatalkan pada: ${_formatDateTime(dibatalkanAt)}',
              style: const TextStyle(fontSize: 12, color: HCColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status, String statusPayment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              status == 'selesai'
                  ? Icons.check_circle_rounded
                  : status == 'dibatalkan'
                      ? Icons.cancel_rounded
                      : Icons.hourglass_empty_rounded,
              color: _statusColor(status),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pembayaran: ${_paymentStatusLabel(statusPayment)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: HCColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayananCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.medical_services_rounded,
                color: HCColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Layanan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _order!['nama_layanan']?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: HCColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                'Tipe: ${_order!['tipe_layanan'] ?? '-'}',
                Icons.inventory_2_rounded,
              ),
              _buildInfoChip(
                'Durasi: ${_order!['durasi_menit_per_visit'] ?? '-'} menit',
                Icons.timer_rounded,
              ),
              _buildInfoChip(
                'Qty: ${_order!['qty'] ?? 1}',
                Icons.shopping_cart_rounded,
              ),
              _buildInfoChip(
                'Visit: ${_order!['jumlah_visit_dipesan'] ?? '-'}x',
                Icons.repeat_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddonsCard() {
    final addons = _getOrderAddons();

    if (addons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_box_rounded, color: HCColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Add-ons',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(addons.length, (index) {
            final addon = addons[index];
            final namaAddon = addon['nama_addon']?.toString() ?? '-';
            final qty = int.tryParse(addon['qty']?.toString() ?? '0') ?? 0;
            final hargaSatuan =
                num.tryParse(addon['harga_satuan']?.toString() ?? '0') ?? 0;
            final subtotal =
                num.tryParse(addon['subtotal']?.toString() ?? '0') ?? 0;

            return Container(
              margin: EdgeInsets.only(
                bottom: index == addons.length - 1 ? 0 : 12,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HCColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HCColors.primary.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaAddon,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: HCColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Qty',
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColors.textMuted,
                        ),
                      ),
                      Text(
                        '$qty',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: HCColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Harga satuan',
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColors.textMuted,
                        ),
                      ),
                      Text(
                        _formatRupiah(hargaSatuan),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: HCColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColors.textMuted,
                        ),
                      ),
                      Text(
                        _formatRupiah(subtotal),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HCColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HCColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HCColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: HCColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalLokasiCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: HCColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Jadwal & Lokasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.today_outlined,
            'Tanggal',
            _formatTanggal(_order!['tanggal_mulai']?.toString()),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.access_time_rounded,
            'Jam',
            _formatJam(_order!['jam_mulai']?.toString()),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.location_on_rounded,
            'Alamat',
            _order!['alamat_lengkap']?.toString() ?? '-',
          ),
          const SizedBox(height: 8),
          Text(
            [_order!['kecamatan'], _order!['kota']]
                .where((e) => e != null && e.toString().isNotEmpty)
                .join(', ')
                .toString(),
            style: const TextStyle(fontSize: 13, color: HCColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPetugasCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people_rounded, color: HCColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Petugas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.supervisor_account_rounded,
            'Koordinator',
            _order!['koordinator_nama']?.toString() ?? '-',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.medical_services_rounded,
            'Perawat',
            _order!['perawat_nama']?.toString() ?? '-',
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.note_rounded, color: HCColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Catatan Pasien',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _order!['catatan_pasien'].toString(),
            style: const TextStyle(
              fontSize: 14,
              color: HCColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPembayaranCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_rounded, color: HCColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Rincian Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaymentRow(
            'Harga satuan',
            _formatRupiah(
              num.tryParse(_order!['harga_satuan']?.toString() ?? '0'),
            ),
          ),
          _buildPaymentRow('Qty', '${_order!['qty'] ?? 1}'),
          const Divider(height: 20),
          _buildPaymentRow(
            'Subtotal',
            _formatRupiah(num.tryParse(_order!['subtotal']?.toString() ?? '0')),
          ),
          _buildPaymentRow(
            'Diskon',
            _formatRupiah(num.tryParse(_order!['diskon']?.toString() ?? '0')),
            isDiscount: true,
          ),
          _buildPaymentRow('Add-ons', _formatRupiah(_getAddonsTotal())),
          const Divider(height: 20),
          _buildPaymentRow(
            'Total Bayar',
            _formatRupiah(
              num.tryParse(_order!['total_bayar']?.toString() ?? '0'),
            ),
            isTotal: true,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(
                'Metode: ${_paymentMethodLabel(_order!['metode_pembayaran']?.toString())}',
                HCColors.primary,
              ),
              _buildBadge(
                'Status: ${_paymentStatusLabel(_order!['status_pembayaran']?.toString() ?? '')}',
                HCColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBuktiTransaksiCard() {
    final buktiUrl =
        _order?['bukti_pembayaran']?.toString() ??
        _order?['payment_info']?['bukti_pembayaran']?.toString();

    final uploadedAt = _order?['payment_info']?['bukti_uploaded_at']?.toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: HCColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Bukti Transaksi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (buktiUrl == null || buktiUrl.isEmpty)
            Container(
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HCColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_rounded,
                    color: HCColors.textMuted,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada bukti transaksi',
                    style: TextStyle(color: HCColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                buktiUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: HCColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        color: HCColors.textMuted,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Gagal memuat bukti transaksi',
                        style: TextStyle(
                          color: HCColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (uploadedAt != null && uploadedAt.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Diunggah: ${_formatDateTime(uploadedAt)}',
                style: const TextStyle(fontSize: 12, color: HCColors.textMuted),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: HCColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isDiscount
                  ? HCColors.danger
                  : isTotal
                      ? HCColors.primary
                      : HCColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: HCColors.textMuted.withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: HCColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: HCColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFotoCard('Kondisi Pasien', _order!['kondisi_pasien']?.toString()),
        const SizedBox(height: 12),
        _buildFotoCard('Bukti Kehadiran', _order!['foto_hadir']?.toString()),
        const SizedBox(height: 12),
        _buildFotoCard('Setelah Tindakan', _order!['foto_selesai']?.toString()),
      ],
    );
  }

  Widget _buildFotoCard(String title, String? rawPath) {
    final url = _resolveImageUrl(rawPath);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Icon(_getFotoIcon(title), size: 18, color: HCColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (url == null)
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: HCColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_rounded,
                    color: HCColors.textMuted,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada foto',
                    style: TextStyle(color: HCColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: HCColors.bg,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: HCColors.textMuted,
                    size: 48,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
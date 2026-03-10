// lib/users/payment_method_page.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/users/lihatDetailHistoriPemesanan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:home_care/users/layananPage.dart' show kApiBase;
const String kBaseUrl = 'http://192.168.1.6:8000';
const String kApiBase = '$kBaseUrl/api';

class PaymentMethodPage extends StatefulWidget {
  final int draftId;
  final int totalBayar;

  const PaymentMethodPage({
    Key? key,
    required this.draftId,
    required this.totalBayar,
  }) : super(key: key);

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage>
    with WidgetsBindingObserver {
  String _selectedMethod = 'cod';
  bool _isSubmitting = false;
  bool _isChecking = false;
  bool _isLoadingDraft = true;

  Timer? _pollTimer;
  bool _alreadyPaid = false;

  Map<String, dynamic>? _draftData;
  String? _draftError;

  // Color scheme matching histori pemesanan
  static const primaryColor = Color(0xFF0BA5A7);
  static const primaryDark = Color(0xFF088088);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const cardColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF2D3436);
  static const textSecondary = Color(0xFF636E72);
  static const successColor = Color(0xFF00B894);
  static const dividerColor = Color(0xFFE5E5EA);

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _money(int v) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(v);

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return raw;
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchDraftData();
    _startAutoPolling();
  }

  @override
  void dispose() {
    _stopAutoPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus(auto: true);
    }
  }

  void _startAutoPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_alreadyPaid) return;
      await _checkStatus(auto: true);
    });
  }

  void _stopAutoPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _fetchDraftData() async {
    debugPrint('🔵 [FETCH] Mulai fetch draft ${widget.draftId}');

    setState(() {
      _isLoadingDraft = true;
      _draftError = null;
    });

    try {
      final t = await _token();

      if (t == null || t.isEmpty) {
        debugPrint('❌ [FETCH] Token tidak ditemukan');
        setState(() {
          _draftError = 'Sesi login berakhir. Silakan login ulang.';
          _isLoadingDraft = false;
        });
        return;
      }

      debugPrint('🔵 [FETCH] Token: ${t.substring(0, 20)}...');

      final uri = Uri.parse('$kApiBase/pasien/order-draft/${widget.draftId}');
      debugPrint('🔵 [FETCH] URI: $uri');

      final res = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $t',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Request timeout');
            },
          );

      debugPrint('🔵 [FETCH] Status: ${res.statusCode}');
      debugPrint('🔵 [FETCH] Body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = json.decode(res.body);

        if (body is Map && body['success'] == true) {
          final data = body['data'];

          Map<String, dynamic>? draft;

          if (data is Map && data['draft'] is Map) {
            draft = Map<String, dynamic>.from(data['draft'] as Map);
          } else if (data is Map) {
            draft = Map<String, dynamic>.from(data as Map);
          }

          if (draft != null) {
            debugPrint('✅ [FETCH] Berhasil! Draft: ${draft['draft_code']}');
            setState(() {
              _draftData = draft;
              _isLoadingDraft = false;
              _draftError = null;
            });
            return;
          }
        }

        debugPrint('❌ [FETCH] Response tidak valid');
        setState(() {
          _draftError = 'Format response tidak valid';
          _isLoadingDraft = false;
        });
      } else if (res.statusCode == 401) {
        debugPrint('❌ [FETCH] Unauthorized');
        setState(() {
          _draftError = 'Sesi login berakhir. Silakan login ulang.';
          _isLoadingDraft = false;
        });
      } else {
        debugPrint('❌ [FETCH] HTTP Error: ${res.statusCode}');
        setState(() {
          _draftError = 'Gagal memuat draft (${res.statusCode})';
          _isLoadingDraft = false;
        });
      }
    } on TimeoutException {
      debugPrint('❌ [FETCH] Timeout!');
      if (!mounted) return;
      setState(() {
        _draftError = 'Request timeout. Coba lagi.';
        _isLoadingDraft = false;
      });
    } catch (e) {
      debugPrint('❌ [FETCH] Exception: $e');
      if (!mounted) return;
      setState(() {
        _draftError = 'Error: $e';
        _isLoadingDraft = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _requestCod() async {
    final t = await _token();
    if (t == null || t.isEmpty) {
      _toast('Sesi login habis, login ulang.');
      return null;
    }

    final res = await http.post(
      Uri.parse('$kApiBase/pasien/order-draft/${widget.draftId}/bayar'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
      body: {'method': _selectedMethod},
    );

    if (!mounted) return null;

    if (res.statusCode != 200 && res.statusCode != 201) {
      String msg = 'Gagal request pembayaran (${res.statusCode})';
      try {
        final j = json.decode(res.body);
        if (j is Map && j['message'] != null) msg = j['message'].toString();
      } catch (_) {}
      _toast(msg);
      return null;
    }

    final body = json.decode(res.body);
    debugPrint('PAY RESP BODY: $body');

    if (body is! Map) return null;

    if (body['success'] != true) {
      _toast(body['message']?.toString() ?? 'Gagal membuat pembayaran');
      return null;
    }

    final data = (body['data'] is Map)
        ? Map<String, dynamic>.from(body['data'] as Map)
        : <String, dynamic>{};

    return data;
  }

  Future<void> _pay() async {
    if (_isSubmitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmationDialog(),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      debugPrint('🔵 [PAY] Mulai proses pembayaran COD...');

      final t = await _token();
      if (t == null || t.isEmpty) {
        _toast('Sesi login habis, login ulang.');
        return;
      }

      final res = await http.post(
        Uri.parse('$kApiBase/pasien/order-draft/${widget.draftId}/bayar'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: {'method': 'cod'},
      );

      debugPrint('🔵 [PAY] Response Status: ${res.statusCode}');
      debugPrint('🔵 [PAY] Response Body: ${res.body}');

      if (!mounted) return;

      if (res.statusCode != 200 && res.statusCode != 201) {
        String msg = 'Gagal request pembayaran (${res.statusCode})';
        try {
          final j = json.decode(res.body);
          if (j is Map && j['message'] != null) msg = j['message'].toString();
        } catch (_) {}
        _toast(msg);
        return;
      }

      final body = json.decode(res.body);

      if (body['success'] != true) {
        _toast(body['message']?.toString() ?? 'Gagal membuat pembayaran');
        return;
      }

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        _toast('Data response tidak valid');
        return;
      }

      final orderId = data['order_id'];

      if (orderId == null) {
        debugPrint('❌ [PAY] Order ID tidak ditemukan di response');
        _toast('Pesanan berhasil, tapi tidak dapat menemukan ID order');
        return;
      }

      debugPrint('✅ [PAY] Order ID: $orderId');

      _toast('Pesanan berhasil dikonfirmasi!');

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _buildSuccessDialog(dialogContext),
      );

      if (!mounted) return;

      debugPrint('🔵 [PAY] Navigasi ke detail order: $orderId');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LihatDetailHistoriPemesananPage(orderId: orderId),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [PAY] Error: $e');
      debugPrint('STACK TRACE: $stackTrace');
      _toast('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _checkStatus({bool auto = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final t = await _token();
      if (t == null || t.isEmpty) {
        if (!auto) _toast('Sesi login habis, login ulang.');
        return;
      }

      final res = await http.get(
        Uri.parse('$kApiBase/pasien/order-draft/${widget.draftId}/status'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
      );

      if (!mounted) return;

      if (res.statusCode != 200) {
        if (!auto) _toast('Gagal cek status (${res.statusCode})');
        return;
      }

      final body = json.decode(res.body);

      Map<String, dynamic> data = {};
      if (body is Map && body['data'] is Map) {
        data = Map<String, dynamic>.from(body['data'] as Map);
      } else if (body is Map) {
        data = Map<String, dynamic>.from(body);
      }

      String? draftStatus;
      String? payStatus;

      if (data['draft'] is Map) {
        draftStatus = (data['draft'] as Map)['status']?.toString();
      }
      if (data['payment'] is Map) {
        payStatus = (data['payment'] as Map)['status']?.toString();
      }

      payStatus ??= data['status']?.toString();

      final isPaid =
          (draftStatus == 'dibayar') ||
          (payStatus == 'paid') ||
          (draftStatus == 'confirmed');

      if (isPaid && !_alreadyPaid) {
        final orderId = data['order_id'];

        if (orderId == null) {
          if (!auto) _toast('Order ID belum tersedia');
          return;
        }

        _alreadyPaid = true;
        _stopAutoPolling();

        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _buildSuccessDialog(dialogContext),
        );

        if (!mounted) return;

        Navigator.pop(context, orderId);

        return;
      }

      if (!auto) {
        _toast('Status: ${draftStatus ?? '-'} | payment: ${payStatus ?? '-'}');
      }
    } catch (e) {
      if (!auto) _toast('Error cek status: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Widget _buildConfirmationDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Konfirmasi Pembayaran',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    primaryDark.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _money(widget.totalBayar),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bayar di tempat saat petugas datang',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 17,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryColor, primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Konfirmasi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDialog(BuildContext dialogContext) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: successColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pesanan Berhasil',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pesanan Anda telah dikonfirmasi. Koordinator akan segera menugaskan perawat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading State
    if (_isLoadingDraft) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    // Error State
    if (_draftError != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: primaryColor,
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Pembayaran',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gagal Memuat Data',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _draftError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: const BorderSide(color: dividerColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Kembali',
                          style: TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _fetchDraftData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryColor, primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          alignment: Alignment.center,
                          child: const Text(
                            'Coba Lagi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
    }

    // Get Draft Data
    final namaLayanan = _draftData?['nama_layanan']?.toString() ?? 'Layanan';
    final tanggal = _formatDate(_draftData?['tanggal_mulai']?.toString());
    final jam = _formatTime(_draftData?['jam_mulai']?.toString());
    final alamat = _draftData?['alamat_lengkap']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: primaryColor,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            color: primaryColor,
            onPressed: _fetchDraftData,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.medical_services,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                namaLayanan,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _infoRow(Icons.calendar_today, 'Tanggal', tanggal),
                        const SizedBox(height: 12),
                        _infoRow(Icons.access_time, 'Waktu', jam),
                        const SizedBox(height: 12),
                        _infoRow(Icons.location_on, 'Lokasi', alamat),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Total Payment Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _money(widget.totalBayar),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Title
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: -0.08,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Payment Method Card
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.payments,
                              color: primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bayar di Tempat',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Cash on Delivery',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: successColor,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: primaryColor.withOpacity(0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Anda akan membayar langsung kepada petugas saat mereka tiba di lokasi.',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryColor, primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.transparent,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Konfirmasi Pesanan',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
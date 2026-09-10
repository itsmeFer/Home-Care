import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/core/widgets/patient_app_bar.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/users/lihat_detail_histori_pemesanan.dart';
import 'package:home_care/users/pemesanan/services/payment_service.dart';
import 'package:home_care/users/pemesanan/widgets/payment_confirmation_dialog.dart';
import 'package:home_care/users/pemesanan/widgets/payment_success_dialog.dart';

class PaymentMethodPage extends StatefulWidget {
  final int draftId;
  final int totalBayar;

  const PaymentMethodPage({
    super.key,
    required this.draftId,
    required this.totalBayar,
  });

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage>
    with WidgetsBindingObserver {
  final _paymentService = const PaymentService();

  final String _selectedMethod = 'cod';
  bool _isSubmitting = false;
  bool _isChecking = false;
  bool _isLoadingDraft = true;
  bool _isNavigatingToDetail = false;

  Timer? _pollTimer;
  bool _alreadyPaid = false;

  Map<String, dynamic>? _draftData;
  String? _draftError;

  static const primaryColor = Color(0xFF0BA5A7);
  static const primaryDark = Color(0xFF088088);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const cardColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF2D3436);
  static const textSecondary = Color(0xFF636E72);
  static const successColor = Color(0xFF00B894);
  static const dividerColor = Color(0xFFE5E5EA);

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

  int? _parseOrderId(dynamic rawOrderId) {
    if (rawOrderId == null) return null;
    return int.tryParse(rawOrderId.toString());
  }

  Future<void> _goToOrderDetail(dynamic rawOrderId) async {
    if (!mounted || _isNavigatingToDetail) return;

    final int? orderId = _parseOrderId(rawOrderId);
    if (orderId == null) {
      _toast('Order ID tidak valid');
      return;
    }

    _isNavigatingToDetail = true;
    _alreadyPaid = true;
    _stopAutoPolling();

    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LihatDetailHistoriPemesananPage(orderId: orderId),
      ),
    );
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
    if (state == AppLifecycleState.resumed &&
        !_alreadyPaid &&
        !_isNavigatingToDetail) {
      _checkStatus(auto: true);
    }
  }

  void _startAutoPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_alreadyPaid || _isNavigatingToDetail) return;
      await _checkStatus(auto: true);
    });
  }

  void _stopAutoPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _fetchDraftData() async {
    setState(() {
      _isLoadingDraft = true;
      _draftError = null;
    });

    try {
      final draft = await _paymentService.fetchDraft(widget.draftId);
      if (!mounted) return;

      if (draft != null) {
        setState(() {
          _draftData = draft;
          _isLoadingDraft = false;
          _draftError = null;
        });
      } else {
        setState(() {
          _draftError = 'Gagal memuat data draft. Periksa koneksi Anda.';
          _isLoadingDraft = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _draftError = 'Terjadi kesalahan: $e';
        _isLoadingDraft = false;
      });
    }
  }

  Future<void> _pay() async {
    if (_isSubmitting || _isNavigatingToDetail) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PaymentConfirmationDialog(totalBayar: widget.totalBayar),
    );

    if (confirmed != true) return;

    _stopAutoPolling();
    setState(() => _isSubmitting = true);

    try {
      final data = await _paymentService.payDraft(widget.draftId, _selectedMethod);
      if (!mounted) return;

      final rawOrderId = data['order_id'];
      final int? orderId = _parseOrderId(rawOrderId);

      if (orderId == null) {
        _toast('Pesanan berhasil, tapi tidak dapat menemukan ID order');
        _startAutoPolling();
        return;
      }

      _alreadyPaid = true;
      _stopAutoPolling();
      _toast('Pesanan berhasil dikonfirmasi!');

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PaymentSuccessDialog(),
      );

      if (!mounted) return;
      await _goToOrderDetail(orderId);
    } catch (e) {
      _toast('Error: $e');
      if (!_alreadyPaid && !_isNavigatingToDetail) {
        _startAutoPolling();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _checkStatus({bool auto = false}) async {
    if (_isChecking || _alreadyPaid || _isNavigatingToDetail) return;

    setState(() => _isChecking = true);

    try {
      final data = await _paymentService.checkStatus(widget.draftId);
      if (!mounted || data == null) return;

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

      if (isPaid && !_alreadyPaid && !_isNavigatingToDetail) {
        final rawOrderId = data['order_id'];
        final int? orderId = _parseOrderId(rawOrderId);

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
          builder: (_) => const PaymentSuccessDialog(),
        );

        if (!mounted) return;
        await _goToOrderDetail(orderId);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDraft) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(child: OrderDetailSkeleton()),
      );
    }

    if (_draftError != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: const PatientAppBar(title: 'Pembayaran'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    IconlyLight.dangerCircle,
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
                          style: TextStyle(fontSize: 15, color: textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryColor, primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
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

    final namaLayanan = _draftData?['nama_layanan']?.toString() ?? 'Layanan';
    final tanggal = AppFormatters.date(_draftData?['tanggal_mulai']?.toString());
    final jam = AppFormatters.time(_draftData?['jam_mulai']?.toString());
    final alamat = _draftData?['alamat_lengkap']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PatientAppBar(
        title: 'Pembayaran',
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.swap, color: Colors.white),
            onPressed: _fetchDraftData,
            tooltip: 'Refresh',
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
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                IconlyLight.activity,
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
                        _infoRow(IconlyLight.calendar, 'Tanggal', tanggal),
                        const SizedBox(height: 12),
                        _infoRow(IconlyLight.timeCircle, 'Waktu', jam),
                        const SizedBox(height: 12),
                        _infoRow(IconlyLight.location, 'Lokasi', alamat),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.currency(widget.totalBayar),
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
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              IconlyLight.wallet,
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
                            IconlyBold.tickSquare,
                            color: successColor,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          IconlyLight.infoSquare,
                          color: primaryColor.withValues(alpha: 0.8),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                        color: primaryColor.withValues(alpha: 0.3),
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
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
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
                style: const TextStyle(fontSize: 12, color: textSecondary),
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

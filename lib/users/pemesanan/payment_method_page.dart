import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/core/widgets/patient_app_bar.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/users/lihat_detail_histori_pemesanan.dart';
import 'package:home_care/users/pemesanan/services/payment_service.dart';
import 'package:home_care/users/pemesanan/widgets/widgets.dart';

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

  static const backgroundColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF2D3436);

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
        body: PaymentErrorView(
          errorMessage: _draftError!,
          onRetry: _fetchDraftData,
          onBack: () => Navigator.pop(context),
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
                  PaymentOrderSummaryCard(
                    namaLayanan: namaLayanan,
                    tanggal: tanggal,
                    jam: jam,
                    alamat: alamat,
                    totalBayar: widget.totalBayar,
                  ),
                  const SizedBox(height: 24),
                  const PaymentMethodCard(),
                ],
              ),
            ),
          ),
          PaymentBottomBar(
            isSubmitting: _isSubmitting,
            onConfirm: _pay,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/features/orders/presentation/widgets/order_cancel_dialog.dart';
import 'package:home_care/features/orders/presentation/widgets/order_rating_section.dart';
import 'package:home_care/features/orders/presentation/widgets/order_timeline_tracker.dart';
import 'package:home_care/users/histori_pemesanan/services/histori_pemesanan_service.dart';
import 'package:home_care/users/histori_pemesanan/widgets/order_foto_section.dart';
import 'package:home_care/users/histori_pemesanan/widgets/order_layanan_detail_card.dart';
import 'package:home_care/users/histori_pemesanan/widgets/order_pembayaran_card.dart';
import 'package:home_care/users/histori_pemesanan/widgets/order_petugas_card.dart';

class LihatDetailHistoriPemesananPage extends StatefulWidget {
  final int orderId;

  const LihatDetailHistoriPemesananPage({super.key, required this.orderId});

  @override
  State<LihatDetailHistoriPemesananPage> createState() =>
      _LihatDetailHistoriPemesananPageState();
}

class _LihatDetailHistoriPemesananPageState
    extends State<LihatDetailHistoriPemesananPage> {
  final _service = const HistoriPemesananService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _order;

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

  bool _canCancelOrder() {
    final status = _order?['status_order']?.toString().toLowerCase() ?? '';
    return ['pending', 'menunggu_penugasan', 'mendapatkan_perawat'].contains(status);
  }

  bool _canRate() {
    final status = _order?['status_order']?.toString().toLowerCase() ?? '';
    return status == 'selesai';
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchOrderDetail(widget.orderId);
      if (!mounted) return;

      if (data != null) {
        setState(() {
          _order = data;
          _isLoading = false;
        });

        if (_canRate()) {
          _fetchRating();
        }
      } else {
        setState(() {
          _error = 'Gagal mengambil detail order.';
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
      final data = await _service.fetchRating(widget.orderId);
      if (!mounted || data == null) return;

      final rating = data['rating'];
      setState(() {
        _ratingData = data;
        _hasRating = rating != null;

        if (_hasRating && rating is Map) {
          _ratingLayanan =
              int.tryParse(rating['rating_layanan']?.toString() ?? '0') ?? 0;
          _ratingPerawat =
              int.tryParse(rating['rating_perawat']?.toString() ?? '0') ?? 0;
          _komentarController.text = rating['komentar']?.toString() ?? '';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoadingRating = false);
    }
  }

  Future<void> _submitRating() async {
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
      await _service.submitRating(
        orderId: widget.orderId,
        ratingLayanan: _ratingLayanan,
        ratingPerawat: _ratingPerawat,
        komentar: _komentarController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating berhasil disimpan'),
          backgroundColor: HCColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      await _fetchRating();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: HCColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingRating = false);
    }
  }

  Future<void> _cancelOrder(String alasan) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: HCColors.primary),
      ),
    );

    try {
      await _service.cancelOrder(widget.orderId, alasan);
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibatalkan'),
          backgroundColor: HCColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      await _fetchDetail();
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan pesanan: $e'),
          backgroundColor: HCColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showCancelDialog() async {
    await OrderCancelDialog.show(
      context,
      orderId: widget.orderId,
      onConfirm: _cancelOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColors.bg,
      body: _isLoading
          ? const OrderDetailSkeleton()
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
              IconlyLight.dangerCircle,
              size: 64,
              color: HCColors.danger.withValues(alpha: 0.5),
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
              icon: const Icon(IconlyLight.swap),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HCColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    if (_order!['layanan'] is Map) {
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
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    IconlyLight.arrowLeft2,
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
                              IconlyLight.activity,
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
                            IconlyLight.activity,
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
                            Colors.black.withValues(alpha: 0.88),
                            Colors.black.withValues(alpha: 0.35),
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
                Column(
                  children: [
                    OrderStatusHeaderCard(status: status, statusPayment: statusPayment),
                    const SizedBox(height: 16),
                    OrderTimelineTracker(statusOrder: status),
                  ],
                ),
                if (_canCancelOrder()) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showCancelDialog,
                      icon: const Icon(IconlyLight.closeSquare, color: HCColors.danger),
                      label: const Text(
                        'Batalkan Pesanan',
                        style: TextStyle(
                          color: HCColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: HCColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
                if (_canRate()) ...[
                  const SizedBox(height: 12),
                  OrderRatingSection(
                    hasRating: _hasRating,
                    isLoadingRating: _isLoadingRating,
                    ratingData: _ratingData,
                    ratingLayanan: _ratingLayanan,
                    ratingPerawat: _ratingPerawat,
                    komentarController: _komentarController,
                    isSubmittingRating: _isSubmittingRating,
                    onRatingLayananChanged: (r) => setState(() => _ratingLayanan = r),
                    onRatingPerawatChanged: (r) => setState(() => _ratingPerawat = r),
                    onSubmit: _submitRating,
                  ),
                ],
                if ((_order?['status_order']?.toString().toLowerCase() ?? '') ==
                        'dibatalkan' &&
                    (_order?['alasan_batal']?.toString().trim() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildAlasanBatalCard(),
                ],
                const SizedBox(height: 16),
                OrderLayananDetailCard(order: _order!),
                const SizedBox(height: 16),
                OrderPetugasCard(order: _order!),
                if ((_order!['catatan_pasien']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildCatatanCard(),
                ],
                const SizedBox(height: 16),
                OrderPembayaranCard(order: _order!),
                const SizedBox(height: 16),
                OrderFotoSection(order: _order!),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlasanBatalCard() {
    final alasan = _order?['alasan_batal']?.toString().trim() ?? '';
    final dibatalkanAt = _order?['dibatalkan_at']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HCColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HCColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(IconlyLight.dangerCircle, color: HCColors.danger, size: 18),
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
              'Dibatalkan pada: ${AppFormatters.dateTime(dibatalkanAt)}',
              style: const TextStyle(fontSize: 12, color: HCColors.textMuted),
            ),
          ],
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
            color: Colors.black.withValues(alpha: 0.04),
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
              Icon(IconlyLight.document, color: HCColors.primary, size: 20),
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
}

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/users/histori_pemesanan/services/histori_pemesanan_service.dart';
import 'package:home_care/users/histori_pemesanan/widgets/order_layanan_detail_card.dart';
import 'package:home_care/users/histori_pemesanan/widgets/order_pembayaran_card.dart';
import 'package:home_care/users/payment_method_page.dart';

class LihatDetailDraftPemesananPage extends StatefulWidget {
  final int draftId;

  const LihatDetailDraftPemesananPage({super.key, required this.draftId});

  @override
  State<LihatDetailDraftPemesananPage> createState() =>
      _LihatDetailDraftPemesananPageState();
}

class _LihatDetailDraftPemesananPageState
    extends State<LihatDetailDraftPemesananPage> {
  final _service = const HistoriPemesananService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _draft;

  @override
  void initState() {
    super.initState();
    _fetchDraftDetail();
  }

  Future<void> _fetchDraftDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchDraftDetail(widget.draftId);
      if (!mounted) return;

      if (data != null) {
        setState(() {
          _draft = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Draft tidak ditemukan.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColors.bg,
      body: _isLoading
          ? const OrderDetailSkeleton()
          : _error != null
              ? _buildErrorState()
              : _draft == null
                  ? const Center(child: Text('Data draft tidak ditemukan.'))
                  : _buildContent(),
      bottomNavigationBar: _draft != null ? _buildBottomBar() : null,
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
              onPressed: _fetchDraftDetail,
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
    String? gambarLayanan;
    if (_draft!['layanan'] is Map) {
      gambarLayanan = _draft!['layanan']['gambar_url']?.toString();
    }

    return RefreshIndicator(
      onRefresh: _fetchDraftDetail,
      color: HCColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: HCColors.warning,
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
                              colors: [HCColors.warning, HCColors.pending],
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
                            colors: [HCColors.warning, HCColors.pending],
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
                _draft!['draft_code']?.toString() ?? 'DRAFT',
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
                _buildStatusCard(),
                const SizedBox(height: 16),
                OrderLayananDetailCard(order: _draft!),
                if ((_draft!['catatan_pasien']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildCatatanCard(),
                ],
                const SizedBox(height: 16),
                OrderPembayaranCard(order: _draft!),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HCColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              IconlyLight.timeCircle,
              color: HCColors.warning,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menunggu Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: HCColors.warning,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Selesaikan pembayaran untuk memproses pesanan',
                  style: TextStyle(fontSize: 13, color: HCColors.textMuted),
                ),
              ],
            ),
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
            _draft!['catatan_pasien'].toString(),
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

  Widget _buildBottomBar() {
    final totalBayar =
        num.tryParse(_draft!['total_bayar']?.toString() ?? '0') ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentMethodPage(
                  draftId: widget.draftId,
                  totalBayar: totalBayar.toInt(),
                ),
              ),
            );

            if (result == true && mounted) {
              Navigator.pop(context, true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: HCColors.warning,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(IconlyLight.wallet, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Bayar Sekarang - ${AppFormatters.currency(totalBayar)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

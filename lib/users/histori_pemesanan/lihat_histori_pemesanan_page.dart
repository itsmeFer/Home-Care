import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/core/widgets/patient_app_bar.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/features/orders/domain/order_models.dart';
import 'package:home_care/users/histori_pemesanan/services/histori_pemesanan_service.dart';
import 'package:home_care/users/histori_pemesanan/widgets/order_history_card.dart';
import 'package:home_care/users/lihat_detail_draft_pemesanan_page.dart';
import 'package:home_care/users/lihat_detail_histori_pemesanan.dart';
import 'package:home_care/users/payment_method_page.dart';

export 'package:home_care/features/orders/domain/order_models.dart';

class LihatHistoriPemesananPage extends StatefulWidget {
  const LihatHistoriPemesananPage({super.key});

  @override
  State<LihatHistoriPemesananPage> createState() =>
      _LihatHistoriPemesananPageState();
}

class _LihatHistoriPemesananPageState extends State<LihatHistoriPemesananPage>
    with SingleTickerProviderStateMixin {
  final _service = const HistoriPemesananService();
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

    if (paymentStatus == 'expired' || orderStatus == 'expired') return true;
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
              ['belum_bayar', 'pending', 'menunggu_pembayaran']
                  .contains(o.statusPembayaran.toLowerCase().trim());
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

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _service.fetchAllOrders();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _allOrders = orders;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat histori pesanan: $e';
      });
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
                  color: HCColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  IconlyLight.wallet,
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
                'Total: ${AppFormatters.currency(order.totalBayar)}',
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
                          color: HCColors.textMuted.withValues(alpha: 0.3),
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

    try {
      await _service.confirmPaymentCod(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan dikonfirmasi! Pembayaran akan dilakukan di tempat.'),
          backgroundColor: HCColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      _fetchHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: HCColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColors.bg,
      appBar: PatientAppBar.withTabs(
        title: 'Pesanan Saya',
        tabController: _tabController,
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.swap, color: Colors.white),
            onPressed: _fetchHistory,
            tooltip: 'Refresh',
          ),
        ],
        tabs: [
          PatientTabBar.buildTab(
            label: 'Belum Bayar',
            count: _unpaidOrders.length,
            countColor: HCColors.danger,
          ),
          PatientTabBar.buildTab(
            label: 'Aktif',
            count: _activeOrders.length,
            countColor: Colors.white.withValues(alpha: 0.3),
          ),
          const Tab(text: 'Riwayat'),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SingleChildScrollView(child: OrderListSkeleton());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                style: const TextStyle(color: HCColors.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchHistory,
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
              IconlyLight.document,
              size: 72,
              color: HCColors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isEmpty,
              style: TextStyle(
                color: HCColors.textMuted.withValues(alpha: 0.6),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: HCColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderHistoryCard(
            order: order,
            isUnpaid: isUnpaid,
            isHistory: isHistory,
            onTap: () async {
              if (order.isDraft && _isDraftExpired(order)) {
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
                    builder: (_) => LihatDetailDraftPemesananPage(
                      draftId: order.draftId!,
                    ),
                  ),
                );
                if (result == true && mounted) await _fetchHistory();
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LihatDetailHistoriPemesananPage(
                      orderId: order.id,
                    ),
                  ),
                );
                if (mounted) await _fetchHistory();
              }
            },
            onPayDraft: () {
              if (order.draftId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentMethodPage(
                      draftId: order.draftId!,
                      totalBayar: order.totalBayar.toInt(),
                    ),
                  ),
                ).then((_) => _fetchHistory());
              }
            },
            onConfirmCod: () => _confirmPaymentCod(order),
            onRate: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LihatDetailHistoriPemesananPage(
                    orderId: order.id,
                  ),
                ),
              );
              if (mounted) await _fetchHistory();
            },
          );
        },
      ),
    );
  }
}

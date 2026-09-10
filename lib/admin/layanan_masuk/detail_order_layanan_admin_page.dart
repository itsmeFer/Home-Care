import 'package:flutter/material.dart';
import 'package:home_care/admin/layanan_masuk/models/order_detail_admin_model.dart';
import 'package:home_care/admin/layanan_masuk/services/layanan_masuk_admin_service.dart';
import 'package:home_care/admin/layanan_masuk/tabs/order_addons_tab.dart';
import 'package:home_care/admin/layanan_masuk/tabs/order_detail_info_tab.dart';
import 'package:home_care/admin/layanan_masuk/tabs/order_foto_tab.dart';
import 'package:home_care/admin/layanan_masuk/tabs/order_koordinator_tab.dart';
import 'package:home_care/admin/layanan_masuk/tabs/order_lokasi_tab.dart';
import 'package:home_care/admin/layanan_masuk/tabs/order_pembayaran_tab.dart';
import 'package:home_care/admin/layanan_masuk/widgets/order_quick_info_card.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/orders/domain/order_models.dart';

class DetailOrderLayananAdminPage extends StatefulWidget {
  final int orderId;

  const DetailOrderLayananAdminPage({super.key, required this.orderId});

  @override
  State<DetailOrderLayananAdminPage> createState() =>
      _DetailOrderLayananAdminPageState();
}

class _DetailOrderLayananAdminPageState
    extends State<DetailOrderLayananAdminPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  OrderLayananDetailAdmin? _order;

  bool _isAssigningKoordinator = false;
  List<KoordinatorOption> _koordinators = [];
  int? _selectedKoordinatorId;

  late final TabController _tabController;

  static const Color _primary = AppColors.primary;
  static const Color _primaryDark = AppColors.primaryDark;
  static const Color _bg = AppColors.bg;
  static const Color _errorColor = AppColors.error;
  static const Color _textMuted = AppColors.textMuted;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initialLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        LayananMasukAdminService.fetchOrderDetail(widget.orderId),
        LayananMasukAdminService.fetchKoordinators(),
      ]);

      if (!mounted) return;

      final orderData = results[0] as OrderLayananDetailAdmin;
      final koorData = results[1] as List<KoordinatorOption>;

      setState(() {
        _order = orderData;
        _koordinators = koorData;
        _selectedKoordinatorId = orderData.koordinatorId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _assignKoordinator() async {
    if (_selectedKoordinatorId == null) {
      _showSnackBar(
        'Silakan pilih koordinator terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() => _isAssigningKoordinator = true);

    try {
      final updatedOrder = await LayananMasukAdminService.assignKoordinator(
        widget.orderId,
        _selectedKoordinatorId!,
      );

      if (!mounted) return;
      setState(() => _order = updatedOrder);

      _showSnackBar('Koordinator berhasil ditugaskan.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isAssigningKoordinator = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _errorColor : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kodeOrder = _order?.kodeOrder ?? 'Detail Order';
    final status = _order?.statusOrder ?? 'pending';

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(kodeOrder, status),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _primary),
                    SizedBox(height: 16),
                    Text('Memuat detail order...'),
                  ],
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_order != null)
            SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildAppBar(String kodeOrder, String status) {
    final statusColor = OrderStatusHelper.color(status);
    final statusLabel = OrderStatusHelper.label(status);

    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: _primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          kodeOrder,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Text(
            statusLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: _errorColor),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initialLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
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
    return RefreshIndicator(
      onRefresh: _initialLoad,
      color: _primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            OrderQuickInfoCard(order: _order!),
            const SizedBox(height: 16),
            _buildTabbedContent(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTabbedContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: _primary,
            unselectedLabelColor: _textMuted,
            indicatorColor: _primary,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Detail'),
              Tab(text: 'Lokasi'),
              Tab(text: 'Pembayaran'),
              Tab(text: 'Addons'),
              Tab(text: 'Koordinator'),
              Tab(text: 'Foto'),
            ],
          ),
          SizedBox(
            height: 450,
            child: TabBarView(
              controller: _tabController,
              children: [
                OrderDetailInfoTab(order: _order!),
                OrderLokasiTab(order: _order!),
                OrderPembayaranTab(order: _order!),
                OrderAddonsTab(order: _order!),
                OrderKoordinatorTab(
                  order: _order!,
                  koordinators: _koordinators,
                  isAssigning: _isAssigningKoordinator,
                  selectedKoordinatorId: _selectedKoordinatorId,
                  onKoordinatorSelected: (val) {
                    setState(() => _selectedKoordinatorId = val);
                  },
                  onAssignKoordinator: _assignKoordinator,
                ),
                OrderFotoTab(order: _order!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

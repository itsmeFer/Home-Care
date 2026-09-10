import 'package:flutter/material.dart';
import 'package:home_care/admin/layanan_masuk/detail_order_layanan_admin_page.dart';
import 'package:home_care/admin/layanan_masuk/services/layanan_masuk_admin_service.dart';
import 'package:home_care/admin/layanan_masuk/widgets/order_filter_card.dart';
import 'package:home_care/admin/layanan_masuk/widgets/order_layanan_card.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/orders/domain/order_models.dart';

class LihatLayananMasukPage extends StatefulWidget {
  const LihatLayananMasukPage({super.key});

  @override
  State<LihatLayananMasukPage> createState() => _LihatLayananMasukPageState();
}

class _LihatLayananMasukPageState extends State<LihatLayananMasukPage> {
  bool _isLoading = true;
  String? _error;
  List<OrderLayananAdmin> _orders = [];
  String? _selectedStatus;

  static const Color _primary = AppColors.primary;
  static const Color _primaryDark = AppColors.primaryDark;
  static const Color _bg = AppColors.bg;
  static const Color _errorColor = AppColors.error;
  static const Color _textMuted = AppColors.textMuted;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await LayananMasukAdminService.fetchOrders(
        status: _selectedStatus,
      );

      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        _orders.where((o) => o.statusOrder == 'pending').length;
    final selesaiCount =
        _orders.where((o) => o.statusOrder == 'selesai').length;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: OrderFilterCard(
              selectedStatus: _selectedStatus,
              totalCount: _orders.length,
              pendingCount: pendingCount,
              selesaiCount: selesaiCount,
              onStatusChanged: (val) {
                setState(() => _selectedStatus = val);
                _fetchOrders();
              },
            ),
          ),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: _primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Layanan Masuk',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh',
          onPressed: _fetchOrders,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _primary),
              SizedBox(height: 16),
              Text('Memuat data...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(child: _buildError());
    }

    if (_orders.isEmpty) {
      return SliverFillRemaining(child: _buildEmpty());
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final order = _orders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OrderLayananCard(
                order: order,
                onTap: () async {
                  final needRefresh = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetailOrderLayananAdminPage(orderId: order.id),
                    ),
                  );

                  if (needRefresh == true) {
                    _fetchOrders();
                  }
                },
              ),
            );
          },
          childCount: _orders.length,
        ),
      ),
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
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 80, color: _textMuted),
          const SizedBox(height: 16),
          const Text(
            'Belum ada order layanan',
            style: TextStyle(
              fontSize: 16,
              color: _textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus != null
                ? 'Tidak ada order dengan status ini'
                : 'Order akan muncul di sini',
            style: const TextStyle(fontSize: 13, color: _textMuted),
          ),
        ],
      ),
    );
  }
}

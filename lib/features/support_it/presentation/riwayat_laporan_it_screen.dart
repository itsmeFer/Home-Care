import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/support_it/data/support_it_service.dart';
import 'package:home_care/features/support_it/domain/support_it_models.dart';
import 'package:home_care/features/support_it/presentation/widgets/ticket_card.dart';
import 'package:home_care/features/support_it/presentation/widgets/ticket_detail_sheet.dart';
import 'package:home_care/features/support_it/presentation/widgets/ticket_filter_dialog.dart';

class RiwayatLaporanITScreen extends StatefulWidget {
  final String source;

  const RiwayatLaporanITScreen({
    super.key,
    this.source = 'user.lapor_it',
  });

  @override
  State<RiwayatLaporanITScreen> createState() => _RiwayatLaporanITScreenState();
}

class _RiwayatLaporanITScreenState extends State<RiwayatLaporanITScreen> {
  static const Color _bg = AppColors.background;
  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _primary = Color(0xFF0EA5E9);
  static const Color _danger = AppColors.danger;

  bool _isLoading = true;
  List<SupportTicket> _tickets = [];
  String? _errorMessage;

  String? _filterStatus;
  String? _filterPriority;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tickets = await SupportItService.fetchTickets(
        status: _filterStatus,
        priority: _filterPriority,
      );
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openFilter() async {
    final result = await TicketFilterDialog.show(
      context,
      initialStatus: _filterStatus,
      initialPriority: _filterPriority,
    );
    if (result != null) {
      setState(() {
        _filterStatus = result.status;
        _filterPriority = result.priority;
      });
      _loadTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 760;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _text, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Laporan IT',
          style: TextStyle(
            color: _text,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: (_filterStatus != null || _filterPriority != null)
                  ? _primary
                  : _text,
            ),
            onPressed: _openFilter,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        child: _buildBody(isMobile),
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: _danger.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTickets,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
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

    if (_tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: _muted.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada laporan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Laporan IT Anda akan muncul di sini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _muted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return TicketCard(
          ticket: ticket,
          isMobile: isMobile,
          onTap: () => TicketDetailSheet.show(context, ticket),
        );
      },
    );
  }
}

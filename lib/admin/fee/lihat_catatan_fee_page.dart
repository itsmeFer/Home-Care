import 'package:flutter/material.dart';
import 'package:home_care/admin/fee/services/fee_catatan_service.dart';
import 'package:home_care/admin/fee/widgets/user_fee_distribution_chart.dart';
import 'package:home_care/admin/fee/widgets/user_fee_filter_row.dart';
import 'package:home_care/admin/fee/widgets/user_fee_leaderboard_card.dart';
import 'package:home_care/admin/fee/widgets/user_fee_picker_card.dart';
import 'package:home_care/admin/fee/widgets/user_fee_summary_card.dart';
import 'package:home_care/admin/fee/widgets/user_fee_timeline_chart.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';

class LihatCatatanFeePage extends StatefulWidget {
  const LihatCatatanFeePage({super.key});

  @override
  State<LihatCatatanFeePage> createState() => _LihatCatatanFeePageState();
}

class _LihatCatatanFeePageState extends State<LihatCatatanFeePage> {
  static const Color _bg = AppColors.background;
  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _textSub = AppColors.textSecondary;
  static const Color _primary = Color(0xFF2563EB);
  static const Color _danger = AppColors.danger;

  SimpleUserOption? _selectedUser;
  List<SimpleUserOption> _userSearchResults = [];
  String _userSearchQuery = '';
  bool _isSearchingUser = false;

  String _selectedRange = '30_hari_terakhir';
  String _selectedStatus = 'semua';
  int? _selectedLayananId;

  bool _isLoadingData = false;
  String? _errorMessage;
  FeeCatatanUserData _data = const FeeCatatanUserData.empty();

  final TextEditingController _userSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchUsers();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    setState(() => _isSearchingUser = true);

    try {
      final results = await FeeCatatanService.searchUsers(_userSearchQuery);
      if (!mounted) return;

      _userSearchResults = results;

      if (_selectedUser == null && _userSearchResults.isNotEmpty) {
        _selectedUser = _userSearchResults.first;
        _selectedLayananId = null;
        await _loadFeeData();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSearchingUser = false);
    }
  }

  Future<void> _loadFeeData() async {
    if (_selectedUser == null) return;

    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final res = await FeeCatatanService.fetchCatatanUser(
        userId: _selectedUser!.id,
        range: _selectedRange,
        status: _selectedStatus,
        layananId: _selectedLayananId,
      );
      if (!mounted) return;
      setState(() {
        _data = res;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoadingData = false;
      });
    }
  }

  FeeByLayanan? get _selectedLayanan {
    if (_selectedLayananId == null || _data.byLayanan.isEmpty) return null;
    return _data.byLayanan.firstWhere(
      (e) => e.layananId == _selectedLayananId,
      orElse: () => _data.byLayanan.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _text),
        title: const Text(
          'Catatan Fee User (Admin)',
          style: TextStyle(color: _text, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_selectedUser != null) {
            await _loadFeeData();
          } else {
            await _searchUsers();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            UserFeePickerCard(
              searchController: _userSearchController,
              isSearching: _isSearchingUser,
              searchResults: _userSearchResults,
              selectedUser: _selectedUser,
              onUserSelected: (u) async {
                setState(() {
                  _selectedUser = u;
                  _selectedLayananId = null;
                });
                await _loadFeeData();
              },
              onSearch: _searchUsers,
              onQueryChanged: (val) => _userSearchQuery = val,
            ),
            const SizedBox(height: 12),
            if (_selectedUser != null)
              UserFeeFilterRow(
                selectedRange: _selectedRange,
                onRangeChanged: (val) {
                  setState(() => _selectedRange = val);
                  _loadFeeData();
                },
                selectedStatus: _selectedStatus,
                onStatusChanged: (val) {
                  setState(() => _selectedStatus = val);
                  _loadFeeData();
                },
                selectedLayananId: _selectedLayananId,
                byLayanan: _data.byLayanan,
                onLayananChanged: (val) {
                  setState(() => _selectedLayananId = val);
                  _loadFeeData();
                },
              ),
            const SizedBox(height: 12),
            if (_selectedUser != null)
              _buildMainContent()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Text(
        'Pilih user terlebih dahulu untuk melihat catatan fee.',
        style: TextStyle(color: _textSub, fontSize: 13),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoadingData) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _danger.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gagal memuat catatan fee',
              style: TextStyle(
                color: _danger,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              style: const TextStyle(color: _textSub, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loadFeeData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
                style: TextButton.styleFrom(foregroundColor: _primary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        UserFeeSummaryCard(
          selectedLayanan: _selectedLayanan,
          totalSemuaLayanan: _data.totalSemuaLayanan,
        ),
        const SizedBox(height: 16),
        UserFeeTimelineChart(timeline: _data.timeline),
        const SizedBox(height: 16),
        UserFeeDistributionChart(byLayanan: _data.byLayanan),
        const SizedBox(height: 16),
        UserFeeLeaderboardCard(
          leaderboard: _data.leaderboard,
          selectedUser: _selectedUser,
        ),
      ],
    );
  }
}

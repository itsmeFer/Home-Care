import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/admin/banners/form_banner_page.dart';
import 'package:home_care/admin/banners/widgets/banner_card_badges.dart';
import 'package:home_care/admin/banners/widgets/banner_filter_bar.dart';
import 'package:home_care/admin/banners/widgets/banner_reorder_sheet.dart';
import 'package:home_care/admin/banners/widgets/banner_states.dart';
import 'package:home_care/admin/banners/widgets/full_width_banner_card.dart';
import 'package:home_care/admin/banners/widgets/landscape_banner_card.dart';
import 'package:home_care/admin/banners/widgets/square_banner_card.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';
import 'package:home_care/features/banners/data/banner_service.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';

class CrudBannerPage extends StatefulWidget {
  const CrudBannerPage({super.key});

  @override
  State<CrudBannerPage> createState() => _CrudBannerPageState();
}

class _CrudBannerPageState extends State<CrudBannerPage> {
  List<BannerModel> _banners = [];
  bool _loading = true;
  String? _errorMessage;

  String _q = '';
  String? _selectedType;
  int? _filterActive;

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final data = await BannerService.getAll();
      if (mounted) setState(() => _banners = data);
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        setState(() => _errorMessage = cleanMsg);
        _snack('Gagal memuat: $cleanMsg', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAktif(BannerModel b) async {
    try {
      await BannerService.toggle(b.id);
      _snack(b.aktif ? 'Banner dinonaktifkan' : 'Banner diaktifkan');
      _load();
    } catch (e) {
      _snack('Gagal: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    }
  }

  Future<void> _hapus(BannerModel b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Banner?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          'Hapus banner "${b.judul ?? 'Tanpa Judul'}"? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await BannerService.delete(b.id);
      _snack('Banner berhasil dihapus');
      _load();
    } catch (e) {
      _snack('Gagal: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll('Exception: ', '')),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _bukaForm([BannerModel? b]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormBannerPage(banner: b)),
    );
    _load();
  }

  Future<void> _bukaAturUrutan() async {
    final updated = await BannerReorderSheet.show(
      context: context,
      banners: _banners,
    );
    if (updated == true) {
      _snack('Urutan banner berhasil disimpan');
      _load();
    }
  }

  void _resetFilter() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _q = '';
      _selectedType = null;
      _filterActive = null;
    });
  }

  List<BannerModel> get _filteredBanners {
    return _banners.where((b) {
      if (_q.isNotEmpty) {
        final q = _q.toLowerCase().trim();
        final matchJudul = (b.judul ?? '').toLowerCase().contains(q);
        final matchSub = (b.subtitle ?? '').toLowerCase().contains(q);
        final matchPromo = (b.kodePromo ?? '').toLowerCase().contains(q);
        final matchTeks = (b.teksDiskon ?? '').toLowerCase().contains(q);
        if (!matchJudul && !matchSub && !matchPromo && !matchTeks) return false;
      }
      if (_selectedType != null && b.tipeCard != _selectedType) return false;
      if (_filterActive != null) {
        if (_filterActive == 1 && !b.aktif) return false;
        if (_filterActive == 0 && b.aktif) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Kelola Banner',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Atur Urutan Banner',
            icon: const Icon(Icons.swap_vert_rounded),
            onPressed: _banners.isEmpty ? null : _bukaAturUrutan,
          ),
          IconButton(
            tooltip: 'Muat Ulang',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        backgroundColor: AppColors.primary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Banner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          BannerFilterBar(
            searchCtrl: _searchCtrl,
            query: _q,
            selectedType: _selectedType,
            filterActive: _filterActive,
            onQueryChanged: (v) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                if (mounted) setState(() => _q = v);
              });
            },
            onClearQuery: () {
              _searchDebounce?.cancel();
              _searchCtrl.clear();
              setState(() => _q = '');
            },
            onTypeChanged: (type) => setState(() => _selectedType = type),
            onActiveChanged: (active) => setState(() => _filterActive = active),
            onReset: _resetFilter,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _banners.isEmpty) {
      return _buildSkeletonLoader();
    }

    if (_errorMessage != null && _banners.isEmpty) {
      return BannerErrorState(
        errorMessage: _errorMessage,
        onRetry: _load,
      );
    }

    final filtered = _filteredBanners;

    if (filtered.isEmpty) {
      return BannerEmptyState(
        hasFilter: _q.isNotEmpty || _selectedType != null || _filterActive != null,
        onResetFilter: _resetFilter,
        onAddBanner: () => _bukaForm(),
      );
    }

    final landscape = filtered.where((b) => b.tipeCard == 'landscape').toList();
    final square = filtered.where((b) => b.tipeCard == 'square').toList();
    final fullWidth = filtered.where((b) => b.tipeCard == 'full_width').toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (landscape.isNotEmpty) ...[
                  BannerSectionHeader(
                    icon: Icons.view_day_outlined,
                    title: 'Tipe Landscape',
                    subtitle: 'Banner lebar (rasio 5:2) — tampil pada carousel utama beranda',
                    count: landscape.length,
                  ),
                  const SizedBox(height: 10),
                  ...landscape.map(
                    (b) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: LandscapeBannerCard(
                        banner: b,
                        onToggle: () => _toggleAktif(b),
                        onEdit: () => _bukaForm(b),
                        onDelete: () => _hapus(b),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (square.isNotEmpty) ...[
                  BannerSectionHeader(
                    icon: Icons.grid_view_rounded,
                    title: 'Tipe Square',
                    subtitle: 'Banner kotak (rasio 1:1) — cocok untuk etalase grid promo',
                    count: square.length,
                  ),
                  const SizedBox(height: 10),
                ],
              ]),
            ),
          ),
          if (square.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => SquareBannerCard(
                    banner: square[i],
                    onToggle: () => _toggleAktif(square[i]),
                    onEdit: () => _bukaForm(square[i]),
                    onDelete: () => _hapus(square[i]),
                  ),
                  childCount: square.length,
                ),
              ),
            ),
          if (fullWidth.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  BannerSectionHeader(
                    icon: Icons.view_carousel_outlined,
                    title: 'Tipe Full Width',
                    subtitle: 'Banner list horizontal — kartu lebar dengan deskripsi detail',
                    count: fullWidth.length,
                  ),
                  const SizedBox(height: 10),
                  ...fullWidth.map(
                    (b) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: FullWidthBannerCard(
                        banner: b,
                        onToggle: () => _toggleAktif(b),
                        onEdit: () => _bukaForm(b),
                        onDelete: () => _hapus(b),
                      ),
                    ),
                  ),
                ]),
              ),
            )
          else
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(14),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton(height: 130, width: double.infinity, borderRadius: 12),
            SizedBox(height: 12),
            AppSkeleton.text(width: 200, height: 16),
            SizedBox(height: 6),
            AppSkeleton.text(width: 140, height: 12),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSkeleton(width: 90, height: 26, borderRadius: 8),
                AppSkeleton(width: 50, height: 26, borderRadius: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

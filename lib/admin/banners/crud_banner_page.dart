import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/banners/data/banner_service.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';
import 'package:home_care/admin/banners/form_banner_page.dart';
import 'package:home_care/admin/banners/widgets/banner_card_badges.dart';
import 'package:home_care/admin/banners/widgets/full_width_banner_card.dart';
import 'package:home_care/admin/banners/widgets/landscape_banner_card.dart';
import 'package:home_care/admin/banners/widgets/square_banner_card.dart';

class CrudBannerPage extends StatefulWidget {
  const CrudBannerPage({super.key});

  @override
  State<CrudBannerPage> createState() => _CrudBannerPageState();
}

class _CrudBannerPageState extends State<CrudBannerPage> {
  List<BannerModel> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await BannerService.getAll();
      if (mounted) setState(() => _banners = data);
    } catch (e) {
      _snack('Gagal memuat: $e', isError: true);
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
      _snack('Gagal: $e', isError: true);
    }
  }

  Future<void> _hapus(BannerModel b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Banner', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Hapus banner "${b.judul ?? 'Tanpa Judul'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      _snack('Gagal: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll('Exception: ', '')),
        backgroundColor: isError ? Colors.red : AppColors.primary,
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

  @override
  Widget build(BuildContext context) {
    final landscape = _banners.where((b) => b.tipeCard == 'landscape').toList();
    final square = _banners.where((b) => b.tipeCard == 'square').toList();
    final fullWidth = _banners.where((b) => b.tipeCard == 'full_width').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kelola Banner',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Banner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _banners.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      if (landscape.isNotEmpty) ...[
                        BannerSectionHeader(
                          icon: Icons.view_day_outlined,
                          title: 'Tipe Landscape',
                          subtitle: 'Banner lebar (rasio 5:2) — cocok untuk carousel utama',
                          count: landscape.length,
                        ),
                        const SizedBox(height: 10),
                        ...landscape.map(
                          (b) => LandscapeBannerCard(
                            banner: b,
                            onToggle: () => _toggleAktif(b),
                            onEdit: () => _bukaForm(b),
                            onDelete: () => _hapus(b),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (square.isNotEmpty) ...[
                        BannerSectionHeader(
                          icon: Icons.grid_view_rounded,
                          title: 'Tipe Square',
                          subtitle: 'Banner kotak (rasio 1:1) — cocok untuk grid promo',
                          count: square.length,
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: square.length,
                          itemBuilder: (_, i) => SquareBannerCard(
                            banner: square[i],
                            onToggle: () => _toggleAktif(square[i]),
                            onEdit: () => _bukaForm(square[i]),
                            onDelete: () => _hapus(square[i]),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (fullWidth.isNotEmpty) ...[
                        BannerSectionHeader(
                          icon: Icons.view_carousel_outlined,
                          title: 'Tipe Full Width',
                          subtitle: 'Banner horizontal scroll — seperti GoFood/GoMart',
                          count: fullWidth.length,
                        ),
                        const SizedBox(height: 10),
                        ...fullWidth.map(
                          (b) => FullWidthBannerCard(
                            banner: b,
                            onToggle: () => _toggleAktif(b),
                            onEdit: () => _bukaForm(b),
                            onDelete: () => _hapus(b),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFE6FAFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_not_supported_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada banner',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Tambah banner untuk carousel pasien',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _bukaForm(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Banner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
}

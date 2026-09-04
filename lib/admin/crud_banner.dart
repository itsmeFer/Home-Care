import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';
import 'package:home_care/features/banners/data/banner_service.dart';
import 'package:home_care/utils/app_cached_image.dart';

export 'package:home_care/features/banners/domain/banner_model.dart';
export 'package:home_care/features/banners/data/banner_service.dart';
import 'package:home_care/features/banners/presentation/form_banner_page.dart';
export 'package:home_care/features/banners/presentation/form_banner_page.dart';

class _Cfg {
  static String get baseUrl => ApiConstants.apiBase;
  static String get bannerUrl => ApiConstants.adminBanners;
  static String get layananUrl => ApiConstants.adminLayanan;
  static String get kategoriUrl => ApiConstants.adminKategoriLayanan;
  static const String tokenKey = 'auth_token';
}

class _AC {
  static const primary = AppColors.primary;
  static const light = Color(0xFFE6FAFA);
  static const bg = AppColors.background;
}

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
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Hapus Banner',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
        content: Text(msg),
        backgroundColor: isError ? Colors.red : _AC.primary,
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
    final fullWidth =
        _banners.where((b) => b.tipeCard == 'full_width').toList();

    return Scaffold(
      backgroundColor: _AC.bg,
      appBar: AppBar(
        title: const Text(
          'Kelola Banner',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _AC.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        backgroundColor: _AC.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Banner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: _AC.primary),
              )
              : _banners.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                onRefresh: _load,
                color: _AC.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    if (landscape.isNotEmpty) ...[
                      _sectionHeader(
                        icon: Icons.view_day_outlined,
                        title: 'Tipe Landscape',
                        subtitle:
                            'Banner lebar (rasio 5:2) — cocok untuk carousel utama',
                        count: landscape.length,
                      ),
                      const SizedBox(height: 10),
                      ...landscape.map((b) => _buildLandscapeCard(b)),
                      const SizedBox(height: 8),
                    ],
                    if (square.isNotEmpty) ...[
                      _sectionHeader(
                        icon: Icons.grid_view_rounded,
                        title: 'Tipe Square',
                        subtitle:
                            'Banner kotak (rasio 1:1) — cocok untuk grid promo',
                        count: square.length,
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                        itemCount: square.length,
                        itemBuilder: (_, i) => _buildSquareCard(square[i]),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (fullWidth.isNotEmpty) ...[
                      _sectionHeader(
                        icon: Icons.view_carousel_outlined,
                        title: 'Tipe Full Width',
                        subtitle:
                            'Banner horizontal scroll — seperti GoFood/GoMart',
                        count: fullWidth.length,
                      ),
                      const SizedBox(height: 10),
                      ...fullWidth.map((b) => _buildFullWidthCard(b)),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AC.primary.withOpacity(.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _AC.light,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _AC.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _AC.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeCard(BannerModel b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child:
                      b.gambarUrl != null
                          ? AppCachedImage(
                            imageUrl: b.gambarUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: _placeholder(160),
                            errorWidget: _placeholder(160),
                          )
                          : _placeholder(160),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(.60),
                          Colors.black.withOpacity(.05),
                        ],
                      ),
                    ),
                  ),
                ),
                if (b.judul != null && b.judul!.isNotEmpty)
                  Positioned(
                    left: 14,
                    right: 60,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.judul!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (b.subtitle != null && b.subtitle!.isNotEmpty)
                          Text(
                            b.subtitle!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                Positioned(top: 10, right: 10, child: _badgeUrutan(b.urutan)),
                if (b.tipeDiskon != 'none' && b.teksDiskon != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _badgeDiskon(b.teksDiskon!),
                  ),
                if (b.layananId != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.link, size: 10, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Linked',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _cardActions(b),
        ],
      ),
    );
  }

  Widget _buildSquareCard(BannerModel b) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  b.gambarUrl != null
                      ? AppCachedImage(
                        imageUrl: b.gambarUrl,
                        fit: BoxFit.cover,
                        placeholder: _placeholder(null),
                        errorWidget: _placeholder(null),
                      )
                      : _placeholder(null),
                  if (b.tipeDiskon != 'none' && b.teksDiskon != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_offer,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              b.teksDiskon!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _badgeUrutan(b.urutan, small: true),
                  ),
                  if (b.layananId != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.link, size: 9, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'Linked',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.judul ?? 'Tanpa Judul',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFF1E3A5F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (b.subtitle != null && b.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    b.subtitle!,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (b.kodePromo != null && b.kodePromo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.discount,
                          size: 9,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          b.kodePromo!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleAktif(b),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: b.aktif ? _AC.light : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: b.aktif ? _AC.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          b.aktif ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: b.aktif ? _AC.primary : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _bukaForm(b),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_outlined,
                              color: _AC.primary,
                              size: 18,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _hapus(b),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthCard(BannerModel b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [

              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      color: _AC.light,
                      child:
                          b.gambarUrl != null
                              ? AppCachedImage(
                                imageUrl: b.gambarUrl,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                                placeholder: _placeholder(140),
                                errorWidget: _placeholder(140),
                              )
                              : _placeholder(140),
                    ),
                    if (b.tipeDiskon != 'none' && b.teksDiskon != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            b.teksDiskon!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.judul ?? 'Tanpa Judul',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF1E3A5F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (b.subtitle != null && b.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          b.subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _badgeUrutan(b.urutan, small: true),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _toggleAktif(b),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    b.aktif ? _AC.light : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      b.aktif
                                          ? _AC.primary
                                          : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                b.aktif ? 'Aktif' : 'Nonaktif',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: b.aktif ? _AC.primary : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          if (b.layananId != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.link,
                                    size: 9,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    'Linked',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _bukaForm(b),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: _AC.primary,
                                    size: 18,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _hapus(b),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (b.kodePromo != null && b.kodePromo!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.discount, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Kode: ${b.kodePromo}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardActions(BannerModel b) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleAktif(b),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: b.aktif ? _AC.light : Colors.grey.withOpacity(.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: b.aktif ? _AC.primary : Colors.grey.shade400,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    b.aktif ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: b.aktif ? _AC.primary : Colors.grey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    b.aktif ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: b.aktif ? _AC.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (b.kodePromo != null && b.kodePromo!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.discount, size: 12, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    b.kodePromo!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _AC.primary),
            onPressed: () => _bukaForm(b),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _hapus(b),
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
  }

  Widget _badgeDiskon(String teks) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_offer, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          teks,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _badgeUrutan(int urutan, {bool small = false}) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: small ? 7 : 10,
      vertical: small ? 3 : 4,
    ),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '#$urutan',
      style: TextStyle(
        color: Colors.white,
        fontSize: small ? 10 : 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: _AC.light,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.image_not_supported_outlined,
            size: 44,
            color: _AC.primary,
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
            backgroundColor: _AC.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _placeholder(double? height) => Container(
    height: height,
    width: double.infinity,
    color: _AC.light,
    child: const Center(
      child: Icon(Icons.image_outlined, size: 40, color: _AC.primary),
    ),
  );
}

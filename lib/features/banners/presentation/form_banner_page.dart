import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';
import 'package:home_care/features/banners/data/banner_service.dart';
import 'package:home_care/utils/app_cached_image.dart';

class _AC {
  static const primary = AppColors.primary;
  static const light = Color(0xFFE6FAFA);
  static const bg = AppColors.background;
}
class FormBannerPage extends StatefulWidget {
  final BannerModel? banner;
  const FormBannerPage({super.key, this.banner});
  @override
  State<FormBannerPage> createState() => _FormBannerPageState();
}

class _FormBannerPageState extends State<FormBannerPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _subCtrl = TextEditingController();
  final _urutanCtrl = TextEditingController();
  final _nilaiDiskonCtrl = TextEditingController();
  final _maxDiskonCtrl = TextEditingController();
  final _kodePromoCtrl = TextEditingController();
  final _minTransaksiCtrl = TextEditingController();
  final _teksDiskonCtrl = TextEditingController();

  bool _aktif = true;
  bool _loading = false;
  String _tipeCard = 'landscape';
  String _tipeDiskon = 'none';

  XFile? _xfile;
  Uint8List? _webBytes;

  List<LayananModel> _layananList = [];
  LayananModel? _selectedLayanan;
  bool _loadingLayanan = true;

  bool get _isEdit => widget.banner != null;

  @override
  void initState() {
    super.initState();
    _loadLayanan();
    if (_isEdit) {
      final b = widget.banner!;
      _judulCtrl.text = b.judul ?? '';
      _subCtrl.text = b.subtitle ?? '';
      _urutanCtrl.text = b.urutan.toString();
      _aktif = b.aktif;
      _tipeCard = b.tipeCard;
      _tipeDiskon = b.tipeDiskon;

      if (b.nilaiDiskon > 0) {
        _nilaiDiskonCtrl.text =
            _tipeDiskon == 'nominal'
                ? formatRupiah(b.nilaiDiskon)
                : b.nilaiDiskon.toString();
      }
      if (b.maxDiskon != null && b.maxDiskon! > 0) {
        _maxDiskonCtrl.text = formatRupiah(b.maxDiskon!);
      }
      if (b.minTransaksi > 0) {
        _minTransaksiCtrl.text = formatRupiah(b.minTransaksi);
      }

      _kodePromoCtrl.text = b.kodePromo ?? '';
      _teksDiskonCtrl.text = b.teksDiskon ?? '';
    } else {
      _urutanCtrl.text = '0';
      _nilaiDiskonCtrl.text = '';
      _minTransaksiCtrl.text = '';
    }
  }

  Future<void> _loadLayanan() async {
    setState(() => _loadingLayanan = true);
    try {
      final list = await BannerService.getLayananList();
      if (mounted) {
        setState(() {
          _layananList = list;
          if (_isEdit && widget.banner!.layananId != null) {
            _selectedLayanan = _layananList.firstWhere(
              (l) => l.id == widget.banner!.layananId,
              orElse: () => _layananList.first,
            );
          }
        });
      }
    } catch (e) {
      _snack('Gagal memuat layanan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingLayanan = false);
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _subCtrl.dispose();
    _urutanCtrl.dispose();
    _nilaiDiskonCtrl.dispose();
    _maxDiskonCtrl.dispose();
    _kodePromoCtrl.dispose();
    _minTransaksiCtrl.dispose();
    _teksDiskonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihGambar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _xfile = picked;
      _webBytes = bytes;
    });
  }

  Future<void> _showLayananSearchDialog() async {
    final TextEditingController searchCtrl = TextEditingController();
    List<LayananModel> filteredList = List.from(_layananList);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void _filterLayanan(String query) {
              setDialogState(() {
                if (query.isEmpty) {
                  filteredList = List.from(_layananList);
                } else {
                  filteredList =
                      _layananList.where((l) {
                        final name = l.namaLayanan.toLowerCase();
                        final code = l.kodeLayanan.toLowerCase();
                        final q = query.toLowerCase();
                        return name.contains(q) || code.contains(q);
                      }).toList();
                }
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 600),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.search, color: _AC.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Pilih Layanan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau kode layanan...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: _AC.primary,
                        ),
                        suffixIcon:
                            searchCtrl.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchCtrl.clear();
                                    _filterLayanan('');
                                  },
                                )
                                : null,
                        filled: true,
                        fillColor: _AC.light,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: _filterLayanan,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.block, color: Colors.grey),
                      ),
                      title: const Text(
                        'Tidak ada layanan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      subtitle: const Text(
                        'Banner tanpa link ke layanan',
                        style: TextStyle(fontSize: 12),
                      ),
                      tileColor:
                          _selectedLayanan == null
                              ? _AC.light
                              : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color:
                              _selectedLayanan == null
                                  ? _AC.primary
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedLayanan = null);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child:
                          filteredList.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tidak ada layanan ditemukan',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredList.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, i) {
                                  final l = filteredList[i];
                                  final isSelected =
                                      _selectedLayanan?.id == l.id;

                                  return ListTile(
                                    leading:
                                        l.gambarUrl != null
                                            ? AppCachedImage(
                                              imageUrl: l.gambarUrl,
                                              width: 50,
                                              height: 50,
                                              borderRadius: BorderRadius.circular(8),
                                              fit: BoxFit.cover,
                                              errorWidget: const Icon(Icons.image, size: 50),
                                            )
                                            : Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: _AC.light,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.medical_services,
                                                color: _AC.primary,
                                              ),
                                            ),
                                    title: Text(
                                      l.namaLayanan,
                                      style: TextStyle(
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l.kodeLayanan,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        Text(
                                          formatRupiah(l.hargaFix),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _AC.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    tileColor:
                                        isSelected
                                            ? _AC.light
                                            : Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color:
                                            isSelected
                                                ? _AC.primary
                                                : Colors.grey.shade200,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    trailing:
                                        isSelected
                                            ? Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: _AC.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            )
                                            : null,
                                    onTap: () {
                                      setState(() => _selectedLayanan = l);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _hitungHargaDiskon() {
    if (_selectedLayanan == null || _tipeDiskon == 'none') return 0;

    final hargaAsli = _selectedLayanan!.hargaFix;
    double diskon = 0;

    if (_tipeDiskon == 'nominal') {
      diskon = parseRupiah(_nilaiDiskonCtrl.text);
    } else if (_tipeDiskon == 'persen') {
      final persen = double.tryParse(_nilaiDiskonCtrl.text) ?? 0;
      diskon = (hargaAsli * persen) / 100;

      final maxDiskon = parseRupiah(_maxDiskonCtrl.text);
      if (maxDiskon > 0 && diskon > maxDiskon) {
        diskon = maxDiskon;
      }
    }

    return (hargaAsli - diskon).clamp(0, double.infinity);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final judul =
          _judulCtrl.text.trim().isEmpty ? null : _judulCtrl.text.trim();
      final sub = _subCtrl.text.trim().isEmpty ? null : _subCtrl.text.trim();
      final kode =
          _kodePromoCtrl.text.trim().isEmpty
              ? null
              : _kodePromoCtrl.text.trim();
      final teks =
          _teksDiskonCtrl.text.trim().isEmpty
              ? null
              : _teksDiskonCtrl.text.trim();

      double nilaiDiskon = 0;
      if (_tipeDiskon == 'nominal') {
        nilaiDiskon = parseRupiah(_nilaiDiskonCtrl.text);
      } else if (_tipeDiskon == 'persen') {
        nilaiDiskon = double.tryParse(_nilaiDiskonCtrl.text) ?? 0;
      }

      final maxDiskon =
          _maxDiskonCtrl.text.isEmpty ? null : parseRupiah(_maxDiskonCtrl.text);
      final minTransaksi = parseRupiah(_minTransaksiCtrl.text);

      if (_isEdit) {
        await BannerService.update(
          id: widget.banner!.id,
          layananId: _selectedLayanan?.id,
          judul: judul,
          subtitle: sub,
          urutan: int.tryParse(_urutanCtrl.text) ?? 0,
          aktif: _aktif,
          tipeCard: _tipeCard,
          tipeDiskon: _tipeDiskon,
          nilaiDiskon: nilaiDiskon,
          maxDiskon: maxDiskon,
          kodePromo: kode,
          minTransaksi: minTransaksi,
          teksDiskon: teks,
        );
        if (_xfile != null) {
          await BannerService.uploadGambar(
            id: widget.banner!.id,
            gambar: _xfile!,
          );
        }
        _snack('Banner berhasil diperbarui');
      } else {
        await BannerService.create(
          layananId: _selectedLayanan?.id,
          judul: judul,
          subtitle: sub,
          urutan: int.tryParse(_urutanCtrl.text) ?? 0,
          aktif: _aktif,
          gambar: _xfile,
          tipeCard: _tipeCard,
          tipeDiskon: _tipeDiskon,
          nilaiDiskon: nilaiDiskon,
          maxDiskon: maxDiskon,
          kodePromo: kode,
          minTransaksi: minTransaksi,
          teksDiskon: teks,
        );
        _snack('Banner berhasil ditambahkan');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
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

  bool get _hasGambarBaru => _webBytes != null;
  bool get _hasGambarLama => _isEdit && widget.banner!.gambarUrl != null;
  bool get _hasGambar => _hasGambarBaru || _hasGambarLama;

  Widget _buildPreviewBg() {
    if (_hasGambarBaru) return Image.memory(_webBytes!, fit: BoxFit.cover);
    if (_hasGambarLama) {
      return AppCachedImage(
        imageUrl: widget.banner!.gambarUrl!,
        fit: BoxFit.cover,
        errorWidget: _emptyPreview(),
        placeholder: _emptyPreview(),
      );
    }
    return _emptyPreview();
  }

  Widget _emptyPreview() => Container(
    color: _AC.light,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 44,
          color: _AC.primary.withOpacity(.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Pilih Gambar Banner',
          style: TextStyle(
            color: _AC.primary.withOpacity(.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Preview tampil seperti di halaman pasien',
          style: TextStyle(color: Colors.grey[400], fontSize: 11),
        ),
      ],
    ),
  );

  Widget _buildFullWidthPreview() {
    return Row(
      children: [

        Container(
          width: 140,
          height: 140,
          color: _AC.light,
          child:
              _hasGambar
                  ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _hasGambarBaru
                          ? Image.memory(_webBytes!, fit: BoxFit.cover)
                          : AppCachedImage(
                            imageUrl: widget.banner!.gambarUrl!,
                            fit: BoxFit.cover,
                            errorWidget: _emptyPreview(),
                            placeholder: _emptyPreview(),
                          ),
                      if (_tipeDiskon != 'none' &&
                          _teksDiskonCtrl.text.isNotEmpty)
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
                              _teksDiskonCtrl.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                  : const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: _AC.primary,
                    ),
                  ),
        ),

        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _judulCtrl.text.trim().isEmpty
                          ? 'Judul Banner'
                          : _judulCtrl.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF1E3A5F),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_subCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _subCtrl.text,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),

                if (_selectedLayanan != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_tipeDiskon != 'none') ...[
                        Text(
                          formatRupiah(_selectedLayanan!.hargaFix),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatRupiah(_hitungHargaDiskon()),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.green,
                              ),
                            ),
                            if (_kodePromoCtrl.text.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
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
                                      _kodePromoCtrl.text,
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
                        ),
                      ] else
                        Text(
                          formatRupiah(_selectedLayanan!.hargaFix),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _AC.primary,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStandardPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPreviewBg(),
        if (_hasGambar)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(.55), Colors.transparent],
              ),
            ),
          ),
        if (_hasGambar &&
            _tipeDiskon != 'none' &&
            _teksDiskonCtrl.text.isNotEmpty)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
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
                    _teksDiskonCtrl.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_hasGambar && _tipeCard == 'landscape')
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _judulCtrl.text.trim().isEmpty
                      ? 'Banner Tanpa Judul'
                      : _judulCtrl.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_subCtrl.text.isNotEmpty)
                  Text(
                    _subCtrl.text,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_camera, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _hasGambar ? 'Ganti' : 'Pilih Foto',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AC.bg,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Banner' : 'Tambah Banner',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _AC.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _loadingLayanan
              ? const Center(
                child: CircularProgressIndicator(color: _AC.primary),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          const Icon(
                            Icons.medical_services,
                            color: _AC.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Link ke Layanan (Opsional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _showLayananSearchDialog(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child:
                                    _selectedLayanan == null
                                        ? Text(
                                          'Pilih layanan (opsional)',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        )
                                        : Row(
                                          children: [
                                            if (_selectedLayanan!.gambarUrl !=
                                                null)
                                              AppCachedImage(
                                                imageUrl: _selectedLayanan!.gambarUrl,
                                                width: 40,
                                                height: 40,
                                                borderRadius: BorderRadius.circular(6),
                                                fit: BoxFit.cover,
                                                errorWidget: const Icon(Icons.image, size: 40),
                                              )
                                            else
                                              const Icon(
                                                Icons.medical_services,
                                                size: 40,
                                                color: _AC.primary,
                                              ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _selectedLayanan!
                                                        .namaLayanan,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    formatRupiah(
                                                      _selectedLayanan!
                                                          .hargaFix,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_selectedLayanan != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _AC.primary.withOpacity(.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _AC.light,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.link,
                                          size: 12,
                                          color: _AC.primary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Banner terkait layanan ini',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _AC.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap:
                                        () => setState(
                                          () => _selectedLayanan = null,
                                        ),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (_selectedLayanan!.gambarUrl != null)
                                    AppCachedImage(
                                      imageUrl: _selectedLayanan!.gambarUrl,
                                      width: 60,
                                      height: 60,
                                      borderRadius: BorderRadius.circular(10),
                                      fit: BoxFit.cover,
                                      errorWidget: const Icon(Icons.image, size: 60),
                                    )
                                  else
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: _AC.light,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.medical_services,
                                        size: 30,
                                        color: _AC.primary,
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedLayanan!.namaLayanan,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: Color(0xFF1E3A5F),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        if (_tipeDiskon != 'none') ...[
                                          Text(
                                            formatRupiah(
                                              _selectedLayanan!.hargaFix,
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatRupiah(_hitungHargaDiskon()),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ] else
                                          Text(
                                            formatRupiah(
                                              _selectedLayanan!.hargaFix,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: _AC.primary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      const Divider(thickness: 1),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(
                            Icons.dashboard_customize,
                            color: _AC.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Tipe Tampilan Card',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [

                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  () => setState(() => _tipeCard = 'landscape'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color:
                                      _tipeCard == 'landscape'
                                          ? _AC.light
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        _tipeCard == 'landscape'
                                            ? _AC.primary
                                            : Colors.grey.shade300,
                                    width: _tipeCard == 'landscape' ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color:
                                            _tipeCard == 'landscape'
                                                ? _AC.primary.withOpacity(.2)
                                                : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.view_day_outlined,
                                          color:
                                              _tipeCard == 'landscape'
                                                  ? _AC.primary
                                                  : Colors.grey,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Landscape',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color:
                                            _tipeCard == 'landscape'
                                                ? _AC.primary
                                                : Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '5:2',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    if (_tipeCard == 'landscape') ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _AC.primary,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          '✓',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _tipeCard = 'square'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color:
                                      _tipeCard == 'square'
                                          ? _AC.light
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        _tipeCard == 'square'
                                            ? _AC.primary
                                            : Colors.grey.shade300,
                                    width: _tipeCard == 'square' ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color:
                                            _tipeCard == 'square'
                                                ? _AC.primary.withOpacity(.2)
                                                : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.grid_view_rounded,
                                          color:
                                              _tipeCard == 'square'
                                                  ? _AC.primary
                                                  : Colors.grey,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Square',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color:
                                            _tipeCard == 'square'
                                                ? _AC.primary
                                                : Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '1:1',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    if (_tipeCard == 'square') ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _AC.primary,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          '✓',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: GestureDetector(
                              onTap:
                                  () =>
                                      setState(() => _tipeCard = 'full_width'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color:
                                      _tipeCard == 'full_width'
                                          ? _AC.light
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        _tipeCard == 'full_width'
                                            ? _AC.primary
                                            : Colors.grey.shade300,
                                    width: _tipeCard == 'full_width' ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color:
                                            _tipeCard == 'full_width'
                                                ? _AC.primary.withOpacity(.2)
                                                : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.view_carousel_outlined,
                                          color:
                                              _tipeCard == 'full_width'
                                                  ? _AC.primary
                                                  : Colors.grey,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Full Width',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color:
                                            _tipeCard == 'full_width'
                                                ? _AC.primary
                                                : Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'Horizontal',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    if (_tipeCard == 'full_width') ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _AC.primary,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          '✓',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tipeCard == 'landscape'
                            ? 'Landscape: ditampilkan penuh lebar di carousel utama'
                            : _tipeCard == 'square'
                            ? 'Square: ditampilkan dalam grid 2 kolom di halaman promo'
                            : 'Full Width: horizontal scroll di section "Promo Paket Layanan"',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[500],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(thickness: 1),
                      const SizedBox(height: 16),

                      _label('Gambar Banner'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pilihGambar,
                        child: Center(
                          child: Container(
                            height:
                                _tipeCard == 'full_width'
                                    ? 140
                                    : (_tipeCard == 'square' ? 220 : 180),
                            width:
                                _tipeCard == 'full_width'
                                    ? double.infinity
                                    : (_tipeCard == 'square'
                                        ? 220
                                        : double.infinity),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _AC.primary.withOpacity(.3),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child:
                                  _tipeCard == 'full_width'
                                      ? _buildFullWidthPreview()
                                      : _buildStandardPreview(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tipeCard == 'landscape'
                            ? 'Rasio 5:2 (800×320px) • JPG/PNG/WEBP • maks 3MB'
                            : _tipeCard == 'square'
                            ? 'Rasio 1:1 (600×600px) • JPG/PNG/WEBP • maks 3MB'
                            : 'Horizontal card (320×140px) • JPG/PNG/WEBP • maks 3MB',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[500],
                        ),
                      ),

                      const SizedBox(height: 22),

                      _label('Judul (Opsional)'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _judulCtrl,
                        hint: 'contoh: Home Nursing 24/7 (opsional)',
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 16),

                      _label('Subtitle (Opsional)'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _subCtrl,
                        hint: 'contoh: Diskon 20% pengguna baru (opsional)',
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 16),

                      _label('Urutan Tampil'),
                      const SizedBox(height: 8),
                      _field(
                        controller: _urutanCtrl,
                        hint: '0',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v != null &&
                              v.isNotEmpty &&
                              int.tryParse(v) == null)
                            return 'Harus angka';
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),
                      const Divider(thickness: 1),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(
                            Icons.local_offer,
                            color: _AC.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Pengaturan Diskon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _label('Tipe Diskon'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<String>(
                              title: const Text('Tidak Ada Diskon'),
                              subtitle: const Text(
                                'Banner biasa tanpa promo',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: 'none',
                              groupValue: _tipeDiskon,
                              activeColor: _AC.primary,
                              onChanged:
                                  (v) => setState(() {
                                    _tipeDiskon = v!;
                                    _nilaiDiskonCtrl.clear();
                                    _maxDiskonCtrl.clear();
                                    _minTransaksiCtrl.clear();
                                    _teksDiskonCtrl.clear();
                                  }),
                            ),
                            const Divider(height: 1),
                            RadioListTile<String>(
                              title: const Text('Diskon Nominal'),
                              subtitle: const Text(
                                'Potongan dalam rupiah (Rp 50.000)',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: 'nominal',
                              groupValue: _tipeDiskon,
                              activeColor: _AC.primary,
                              onChanged:
                                  (v) => setState(() => _tipeDiskon = v!),
                            ),
                            const Divider(height: 1),
                            RadioListTile<String>(
                              title: const Text('Diskon Persentase'),
                              subtitle: const Text(
                                'Potongan dalam persen (20%)',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: 'persen',
                              groupValue: _tipeDiskon,
                              activeColor: _AC.primary,
                              onChanged:
                                  (v) => setState(() => _tipeDiskon = v!),
                            ),
                          ],
                        ),
                      ),

                      if (_tipeDiskon != 'none') ...[
                        const SizedBox(height: 16),
                        _label(
                          _tipeDiskon == 'nominal'
                              ? 'Nilai Diskon (Rupiah) *'
                              : 'Nilai Diskon (Persen) *',
                        ),
                        const SizedBox(height: 8),
                        _field(
                          controller: _nilaiDiskonCtrl,
                          hint: _tipeDiskon == 'nominal' ? 'Rp 50.000' : '20',
                          keyboardType: TextInputType.number,
                          inputFormatters:
                              _tipeDiskon == 'nominal'
                                  ? [CurrencyFormatter()]
                                  : [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Nilai diskon wajib diisi';
                            if (_tipeDiskon == 'nominal') {
                              if (parseRupiah(v) == 0)
                                return 'Nilai harus lebih dari 0';
                            } else {
                              if (double.tryParse(v) == null)
                                return 'Harus angka';
                            }
                            return null;
                          },
                        ),
                        Text(
                          _tipeDiskon == 'nominal'
                              ? 'Format otomatis: Rp 50.000'
                              : 'Contoh: 20 untuk diskon 20%',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey[500],
                          ),
                        ),

                        if (_tipeDiskon == 'persen') ...[
                          const SizedBox(height: 16),
                          _label('Maksimal Diskon (Rupiah - Opsional)'),
                          const SizedBox(height: 8),
                          _field(
                            controller: _maxDiskonCtrl,
                            hint: 'Rp 100.000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyFormatter()],
                            onChanged: (_) => setState(() {}),
                          ),
                          Text(
                            'Format otomatis: Rp 100.000 untuk maksimal potongan',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        _label('Teks Diskon (ditampilkan di banner) *'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _teksDiskonCtrl,
                          hint: 'Diskon 20% atau Hemat Rp 50.000',
                          onChanged: (_) => setState(() {}),
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Teks diskon wajib diisi'
                                      : null,
                        ),

                        const SizedBox(height: 16),
                        _label('Kode Promo/Voucher (Opsional)'),
                        const SizedBox(height: 8),
                        _field(controller: _kodePromoCtrl, hint: 'HEMAT20'),
                        Text(
                          'Kode yang bisa diinput user saat checkout',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey[500],
                          ),
                        ),

                        const SizedBox(height: 16),
                        _label('Minimal Transaksi (Rupiah)'),
                        const SizedBox(height: 8),
                        _field(
                          controller: _minTransaksiCtrl,
                          hint: 'Rp 500.000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyFormatter()],
                        ),
                        Text(
                          'Kosongkan atau Rp 0 jika tidak ada minimal transaksi',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      const Divider(thickness: 1),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Status Banner',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            _aktif
                                ? 'Ditampilkan di halaman pasien'
                                : 'Disembunyikan dari pasien',
                            style: TextStyle(
                              color: _aktif ? _AC.primary : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          value: _aktif,
                          activeColor: _AC.primary,
                          onChanged: (v) => setState(() => _aktif = v),
                        ),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _simpan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _AC.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _loading
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    _isEdit
                                        ? 'Simpan Perubahan'
                                        : 'Tambah Banner',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      color: Color(0xFF1E3A5F),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _AC.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}

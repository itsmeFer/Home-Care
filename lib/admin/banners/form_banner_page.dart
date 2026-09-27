import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:home_care/admin/banners/widgets/banner_discount_section.dart';
import 'package:home_care/admin/banners/widgets/banner_form_content_section.dart';
import 'package:home_care/admin/banners/widgets/banner_form_layanan_section.dart';
import 'package:home_care/admin/banners/widgets/banner_form_status_section.dart';
import 'package:home_care/admin/banners/widgets/banner_layanan_picker_dialog.dart';
import 'package:home_care/admin/banners/widgets/banner_live_preview.dart';
import 'package:home_care/admin/banners/widgets/banner_type_selector.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_image_compressor.dart';
import 'package:home_care/features/banners/data/banner_service.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';

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
  bool _loadingLayanan = true;
  String _tipeCard = 'landscape';
  String _tipeDiskon = 'none';

  XFile? _xfile;
  Uint8List? _webBytes;

  List<LayananModel> _layananList = [];
  LayananModel? _selectedLayanan;

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
        _nilaiDiskonCtrl.text = _tipeDiskon == 'nominal'
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

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Sumber Foto Banner',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pilihGambar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pilihGambar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pilihGambar(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = await AppImageCompressor.compressXFile(
      picked,
      maxDimension: 1200,
      quality: 80,
    );

    setState(() {
      _xfile = picked;
      _webBytes = bytes;
    });
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
      final judul = _judulCtrl.text.trim().isEmpty ? null : _judulCtrl.text.trim();
      final sub = _subCtrl.text.trim().isEmpty ? null : _subCtrl.text.trim();
      final kode = _kodePromoCtrl.text.trim().isEmpty ? null : _kodePromoCtrl.text.trim();
      final teks = _teksDiskonCtrl.text.trim().isEmpty ? null : _teksDiskonCtrl.text.trim();

      double nilaiDiskon = 0;
      if (_tipeDiskon == 'nominal') {
        nilaiDiskon = parseRupiah(_nilaiDiskonCtrl.text);
      } else if (_tipeDiskon == 'persen') {
        nilaiDiskon = double.tryParse(_nilaiDiskonCtrl.text) ?? 0;
      }

      final maxDiskon = _maxDiskonCtrl.text.isEmpty ? null : parseRupiah(_maxDiskonCtrl.text);
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
        content: Text(msg.replaceAll('Exception: ', '')),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Banner' : 'Tambah Banner',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loadingLayanan
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BannerLivePreview(
                      tipeCard: _tipeCard,
                      judul: _judulCtrl.text,
                      subtitle: _subCtrl.text,
                      tipeDiskon: _tipeDiskon,
                      teksDiskon: _teksDiskonCtrl.text,
                      kodePromo: _kodePromoCtrl.text,
                      selectedLayanan: _selectedLayanan,
                      hargaDiskon: _hitungHargaDiskon(),
                      webBytes: _webBytes,
                      existingImageUrl: widget.banner?.gambarUrl,
                      onPickImage: _showImagePickerSheet,
                    ),
                    const SizedBox(height: 24),
                    BannerFormLayananSection(
                      selectedLayanan: _selectedLayanan,
                      onTap: () async {
                        final result = await BannerLayananPickerDialog.show(
                          context: context,
                          layananList: _layananList,
                          currentSelected: _selectedLayanan,
                        );
                        setState(() => _selectedLayanan = result);
                      },
                    ),
                    const SizedBox(height: 24),
                    BannerTypeSelector(
                      selectedType: _tipeCard,
                      onChanged: (type) => setState(() => _tipeCard = type),
                    ),
                    const SizedBox(height: 24),
                    BannerFormContentSection(
                      judulCtrl: _judulCtrl,
                      subCtrl: _subCtrl,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    BannerDiscountSection(
                      tipeDiskon: _tipeDiskon,
                      onTipeDiskonChanged: (v) => setState(() => _tipeDiskon = v),
                      nilaiDiskonCtrl: _nilaiDiskonCtrl,
                      maxDiskonCtrl: _maxDiskonCtrl,
                      teksDiskonCtrl: _teksDiskonCtrl,
                      kodePromoCtrl: _kodePromoCtrl,
                      minTransaksiCtrl: _minTransaksiCtrl,
                      selectedLayanan: _selectedLayanan,
                      onDataChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    BannerFormStatusSection(
                      urutanCtrl: _urutanCtrl,
                      aktif: _aktif,
                      onAktifChanged: (v) => setState(() => _aktif = v),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _simpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _isEdit ? 'Simpan Perubahan' : 'Tambah Banner',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── KONSTANTA ────────────────────────────────────────────────────────────────
class _Cfg {
  static const String baseUrl = 'http://192.168.1.5:8000/api';
  static const String bannerUrl = '$baseUrl/admin/banners';
  static const String layananUrl = '$baseUrl/admin/layanan-list';
  static const String tokenKey = 'auth_token';
}

// ─── WARNA ─────────────────────────────────────────────────────────────────
class _AC {
  static const primary = Color(0xFF0BA5A7);
  static const light = Color(0xFFE6FAFA);
  static const bg = Color(0xFFF5F7FA);
}

// ─── HELPER ────────────────────────────────────────────────────────────────
Future<http.MultipartFile> _toMultipart(String field, XFile xfile) async {
  final bytes = await xfile.readAsBytes();
  final ext = xfile.name.split('.').last.toLowerCase();
  return http.MultipartFile.fromBytes(
    field,
    bytes,
    filename: xfile.name,
    contentType: MediaType('image', ext),
  );
}

// ─── CURRENCY FORMATTER ───────────────────────────────────────────────────
class CurrencyFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    int value = int.parse(digitsOnly);
    String formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

double parseRupiah(String text) {
  if (text.isEmpty) return 0;
  String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
  return double.tryParse(digitsOnly) ?? 0;
}

String formatRupiah(double value) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(value);
}

// =========================
// MODEL LAYANAN
// =========================
class LayananModel {
  final int id;
  final String kodeLayanan;
  final String namaLayanan;
  final double hargaFix;
  final String? kategori;
  final String? gambarUrl;

  LayananModel({
    required this.id,
    required this.kodeLayanan,
    required this.namaLayanan,
    required this.hargaFix,
    this.kategori,
    this.gambarUrl,
  });

  factory LayananModel.fromJson(Map<String, dynamic> j) {
    return LayananModel(
      id: j['id'],
      kodeLayanan: j['kode_layanan'] ?? '',
      namaLayanan: j['nama_layanan'] ?? '',
      hargaFix: _safeDouble(j['harga_fix']),
      kategori: j['kategori'],
      gambarUrl: j['gambar_url'],
    );
  }

  static double _safeDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

// =========================
// MODEL BANNER
// =========================
class BannerModel {
  final int id;
  final int? layananId;
  final String? judul;
  final String? subtitle;
  final String? gambarUrl;
  final int urutan;
  final bool aktif;
  final String tipeCard;
  final String tipeDiskon;
  final double nilaiDiskon;
  final double? maxDiskon;
  final String? kodePromo;
  final double minTransaksi;
  final String? teksDiskon;
  final Map<String, dynamic>? layanan;

  BannerModel({
    required this.id,
    this.layananId,
    this.judul,
    this.subtitle,
    this.gambarUrl,
    required this.urutan,
    required this.aktif,
    this.tipeCard = 'landscape',
    this.tipeDiskon = 'none',
    this.nilaiDiskon = 0,
    this.maxDiskon,
    this.kodePromo,
    this.minTransaksi = 0,
    this.teksDiskon,
    this.layanan,
  });

  factory BannerModel.fromJson(Map<String, dynamic> j) {
    return BannerModel(
      id: j['id'],
      layananId: j['layanan_id'],
      judul: j['judul'],
      subtitle: j['subtitle'],
      gambarUrl: j['gambar_url'],
      urutan: j['urutan'] ?? 0,
      aktif: j['aktif'] ?? false,
      tipeCard: j['tipe_card'] ?? 'landscape',
      tipeDiskon: j['tipe_diskon'] ?? 'none',
      nilaiDiskon: _safeDouble(j['nilai_diskon']),
      maxDiskon: j['max_diskon'] != null ? _safeDouble(j['max_diskon']) : null,
      kodePromo: j['kode_promo'],
      minTransaksi: _safeDouble(j['min_transaksi']),
      teksDiskon: j['teks_diskon'],
      layanan: j['layanan'],
    );
  }

  static double _safeDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

// =========================
// SERVICE
// =========================
class BannerService {
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_Cfg.tokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final t = await _token();
    return {'Accept': 'application/json', 'Authorization': 'Bearer $t'};
  }

  static Future<List<LayananModel>> getLayananList() async {
    final res = await http.get(
      Uri.parse(_Cfg.layananUrl),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return (json.decode(res.body)['data'] as List)
          .map((e) => LayananModel.fromJson(e))
          .toList();
    }
    throw Exception('Gagal memuat layanan');
  }

  static Future<List<BannerModel>> getAll() async {
    final res = await http.get(
      Uri.parse(_Cfg.bannerUrl),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return (json.decode(res.body)['data'] as List)
          .map((e) => BannerModel.fromJson(e))
          .toList();
    }
    throw Exception('Gagal memuat banner');
  }

  static Future<void> create({
    int? layananId,
    String? judul,
    String? subtitle,
    int urutan = 0,
    bool aktif = true,
    XFile? gambar,
    String tipeCard = 'landscape',
    String tipeDiskon = 'none',
    double nilaiDiskon = 0,
    double? maxDiskon,
    String? kodePromo,
    double minTransaksi = 0,
    String? teksDiskon,
  }) async {
    final token = await _token();
    final req = http.MultipartRequest('POST', Uri.parse(_Cfg.bannerUrl));
    req.headers['Authorization'] = 'Bearer $token';
    req.headers['Accept'] = 'application/json';

    if (layananId != null) req.fields['layanan_id'] = layananId.toString();
    if (judul != null && judul.trim().isNotEmpty) {
      req.fields['judul'] = judul.trim();
    }

    req.fields['urutan'] = urutan.toString();
    req.fields['aktif'] = aktif ? '1' : '0';
    req.fields['tipe_card'] = tipeCard;
    req.fields['tipe_diskon'] = tipeDiskon;
    req.fields['nilai_diskon'] = nilaiDiskon.toString();
    req.fields['min_transaksi'] = minTransaksi.toString();

    if (subtitle != null && subtitle.isNotEmpty)
      req.fields['subtitle'] = subtitle;
    if (maxDiskon != null) req.fields['max_diskon'] = maxDiskon.toString();
    if (kodePromo != null && kodePromo.isNotEmpty)
      req.fields['kode_promo'] = kodePromo;
    if (teksDiskon != null && teksDiskon.isNotEmpty)
      req.fields['teks_diskon'] = teksDiskon;
    if (gambar != null) req.files.add(await _toMultipart('gambar', gambar));

    final res = await req.send();
    if (res.statusCode != 201) throw Exception('Gagal membuat banner');
  }

  static Future<void> update({
    required int id,
    int? layananId,
    String? judul,
    String? subtitle,
    int? urutan,
    bool? aktif,
    String? tipeCard,
    String? tipeDiskon,
    double? nilaiDiskon,
    double? maxDiskon,
    String? kodePromo,
    double? minTransaksi,
    String? teksDiskon,
  }) async {
    final body = <String, dynamic>{};

    if (layananId != null) body['layanan_id'] = layananId;
    if (judul != null) body['judul'] = judul;
    if (subtitle != null) body['subtitle'] = subtitle;
    if (urutan != null) body['urutan'] = urutan;
    if (aktif != null) body['aktif'] = aktif;
    if (tipeCard != null) body['tipe_card'] = tipeCard;
    if (tipeDiskon != null) body['tipe_diskon'] = tipeDiskon;
    if (nilaiDiskon != null) body['nilai_diskon'] = nilaiDiskon;
    if (maxDiskon != null) body['max_diskon'] = maxDiskon;
    if (kodePromo != null) body['kode_promo'] = kodePromo;
    if (minTransaksi != null) body['min_transaksi'] = minTransaksi;
    if (teksDiskon != null) body['teks_diskon'] = teksDiskon;

    final res = await http.put(
      Uri.parse('${_Cfg.bannerUrl}/$id'),
      headers: {...(await _headers()), 'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (res.statusCode != 200) throw Exception('Gagal update banner');
  }

  static Future<void> uploadGambar({
    required int id,
    required XFile gambar,
  }) async {
    final token = await _token();
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${_Cfg.bannerUrl}/$id/gambar'),
    );
    req.headers['Authorization'] = 'Bearer $token';
    req.headers['Accept'] = 'application/json';
    req.files.add(await _toMultipart('gambar', gambar));
    final res = await req.send();
    if (res.statusCode != 200) throw Exception('Gagal upload gambar');
  }

  static Future<void> toggle(int id) async {
    final res = await http.patch(
      Uri.parse('${_Cfg.bannerUrl}/$id/toggle'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception('Gagal toggle banner');
  }

  static Future<void> delete(int id) async {
    final res = await http.delete(
      Uri.parse('${_Cfg.bannerUrl}/$id'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) throw Exception('Gagal hapus banner');
  }
}

// =========================
// HALAMAN CRUD BANNER
// =========================
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
    final fullWidth = _banners.where((b) => b.tipeCard == 'full_width').toList();

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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _AC.primary))
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
                  child: b.gambarUrl != null
                      ? Image.network(
                          b.gambarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(160),
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
                      ? Image.network(
                          b.gambarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(null),
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

  // ✅ FULL WIDTH CARD (HORIZONTAL LAYOUT)
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
              // GAMBAR KIRI
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
                      child: b.gambarUrl != null
                          ? Image.network(
                              b.gambarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(140),
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

              // INFO KANAN
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
                                color: b.aktif
                                    ? _AC.light
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: b.aktif
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

// =========================
// FORM TAMBAH / EDIT BANNER
// =========================
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
      imageQuality: 85,
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
                  filteredList = _layananList.where((l) {
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
                        suffixIcon: searchCtrl.text.isNotEmpty
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
                      tileColor: _selectedLayanan == null
                          ? _AC.light
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _selectedLayanan == null
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
                      child: filteredList.isEmpty
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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final l = filteredList[i];
                                final isSelected = _selectedLayanan?.id == l.id;

                                return ListTile(
                                  leading: l.gambarUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            l.gambarUrl!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                              Icons.image,
                                              size: 50,
                                            ),
                                          ),
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
                                      fontWeight: isSelected
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
                                  tileColor: isSelected
                                      ? _AC.light
                                      : Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected
                                          ? _AC.primary
                                          : Colors.grey.shade200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  trailing: isSelected
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
          _kodePromoCtrl.text.trim().isEmpty ? null : _kodePromoCtrl.text.trim();
      final teks = _teksDiskonCtrl.text.trim().isEmpty
          ? null
          : _teksDiskonCtrl.text.trim();

      double nilaiDiskon = 0;
      if (_tipeDiskon == 'nominal') {
        nilaiDiskon = parseRupiah(_nilaiDiskonCtrl.text);
      } else if (_tipeDiskon == 'persen') {
        nilaiDiskon = double.tryParse(_nilaiDiskonCtrl.text) ?? 0;
      }

      final maxDiskon = _maxDiskonCtrl.text.isEmpty
          ? null
          : parseRupiah(_maxDiskonCtrl.text);
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
      return Image.network(
        widget.banner!.gambarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _emptyPreview(),
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

  // ✅ PREVIEW FULL WIDTH (HORIZONTAL LAYOUT)
  Widget _buildFullWidthPreview() {
    return Row(
      children: [
        // GAMBAR KIRI (140x140 = kotak)
        Container(
          width: 140,
          height: 140,
          color: _AC.light,
          child: _hasGambar
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    _hasGambarBaru
                        ? Image.memory(_webBytes!, fit: BoxFit.cover)
                        : Image.network(
                            widget.banner!.gambarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _emptyPreview(),
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

        // INFO KANAN
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // JUDUL & SUBTITLE
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
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),

                // HARGA & PROMO
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

  // ✅ PREVIEW STANDARD (LANDSCAPE & SQUARE)
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
                colors: [
                  Colors.black.withOpacity(.55),
                  Colors.transparent,
                ],
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
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
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
                    size: 12,
                    color: Colors.white,
                  ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.photo_camera,
                  size: 13,
                  color: Colors.white,
                ),
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
      body: _loadingLayanan
          ? const Center(child: CircularProgressIndicator(color: _AC.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PILIH LAYANAN
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
                              child: _selectedLayanan == null
                                  ? Text(
                                      'Pilih layanan (opsional)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        if (_selectedLayanan!.gambarUrl != null)
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Image.network(
                                              _selectedLayanan!.gambarUrl!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.image,
                                                size: 40,
                                              ),
                                            ),
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
                                                _selectedLayanan!.namaLayanan,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                formatRupiah(
                                                  _selectedLayanan!.hargaFix,
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
                                  onTap: () =>
                                      setState(() => _selectedLayanan = null),
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      _selectedLayanan!.gambarUrl!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image, size: 60),
                                    ),
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

                    // TIPE CARD (3 PILIHAN)
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
                        // LANDSCAPE
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _tipeCard = 'landscape'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _tipeCard == 'landscape'
                                    ? _AC.light
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _tipeCard == 'landscape'
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
                                      color: _tipeCard == 'landscape'
                                          ? _AC.primary.withOpacity(.2)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.view_day_outlined,
                                        color: _tipeCard == 'landscape'
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
                                      color: _tipeCard == 'landscape'
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
                                        borderRadius: BorderRadius.circular(20),
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

                        // SQUARE
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tipeCard = 'square'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _tipeCard == 'square'
                                    ? _AC.light
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _tipeCard == 'square'
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
                                      color: _tipeCard == 'square'
                                          ? _AC.primary.withOpacity(.2)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.grid_view_rounded,
                                        color: _tipeCard == 'square'
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
                                      color: _tipeCard == 'square'
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
                                        borderRadius: BorderRadius.circular(20),
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

                        // FULL WIDTH
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _tipeCard = 'full_width'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _tipeCard == 'full_width'
                                    ? _AC.light
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _tipeCard == 'full_width'
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
                                      color: _tipeCard == 'full_width'
                                          ? _AC.primary.withOpacity(.2)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.view_carousel_outlined,
                                        color: _tipeCard == 'full_width'
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
                                      color: _tipeCard == 'full_width'
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
                                        borderRadius: BorderRadius.circular(20),
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

                    // PREVIEW GAMBAR
                    _label('Gambar Banner'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pilihGambar,
                      child: Center(
                        child: Container(
                          height: _tipeCard == 'full_width'
                              ? 140
                              : (_tipeCard == 'square' ? 220 : 180),
                          width: _tipeCard == 'full_width'
                              ? double.infinity
                              : (_tipeCard == 'square' ? 220 : double.infinity),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _AC.primary.withOpacity(.3),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: _tipeCard == 'full_width'
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

                    // JUDUL
                    _label('Judul (Opsional)'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _judulCtrl,
                      hint: 'contoh: Home Nursing 24/7 (opsional)',
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // SUBTITLE
                    _label('Subtitle (Opsional)'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _subCtrl,
                      hint: 'contoh: Diskon 20% pengguna baru (opsional)',
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // URUTAN
                    _label('Urutan Tampil'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _urutanCtrl,
                      hint: '0',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null &&
                            v.isNotEmpty &&
                            int.tryParse(v) == null) return 'Harus angka';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),

                    // SECTION DISKON
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
                            onChanged: (v) => setState(() {
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
                            onChanged: (v) => setState(() => _tipeDiskon = v!),
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
                            onChanged: (v) => setState(() => _tipeDiskon = v!),
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
                        inputFormatters: _tipeDiskon == 'nominal'
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
                        validator: (v) => v == null || v.trim().isEmpty
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

                    // TOGGLE AKTIF
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

                    // BUTTON SIMPAN
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
                        child: _loading
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
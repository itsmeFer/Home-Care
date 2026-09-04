import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';
import 'package:home_care/utils/app_image_compressor.dart';

class BannerService {
  BannerService._();

  static Future<http.MultipartFile> toMultipart(String field, XFile xfile) async {
    final bytes = await AppImageCompressor.compressXFile(
      xfile,
      maxDimension: 1200,
      quality: 78,
    );
    final filename = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    );
  }

  static Future<List<LayananModel>> getLayananList() async {
    final res = await ApiClient.get(ApiConstants.adminLayanan);
    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .map((e) => LayananModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    throw Exception('Gagal memuat layanan');
  }

  static Future<List<BannerModel>> getAll() async {
    final res = await ApiClient.get(ApiConstants.adminBanners);
    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .map((e) => BannerModel.fromJson(Map<String, dynamic>.from(e as Map)))
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
    final req = http.MultipartRequest('POST', Uri.parse(ApiConstants.adminBanners));

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

    if (subtitle != null && subtitle.isNotEmpty) {
      req.fields['subtitle'] = subtitle;
    }
    if (maxDiskon != null) req.fields['max_diskon'] = maxDiskon.toString();
    if (kodePromo != null && kodePromo.isNotEmpty) {
      req.fields['kode_promo'] = kodePromo;
    }
    if (teksDiskon != null && teksDiskon.isNotEmpty) {
      req.fields['teks_diskon'] = teksDiskon;
    }
    if (gambar != null) req.files.add(await toMultipart('gambar', gambar));

    await ApiClient.sendMultipart(req);
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

    await ApiClient.put('${ApiConstants.adminBanners}/$id', body: body);
  }

  static Future<void> uploadGambar({
    required int id,
    required XFile gambar,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.adminBanners}/$id/gambar'),
    );
    req.files.add(await toMultipart('gambar', gambar));
    await ApiClient.sendMultipart(req);
  }

  static Future<void> toggle(int id) async {
    await ApiClient.post('${ApiConstants.adminBanners}/$id/toggle');
  }

  static Future<void> delete(int id) async {
    await ApiClient.delete('${ApiConstants.adminBanners}/$id');
  }
}

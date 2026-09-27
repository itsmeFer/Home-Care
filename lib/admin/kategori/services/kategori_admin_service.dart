import 'dart:typed_data';
import 'package:home_care/admin/kategori/models/kategori_layanan_model.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:http/http.dart' as http;

class KategoriAdminService {
  /// Mengambil daftar kategori layanan dengan opsional pencarian dan filter aktif.
  static Future<List<KategoriLayanan>> fetchKategori({
    String? search,
    bool? aktif,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (aktif != null) {
      queryParams['aktif'] = aktif.toString();
    }

    final url = queryParams.isEmpty
        ? ApiConstants.adminKategoriLayanan
        : '${ApiConstants.adminKategoriLayanan}?${Uri(queryParameters: queryParams).query}';

    final res = await ApiClient.get(url);

    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .map((e) => KategoriLayanan.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (res is List) {
      return res
          .map((e) => KategoriLayanan.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Membuat kategori baru dan mengembalikan model data yang berhasil dibuat.
  static Future<KategoriLayanan> createKategori(Map<String, dynamic> payload) async {
    final res = await ApiClient.post(
      ApiConstants.adminKategoriLayanan,
      body: payload,
    );

    if (res is Map && res['data'] is Map) {
      return KategoriLayanan.fromJson(res['data'] as Map<String, dynamic>);
    }
    throw 'Gagal membuat kategori layanan';
  }

  /// Mengupdate data kategori dan mengembalikan data terbaru.
  static Future<KategoriLayanan> updateKategori(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final res = await ApiClient.put(
      ApiConstants.adminKategoriLayananDetail(id),
      body: payload,
    );

    if (res is Map && res['data'] is Map) {
      return KategoriLayanan.fromJson(res['data'] as Map<String, dynamic>);
    }
    throw 'Gagal memperbarui kategori layanan';
  }

  /// Mengubah status aktif / nonaktif kategori.
  static Future<void> toggleKategori(int id) async {
    await ApiClient.patch(ApiConstants.adminKategoriLayananToggle(id));
  }

  /// Menghapus kategori layanan berdasarkan ID.
  static Future<void> deleteKategori(int id) async {
    await ApiClient.delete(ApiConstants.adminKategoriLayananDetail(id));
  }

  /// Menghapus foto/gambar dari kategori layanan.
  static Future<void> deleteGambar(int id) async {
    await ApiClient.delete(ApiConstants.adminKategoriLayananGambar(id));
  }

  /// Mengunggah gambar kategori layanan (bytes terkompresi).
  static Future<void> uploadGambar({
    required int kategoriId,
    required Uint8List imageBytes,
    String? fileName,
  }) async {
    final url = ApiConstants.adminKategoriLayananGambar(kategoriId);
    final request = http.MultipartRequest('POST', Uri.parse(url));

    request.files.add(
      http.MultipartFile.fromBytes(
        'gambar',
        imageBytes,
        filename: fileName ?? 'kategori.jpg',
      ),
    );

    await ApiClient.sendMultipart(request);
  }

  /// Mengatur ulang prioritas urutan tampil kategori di aplikasi.
  static Future<void> aturUrutan(List<int> kategoriIds) async {
    final payload = kategoriIds.asMap().entries.map((e) {
      return {
        'id': e.value,
        'urutan': e.key,
      };
    }).toList();

    await ApiClient.patch(
      ApiConstants.adminKategoriLayananUrutan,
      body: {'urutan': payload},
    );
  }
}

import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class DetailLayananService {
  /// Mengambil daftar kategori layanan aktif
  static Future<List<KategoriLayananItem>> fetchKategori() async {
    final response = await ApiClient.get('/admin/kategori-layanan');
    if (response is Map) {
      final List data = (response['data'] as List?) ?? [];
      return data
          .map((e) => KategoriLayananItem.fromJson(e as Map<String, dynamic>))
          .where((e) => e.slug.trim().isNotEmpty)
          .toList();
    }
    return [];
  }

  /// Mengambil data detail satu layanan berdasarkan ID
  static Future<LayananDetail> fetchDetail(int layananId) async {
    final response = await ApiClient.get('/layanan/$layananId');
    if (response is Map && response['data'] != null) {
      return LayananDetail.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw 'Data layanan tidak ditemukan.';
  }

  /// Mengambil daftar koordinator yang bertugas pada layanan ini
  static Future<List<KoordinatorItem>> fetchKoordinatorLayanan(
    int layananId,
  ) async {
    final response = await ApiClient.get(
      '/admin/layanan/$layananId/koordinator',
    );
    if (response is Map) {
      final List data = (response['data'] as List?) ?? [];
      return data
          .map((e) => KoordinatorItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Mengambil daftar seluruh koordinator
  static Future<List<KoordinatorItem>> fetchAllKoordinator() async {
    final response = await ApiClient.get('/admin/koordinator');
    if (response is Map) {
      final List data = (response['data'] as List?) ?? [];
      return data
          .map((e) => KoordinatorItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Sinkronisasi relasi koordinator pada layanan
  static Future<void> syncKoordinator(
    int layananId,
    List<int> koordinatorIds,
  ) async {
    await ApiClient.put(
      '/admin/layanan/$layananId/koordinator',
      body: {'koordinator_ids': koordinatorIds},
    );
  }

  /// Mengupdate status aktif dan catatan penugasan koordinator
  static Future<void> updateKoordinatorPivot({
    required int layananId,
    required int koordinatorId,
    required bool aktif,
    String? catatan,
  }) async {
    await ApiClient.patch(
      '/admin/layanan/$layananId/koordinator/$koordinatorId',
      body: {'aktif': aktif, 'catatan': catatan},
    );
  }

  /// Mengupdate informasi layanan
  static Future<void> updateLayanan(
    int layananId,
    Map<String, dynamic> payload,
  ) async {
    await ApiClient.put('/layanan/$layananId', body: payload);
  }

  /// Menghapus layanan
  static Future<void> deleteLayanan(int layananId) async {
    await ApiClient.delete('/layanan/$layananId');
  }

  /// Mengupload gambar layanan yang terkompresi
  static Future<void> uploadGambarLayanan({
    required int layananId,
    required List<int> compressedBytes,
    required String filename,
  }) async {
    final uri = Uri.parse('${ApiConstants.apiBase}/layanan/$layananId/gambar');
    final request = http.MultipartRequest('POST', uri);
    final multipartFile = http.MultipartFile.fromBytes(
      'gambar',
      compressedBytes,
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(multipartFile);

    await ApiClient.sendMultipart(request);
  }
}

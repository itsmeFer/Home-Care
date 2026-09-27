import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

class LayananAdminService {
  /// Mengambil daftar seluruh kategori layanan aktif
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

  /// Mengambil daftar layanan dengan dukungan filter opsional
  static Future<List<Layanan>> fetchLayanan({
    String? search,
    String? kategori,
    bool? aktif,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (kategori != null && kategori.trim().isNotEmpty) {
      queryParams['kategori'] = kategori.trim();
    }
    if (aktif != null) {
      queryParams['aktif'] = aktif.toString();
    }

    final url = queryParams.isEmpty
        ? '/layanan'
        : '/layanan?${Uri(queryParameters: queryParams).query}';

    final response = await ApiClient.get(url);
    if (response is Map) {
      final List data = (response['data'] as List?) ?? [];
      return data
          .map((e) => Layanan.fromJson(e as Map<String, dynamic>))
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

  /// Membuat layanan baru
  static Future<void> createLayanan(Map<String, dynamic> payload) async {
    await ApiClient.post('/layanan', body: payload);
  }

  /// Mengupdate informasi layanan
  static Future<void> updateLayanan(
    int id,
    Map<String, dynamic> payload,
  ) async {
    await ApiClient.put('/layanan/$id', body: payload);
  }

  /// Menghapus layanan berdasarkan ID
  static Future<void> deleteLayanan(int id) async {
    await ApiClient.delete('/layanan/$id');
  }
}

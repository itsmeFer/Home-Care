import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

/// Repository untuk penanganan katalog layanan, kategori, addon, dan riwayat pencarian.
class ServiceRepository {
  const ServiceRepository();

  /// Mengambil daftar layanan (publik/admin) dengan opsional filter kategori, keyword, dan status aktif.
  Future<List<ServiceModel>> getServices({
    String? kategori,
    String? q,
    bool? aktif,
  }) async {
    final params = <String, dynamic>{};
    if (kategori != null && kategori.isNotEmpty) params['kategori'] = kategori;
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (aktif != null) params['aktif'] = aktif ? '1' : '0';

    final response = await ApiClient.get(
      ApiConstants.adminLayanan,
      queryParams: params.isNotEmpty ? params : null,
      requiresAuth: false,
    );

    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(ServiceModel.fromJson)
        .toList();
  }

  /// Mengambil detail satu layanan berdasarkan ID.
  Future<ServiceModel> getServiceDetail(int id) async {
    final response = await ApiClient.get(
      ApiConstants.adminLayananDetail(id),
      requiresAuth: false,
    );

    if (response is Map && response['data'] is Map) {
      return ServiceModel.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    } else if (response is Map) {
      return ServiceModel.fromJson(Map<String, dynamic>.from(response));
    }
    throw Exception('Format data layanan tidak valid');
  }

  /// Melakukan pencarian layanan berdasarkan kata kunci.
  Future<List<ServiceModel>> searchServices(String query) async {
    final response = await ApiClient.get(
      ApiConstants.layananSearch,
      queryParams: {'q': query.trim()},
      requiresAuth: false,
    );

    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(ServiceModel.fromJson)
        .toList();
  }

  /// Mengambil daftar kategori layanan aktif.
  Future<List<ServiceCategory>> getCategories() async {
    final response = await ApiClient.get(
      ApiConstants.kategoriLayananPublik,
      requiresAuth: false,
    );

    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(ServiceCategory.fromJson)
        .toList();
  }

  /// Mengambil daftar addon pendukung layanan tertentu atau seluruh addon admin.
  Future<List<Addon>> getAddons({int? layananId}) async {
    final url = layananId != null
        ? ApiConstants.pasienLayananAddons(layananId)
        : ApiConstants.adminAddons;

    final response = await ApiClient.get(url);
    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Addon.fromJson)
        .toList();
  }

  /// Mengambil riwayat layanan yang baru saja dilihat pasien.
  Future<List<ServiceModel>> getRecentViewedServices() async {
    final response = await ApiClient.get(ApiConstants.pasienRecentViewedLayanan);
    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) {
          if (e['layanan'] is Map) {
            return ServiceModel.fromJson(
              Map<String, dynamic>.from(e['layanan'] as Map),
            );
          }
          return ServiceModel.fromJson(e);
        })
        .toList();
  }

  /// Mencatat layanan yang baru dilihat oleh pasien ke backend.
  Future<void> recordRecentViewed(int layananId) async {
    try {
      await ApiClient.post(
        ApiConstants.pasienRecentViewedLayanan,
        body: {'layanan_id': layananId},
      );
    } catch (_) {
      // Background telemetry, tidak perlu melempar exception ke UI
    }
  }

  /// Mengambil riwayat keyword pencarian pasien.
  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    final response = await ApiClient.get(ApiConstants.pasienSearchHistory);
    final List data = _extractListData(response);
    return data.whereType<Map<String, dynamic>>().toList();
  }

  /// Menyimpan atau memperbarui data layanan (Admin).
  Future<ServiceModel> saveService(
    Map<String, dynamic> payload, {
    int? id,
  }) async {
    final dynamic response;
    if (id == null) {
      response = await ApiClient.post(
        ApiConstants.adminLayanan,
        body: payload,
      );
    } else {
      response = await ApiClient.put(
        ApiConstants.adminLayananDetail(id),
        body: payload,
      );
    }

    if (response is Map && response['data'] is Map) {
      return ServiceModel.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    }
    return ServiceModel.fromJson(payload);
  }

  /// Menghapus layanan (Admin).
  Future<void> deleteService(int id) async {
    await ApiClient.delete(ApiConstants.adminLayananDetail(id));
  }

  /// Mengaktifkan / menonaktifkan status layanan (Admin).
  Future<void> toggleService(int id, bool aktif) async {
    await ApiClient.put(
      ApiConstants.adminLayananDetail(id),
      body: {'aktif': aktif},
    );
  }

  static List _extractListData(dynamic response) {
    if (response == null) return [];
    if (response is List) return response;
    if (response is Map) {
      if (response['data'] is List) return response['data'] as List;
      if (response['data'] is Map && response['data']['data'] is List) {
        return response['data']['data'] as List;
      }
    }
    return [];
  }
}

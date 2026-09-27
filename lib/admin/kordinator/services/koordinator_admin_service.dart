import 'package:home_care/admin/kordinator/models/koordinator_admin_model.dart';
import 'package:home_care/core/network/api_client.dart';

class KoordinatorAdminService {
  /// Mengambil daftar akun koordinator dengan dukungan pencarian server-side.
  static Future<List<Koordinator>> fetchKoordinator({String? search}) async {
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final url = queryParams.isEmpty
        ? '/admin/koordinator'
        : '/admin/koordinator?${Uri(queryParameters: queryParams).query}';

    final res = await ApiClient.get(url);

    if (res is Map && res['data'] is List) {
      final List<dynamic> list = res['data'];
      return list
          .map((e) => Koordinator.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (res is List) {
      return res
          .map((e) => Koordinator.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Menambah akun koordinator baru dan mengembalikan model data terbaru.
  static Future<Koordinator> createKoordinator(
    Map<String, dynamic> payload,
  ) async {
    final res = await ApiClient.post(
      '/admin/koordinator',
      body: payload,
    );

    if (res is Map && res['data'] is Map) {
      return Koordinator.fromJson(res['data'] as Map<String, dynamic>);
    }
    throw 'Gagal menambah data koordinator';
  }

  /// Mengupdate data koordinator dan mengembalikan model data yang diperbarui.
  static Future<Koordinator> updateKoordinator(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final res = await ApiClient.put(
      '/admin/koordinator/$id',
      body: payload,
    );

    if (res is Map && res['data'] is Map) {
      return Koordinator.fromJson(res['data'] as Map<String, dynamic>);
    }
    throw 'Gagal memperbarui data koordinator';
  }

  /// Menghapus akun koordinator berdasarkan User ID.
  static Future<void> deleteKoordinator(int id) async {
    await ApiClient.delete('/admin/koordinator/$id');
  }
}

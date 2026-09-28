import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/nurses/domain/nurse_model.dart';

class KelolaPerawatService {
  static Future<List<Perawat>> fetchPerawat() async {
    final body = await ApiClient.get('/koordinator/perawat');
    if (body is Map && body['success'] == true && body['data'] != null) {
      final List<dynamic> data = body['data'];
      return data.map((e) => Perawat.fromJson(e)).toList();
    }
    throw (body is Map ? body['message'] : null) ?? 'Gagal mengambil data perawat';
  }

  static Future<void> ubahStatusVerifikasi(
    int perawatId,
    String status, {
    String? catatan,
  }) async {
    final bodyPayload = <String, dynamic>{
      'status_verifikasi': status,
      if (catatan != null && catatan.trim().isNotEmpty)
        'catatan_verifikasi': catatan.trim(),
    };
    await ApiClient.put('/koordinator/perawat/$perawatId/verifikasi', body: bodyPayload);
  }

  static Future<void> createPerawat(Map<String, dynamic> payload) async {
    await ApiClient.post('/koordinator/perawat', body: payload);
  }

  static Future<void> updatePerawat(int id, Map<String, dynamic> payload) async {
    await ApiClient.put('/koordinator/perawat/$id', body: payload);
  }

  static Future<void> deletePerawat(int id) async {
    await ApiClient.delete('/koordinator/perawat/$id');
  }

  static Future<void> updatePassword(int id, String password) async {
    await ApiClient.put('/koordinator/perawat/$id/password', body: {'password': password});
  }
}

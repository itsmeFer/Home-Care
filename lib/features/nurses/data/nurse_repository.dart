import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/nurses/domain/nurse_model.dart';

/// Repository untuk data perawat, profil, verifikasi, dan assignment tugas.
class NurseRepository {
  const NurseRepository();

  /// Mengambil profil perawat yang sedang login saat ini.
  Future<PerawatModel> getMyProfile() async {
    final response = await ApiClient.get(ApiConstants.perawatProfil);
    if (response is Map && response['data'] is Map) {
      return PerawatModel.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    } else if (response is Map) {
      return PerawatModel.fromJson(Map<String, dynamic>.from(response));
    }
    throw Exception('Data profil perawat tidak valid');
  }

  /// Mengambil daftar perawat (untuk Koordinator atau Admin).
  Future<List<PerawatModel>> getNurses({
    String? q,
    int? koordinatorId,
    String? statusVerifikasi,
    bool? aktif,
    bool isAdmin = false,
  }) async {
    final params = <String, dynamic>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (koordinatorId != null) {
      params['koordinator_id'] = koordinatorId.toString();
    }
    if (statusVerifikasi != null && statusVerifikasi.isNotEmpty) {
      params['status_verifikasi'] = statusVerifikasi;
    }
    if (aktif != null) params['aktif'] = aktif ? '1' : '0';

    final url = isAdmin ? ApiConstants.adminPerawat : ApiConstants.koordinatorPerawat;
    final response = await ApiClient.get(
      url,
      queryParams: params.isNotEmpty ? params : null,
    );

    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(PerawatModel.fromJson)
        .toList();
  }

  /// Mengambil detail profil dan dokumen satu perawat.
  Future<PerawatModel> getNurseDetail(
    int perawatId, {
    bool isAdmin = false,
  }) async {
    final url = isAdmin
        ? ApiConstants.adminPerawatDetail(perawatId)
        : ApiConstants.koordinatorPerawatDetail(perawatId);

    final response = await ApiClient.get(url);
    if (response is Map && response['data'] is Map) {
      return PerawatModel.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    } else if (response is Map) {
      return PerawatModel.fromJson(Map<String, dynamic>.from(response));
    }
    throw Exception('Detail perawat tidak ditemukan');
  }

  /// Menugaskan perawat ke pesanan layanan tertentu (Koordinator).
  Future<void> assignNurseToOrder({
    required int orderId,
    required int perawatId,
  }) async {
    await ApiClient.post(
      ApiConstants.koordinatorOrderAssign(orderId),
      body: {'perawat_id': perawatId},
    );
  }

  /// Mengatur koordinator yang membawahi perawat (Admin).
  Future<void> assignKoordinator({
    required int perawatId,
    required int koordinatorId,
  }) async {
    await ApiClient.post(
      ApiConstants.adminPerawatAssignKoordinator(perawatId),
      body: {'koordinator_id': koordinatorId},
    );
  }

  /// Memperbarui status verifikasi berkas perawat (verified / rejected / pending).
  Future<void> updateVerificationStatus({
    required int perawatId,
    required String status,
    String? catatan,
    bool isAdmin = false,
  }) async {
    final url = isAdmin
        ? ApiConstants.adminPerawatCrudVerifikasi(perawatId)
        : ApiConstants.koordinatorPerawatVerifikasi(perawatId);

    await ApiClient.post(
      url,
      body: {
        'status_verifikasi': status,
        if (catatan != null) 'catatan_verifikasi': catatan,
      },
    );
  }

  /// Mengambil ringkasan ulasan/rating kinerja perawat.
  Future<Map<String, dynamic>> getNurseRatingSummary(int perawatId) async {
    final response = await ApiClient.get(
      ApiConstants.koordinatorPerawatRatingSummary(perawatId),
    );
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      return response;
    }
    return {'avg_rating': 0.0, 'total_rating': 0};
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

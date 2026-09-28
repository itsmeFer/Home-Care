import 'package:home_care/admin/perawat/models/perawat_admin_models.dart';
import 'package:home_care/core/network/api_client.dart';

class PerawatAdminService {
  static Future<List<PerawatModel>> fetchPerawat({
    String? search,
    String? filterStatus,
    int? filterActive,
  }) async {
    final qp = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) {
      qp['search'] = search.trim();
    }

    final decoded = await ApiClient.get(
      '/admin/perawat',
      queryParams: qp.isNotEmpty ? qp : null,
    );

    if (decoded is! Map) {
      throw 'Format response perawat tidak sesuai.';
    }

    final raw = decoded['data'];
    final List<dynamic> dataList = raw is List ? raw : [];

    final items = dataList
        .map((e) => PerawatModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return items.where((x) {
      final statusOk =
          filterStatus == null || x.statusVerifikasi == filterStatus;
      final activeOk = filterActive == null
          ? true
          : (filterActive == 1 ? x.isActive : !x.isActive);
      return statusOk && activeOk;
    }).toList();
  }

  static Future<PerawatDetailModel> fetchPerawatDetail(int id) async {
    final decoded = await ApiClient.get('/admin/perawat/$id');

    if (decoded is! Map || decoded['data'] is! Map) {
      throw 'Format detail perawat tidak sesuai.';
    }

    final data = Map<String, dynamic>.from(decoded['data']);
    final perawatMap = data['perawat'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['perawat'])
        : <String, dynamic>{};

    final koorRaw = data['koordinator_options'];
    final List<KoordinatorItem> koorList = (koorRaw is List)
        ? koorRaw
            .map((e) =>
                KoordinatorItem.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id != 0)
            .toList()
        : [];

    return PerawatDetailModel(
      perawat: PerawatModel.fromJson(perawatMap),
      koordinatorOptions: koorList,
    );
  }

  static Future<int> savePerawat({
    required Map<String, dynamic> body,
    int? perawatId,
  }) async {
    final isEdit = perawatId != null;
    final url = isEdit
        ? '/admin/perawat-crud/$perawatId'
        : '/admin/perawat-crud';

    final decoded = isEdit
        ? await ApiClient.put(url, body: body)
        : await ApiClient.post(url, body: body);

    int targetPerawatId = perawatId ?? 0;
    try {
      if (decoded is Map && decoded['data'] is Map) {
        final data = Map<String, dynamic>.from(decoded['data']);
        final idRaw = data['id'];
        if (idRaw is int) {
          targetPerawatId = idRaw;
        } else {
          targetPerawatId = int.tryParse('$idRaw') ?? targetPerawatId;
        }
      }
    } catch (_) {}

    return targetPerawatId;
  }

  static Future<void> assignKoordinatorDirect({
    required int perawatId,
    required int? koordinatorId,
  }) async {
    await ApiClient.put(
      '/admin/perawat/$perawatId/assign-koordinator',
      body: {'koordinator_id': koordinatorId},
    );
  }

  static Future<void> deletePerawat(int id) async {
    await ApiClient.delete('/admin/perawat-crud/$id');
  }

  static Future<String> setPassword({
    required int perawatId,
    required String password,
  }) async {
    final decoded = await ApiClient.put(
      '/admin/perawat-crud/$perawatId/password',
      body: {'password': password},
    );

    String emailLogin = '-';
    try {
      if (decoded is Map && decoded['data'] is Map) {
        emailLogin = (decoded['data']['login_email'] ?? '-').toString();
      }
    } catch (_) {}

    return emailLogin;
  }

  static Future<void> updateVerifikasi({
    required int perawatId,
    required String status,
    String? note,
  }) async {
    await ApiClient.put(
      '/admin/perawat-crud/$perawatId/verifikasi',
      body: {
        'status_verifikasi': status,
        'catatan_verifikasi':
            note?.trim().isEmpty == true ? null : note?.trim(),
      },
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:home_care/admin/perawat/models/perawat_admin_models.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:http/http.dart' as http;

class PerawatAdminService {
  static const Duration _timeout = Duration(seconds: 15);

  static String get baseUrl => ApiConstants.apiBase;

  static Future<String> _requireToken() async {
    final token = await StorageService.getToken();
    if (token == null || token.trim().isEmpty) {
      throw 'Sesi login telah berakhir. Silakan login ulang.';
    }
    return token;
  }

  static Future<Map<String, String>> _authHeaders({bool jsonBody = false}) async {
    final token = await _requireToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
  }

  static Uri _buildUri(String path, [Map<String, String>? qp]) {
    return Uri.parse('$baseUrl$path')
        .replace(queryParameters: qp?.isEmpty == true ? null : qp);
  }

  static String _extractErrorMessage(String rawBody, String defaultMsg) {
    try {
      final body = json.decode(rawBody);
      if (body is Map) {
        if (body['errors'] != null && body['errors'] is Map) {
          final errors = Map<String, dynamic>.from(body['errors']);
          final buffer = StringBuffer();
          errors.forEach((k, v) {
            if (v is List && v.isNotEmpty) {
              buffer.writeln('$k: ${v.first}');
            } else if (v is String) {
              buffer.writeln('$k: $v');
            }
          });
          if (buffer.isNotEmpty) return buffer.toString().trim();
        } else if (body['message'] != null) {
          return body['message'].toString();
        }
      }
    } catch (_) {}
    return defaultMsg;
  }

  static Future<List<PerawatModel>> fetchPerawat({
    String? search,
    String? filterStatus,
    int? filterActive,
  }) async {
    final qp = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      qp['search'] = search.trim();
    }

    try {
      final res = await http
          .get(_buildUri('/admin/perawat', qp), headers: await _authHeaders())
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw 'Gagal mengambil data perawat (kode ${res.statusCode})';
      }

      final decoded = json.decode(res.body);
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
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat daftar perawat.';
    }
  }

  static Future<PerawatDetailModel> fetchPerawatDetail(int id) async {
    try {
      final res = await http
          .get(_buildUri('/admin/perawat/$id'), headers: await _authHeaders())
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw 'Gagal mengambil detail perawat (kode ${res.statusCode})';
      }

      final decoded = json.decode(res.body);
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
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat detail perawat.';
    }
  }

  static Future<int> savePerawat({
    required Map<String, dynamic> body,
    int? perawatId,
  }) async {
    final isEdit = perawatId != null;
    final url = isEdit
        ? _buildUri('/admin/perawat-crud/$perawatId')
        : _buildUri('/admin/perawat-crud');

    try {
      final res = isEdit
          ? await http
              .put(url,
                  headers: await _authHeaders(jsonBody: true),
                  body: json.encode(body))
              .timeout(_timeout)
          : await http
              .post(url,
                  headers: await _authHeaders(jsonBody: true),
                  body: json.encode(body))
              .timeout(_timeout);

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw _extractErrorMessage(
            res.body, 'Gagal menyimpan data perawat (kode ${res.statusCode})');
      }

      int targetPerawatId = perawatId ?? 0;
      try {
        final decoded = json.decode(res.body);
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
    } on TimeoutException {
      throw 'Koneksi waktu habis saat menyimpan perawat.';
    }
  }

  static Future<void> assignKoordinatorDirect({
    required int perawatId,
    required int? koordinatorId,
  }) async {
    try {
      final res = await http
          .put(
            _buildUri('/admin/perawat/$perawatId/assign-koordinator'),
            headers: await _authHeaders(jsonBody: true),
            body: json.encode({'koordinator_id': koordinatorId}),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(res.body,
            'Gagal assign koordinator (kode ${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat assign koordinator.';
    }
  }

  static Future<void> deletePerawat(int id) async {
    try {
      final res = await http
          .delete(_buildUri('/admin/perawat-crud/$id'),
              headers: await _authHeaders())
          .timeout(_timeout);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw _extractErrorMessage(
            res.body, 'Gagal menghapus perawat (kode ${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat menghapus perawat.';
    }
  }

  static Future<String> setPassword({
    required int perawatId,
    required String password,
  }) async {
    try {
      final res = await http
          .put(
            _buildUri('/admin/perawat-crud/$perawatId/password'),
            headers: await _authHeaders(jsonBody: true),
            body: json.encode({'password': password}),
          )
          .timeout(_timeout);

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw _extractErrorMessage(
            res.body, 'Gagal set password perawat (kode ${res.statusCode})');
      }

      String emailLogin = '-';
      try {
        final decoded = json.decode(res.body);
        if (decoded is Map && decoded['data'] is Map) {
          emailLogin = (decoded['data']['login_email'] ?? '-').toString();
        }
      } catch (_) {}

      return emailLogin;
    } on TimeoutException {
      throw 'Koneksi waktu habis saat set password perawat.';
    }
  }

  static Future<void> updateVerifikasi({
    required int perawatId,
    required String status,
    String? note,
  }) async {
    try {
      final res = await http
          .put(
            _buildUri('/admin/perawat-crud/$perawatId/verifikasi'),
            headers: await _authHeaders(jsonBody: true),
            body: json.encode({
              'status_verifikasi': status,
              'catatan_verifikasi':
                  note?.trim().isEmpty == true ? null : note?.trim(),
            }),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(res.body,
            'Gagal update status verifikasi (kode ${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat update verifikasi.';
    }
  }
}

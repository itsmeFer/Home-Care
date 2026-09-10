import 'dart:async';
import 'dart:convert';
import 'package:home_care/admin/role/models/role_admin_models.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:http/http.dart' as http;

class RoleAdminService {
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

  static String _extractErrorMessage(String rawBody, String defaultMsg) {
    try {
      final body = json.decode(rawBody);
      if (body is Map) {
        if (body['errors'] != null && body['errors'] is Map) {
          final errors = Map<String, dynamic>.from(body['errors']);
          final buffer = StringBuffer();
          errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              buffer.writeln('$key: ${value.first}');
            } else if (value is String) {
              buffer.writeln('$key: $value');
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

  static Future<List<RoleModel>> fetchRoles() async {
    try {
      final url = Uri.parse('$baseUrl/admin/roles');
      final res = await http.get(url, headers: await _authHeaders()).timeout(_timeout);

      if (res.statusCode != 200) {
        throw 'Gagal mengambil data role (kode ${res.statusCode})';
      }

      final body = json.decode(res.body);
      if (body is Map && body['data'] != null) {
        final paginated = body['data'];
        if (paginated is Map && paginated['data'] != null) {
          final List<dynamic> data = paginated['data'];
          return data
              .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      throw 'Format data role tidak sesuai.';
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat daftar role.';
    }
  }

  static Future<void> createRole(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/admin/roles');
      final res = await http
          .post(url,
              headers: await _authHeaders(jsonBody: true),
              body: json.encode(payload))
          .timeout(_timeout);

      if (res.statusCode != 201 && res.statusCode != 200) {
        throw _extractErrorMessage(
            res.body, 'Gagal menambah role (kode ${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat membuat role baru.';
    }
  }

  static Future<void> updateRole(int id, Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/admin/roles/$id');
      final res = await http
          .put(url,
              headers: await _authHeaders(jsonBody: true),
              body: json.encode(payload))
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(
            res.body, 'Gagal mengupdate role (kode ${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat mengupdate role.';
    }
  }

  static Future<void> deleteRole(int id) async {
    try {
      final url = Uri.parse('$baseUrl/admin/roles/$id');
      final res = await http
          .delete(url, headers: await _authHeaders())
          .timeout(_timeout);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw _extractErrorMessage(
            res.body, 'Gagal menghapus role (kode ${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat menghapus role.';
    }
  }

  static Future<AssignFormData> fetchAssignFormData() async {
    try {
      final url = Uri.parse('$baseUrl/admin/roles/assign-form-data');
      final res = await http.get(url, headers: await _authHeaders()).timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(res.body,
            'Gagal mengambil data user & role (kode ${res.statusCode})');
      }

      final decoded = json.decode(res.body);
      if (decoded is! Map) throw 'Format data assign tidak sesuai.';

      return AssignFormData.fromJson(Map<String, dynamic>.from(decoded));
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat data assign user.';
    }
  }

  static Future<void> assignRoleToUser({
    required int userId,
    required int roleId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/roles/assign');
      final res = await http
          .post(
            url,
            headers: await _authHeaders(jsonBody: true),
            body: json.encode({'user_id': userId, 'role_id': roleId}),
          )
          .timeout(_timeout);

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw _extractErrorMessage(
            res.body, 'Gagal meng-assign role (kode ${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat meng-assign role.';
    }
  }
}

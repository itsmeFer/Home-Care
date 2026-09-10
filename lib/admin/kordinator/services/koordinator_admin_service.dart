import 'dart:async';
import 'dart:convert';
import 'package:home_care/admin/kordinator/models/koordinator_admin_model.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:http/http.dart' as http;

class KoordinatorAdminService {
  static const Duration _timeout = Duration(seconds: 15);
  static String get baseUrl => ApiConstants.apiBase;

  static Future<String> _requireToken() async {
    final token = await StorageService.getToken();
    if (token == null || token.trim().isEmpty) {
      throw 'Sesi login telah berakhir. Silakan login ulang.';
    }
    return token;
  }

  static Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final token = await _requireToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
  }

  static String _extractErrorMessage(String responseBody, String fallback) {
    try {
      final body = json.decode(responseBody);
      if (body is Map) {
        if (body['errors'] != null) {
          final errors = body['errors'] as Map<String, dynamic>;
          final buffer = StringBuffer();
          errors.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              buffer.writeln('$key: ${value.first}');
            }
          });
          if (buffer.isNotEmpty) {
            return buffer.toString().trim();
          }
        } else if (body['message'] != null) {
          return body['message'].toString();
        }
      }
    } catch (_) {}
    return fallback;
  }

  static Future<List<Koordinator>> fetchKoordinator() async {
    try {
      final url = Uri.parse('$baseUrl/admin/koordinator');
      final res = await http.get(url, headers: await _headers()).timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(
          res.body,
          'Gagal mengambil data koordinator (kode ${res.statusCode})',
        );
      }

      final body = json.decode(res.body);
      if (body is Map && body['success'] == true && body['data'] != null) {
        final List<dynamic> data = body['data'];
        return data.map((e) => Koordinator.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw body['message'] ?? 'Gagal mengambil data koordinator dari server.';
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat data koordinator.';
    }
  }

  static Future<void> createKoordinator(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/admin/koordinator');
      final res = await http
          .post(
            url,
            headers: await _headers(jsonBody: true),
            body: json.encode(payload),
          )
          .timeout(_timeout);

      if (res.statusCode != 201 && res.statusCode != 200) {
        throw _extractErrorMessage(
          res.body,
          'Gagal menambah koordinator (kode ${res.statusCode})',
        );
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat menambah koordinator.';
    }
  }

  static Future<void> updateKoordinator(int id, Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/admin/koordinator/$id');
      final res = await http
          .put(
            url,
            headers: await _headers(jsonBody: true),
            body: json.encode(payload),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(
          res.body,
          'Gagal mengupdate koordinator (kode ${res.statusCode})',
        );
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat mengupdate koordinator.';
    }
  }

  static Future<void> deleteKoordinator(int id) async {
    try {
      final url = Uri.parse('$baseUrl/admin/koordinator/$id');
      final res = await http.delete(url, headers: await _headers()).timeout(_timeout);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw _extractErrorMessage(
          res.body,
          'Gagal menghapus koordinator (kode ${res.statusCode})',
        );
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat menghapus koordinator.';
    }
  }
}

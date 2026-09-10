import 'dart:async';
import 'dart:convert';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:http/http.dart' as http;

class LayananAdminService {
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
        if (body['errors'] is Map) {
          final errors = body['errors'] as Map;
          final List<String> all = [];
          errors.forEach((key, value) {
            if (value is List) {
              for (var v in value) {
                all.add('$key: $v');
              }
            } else if (value != null) {
              all.add('$key: $value');
            }
          });
          if (all.isNotEmpty) return all.join('\n');
        }
        if (body['message'] is String && (body['message'] as String).isNotEmpty) {
          return body['message'] as String;
        }
      }
    } catch (_) {}
    return fallback;
  }

  static Future<List<KategoriLayananItem>> fetchKategori() async {
    try {
      final url = Uri.parse('$baseUrl/admin/kategori-layanan');
      final res = await http.get(url, headers: await _headers()).timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(
          res.body,
          'Gagal mengambil kategori (${res.statusCode})',
        );
      }

      final body = json.decode(res.body);
      final List data = (body['data'] as List?) ?? [];
      return data
          .map((e) => KategoriLayananItem.fromJson(e as Map<String, dynamic>))
          .where((e) => e.slug.trim().isNotEmpty)
          .toList();
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat kategori.';
    }
  }

  static Future<List<Layanan>> fetchLayanan() async {
    try {
      final url = Uri.parse('$baseUrl/layanan');
      final res = await http.get(url, headers: await _headers()).timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(
          res.body,
          'Gagal mengambil data layanan (kode ${res.statusCode})',
        );
      }

      final body = json.decode(res.body);
      if (body['success'] != true) {
        throw body['message'] ?? 'Gagal mengambil data layanan dari server.';
      }

      final List<dynamic> data = body['data'] ?? [];
      return data.map((e) => Layanan.fromJson(e as Map<String, dynamic>)).toList();
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat daftar layanan.';
    }
  }

  static Future<void> createLayanan(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/layanan');
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
          'Gagal membuat layanan (kode ${res.statusCode})',
        );
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat membuat layanan.';
    }
  }

  static Future<void> updateLayanan(int id, Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/layanan/$id');
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
          'Gagal mengupdate layanan (kode ${res.statusCode})',
        );
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat mengupdate layanan.';
    }
  }

  static Future<void> deleteLayanan(int id) async {
    try {
      final url = Uri.parse('$baseUrl/layanan/$id');
      final res = await http.delete(url, headers: await _headers()).timeout(_timeout);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw _extractErrorMessage(
          res.body,
          'Gagal menghapus layanan (kode ${res.statusCode})',
        );
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat menghapus layanan.';
    }
  }
}

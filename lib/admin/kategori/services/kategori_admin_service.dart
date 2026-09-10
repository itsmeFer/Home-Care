import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_care/admin/kategori/models/kategori_layanan_model.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:http/http.dart' as http;

class KategoriAdminService {
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _uploadTimeout = Duration(seconds: 25);

  static String get baseUrl => ApiConstants.apiBase;

  static Future<String> _requireToken() async {
    final token = await StorageService.getToken();
    if (token == null || token.trim().isEmpty) {
      throw 'Sesi login telah berakhir. Silakan login ulang.';
    }
    return token;
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  static String _extractValidationMessage(String rawBody, String defaultMsg) {
    try {
      final body = json.decode(rawBody);
      if (body is Map) {
        final msg = body['message'];
        if (msg is String && msg.isNotEmpty) return msg;

        if (body['errors'] is Map) {
          final errors = body['errors'] as Map;
          final List<String> all = [];
          errors.forEach((key, value) {
            if (value is List) {
              for (var v in value) {
                all.add('$key: $v');
              }
            } else if (value is String) {
              all.add('$key: $value');
            }
          });
          if (all.isNotEmpty) return all.join('\n');
        }
      }
    } catch (_) {}
    return defaultMsg;
  }

  static Future<List<KategoriLayanan>> fetchKategori({
    String? search,
    bool? aktif,
  }) async {
    final token = await _requireToken();
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (aktif != null) {
      queryParams['aktif'] = aktif.toString();
    }

    final uri = Uri.parse('$baseUrl/admin/kategori-layanan')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    try {
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(_timeout);

      if (res.statusCode != 200) {
        throw 'Gagal mengambil data kategori (kode ${res.statusCode})';
      }

      final body = json.decode(res.body);
      if (body['success'] != true) {
        throw body['message'] ?? 'Gagal mengambil data kategori.';
      }

      final List<dynamic> data = body['data'] ?? [];
      return data.map((e) => KategoriLayanan.fromJson(e)).toList();
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat kategori.';
    }
  }

  static Future<void> createKategori(Map<String, dynamic> payload) async {
    final token = await _requireToken();
    final uri = Uri.parse('$baseUrl/admin/kategori-layanan');

    try {
      final res = await http
          .post(uri, headers: _headers(token), body: json.encode(payload))
          .timeout(_timeout);

      if (res.statusCode != 201 && res.statusCode != 200) {
        String msg = 'Gagal membuat kategori (kode ${res.statusCode})';
        if (res.statusCode == 422) {
          msg = _extractValidationMessage(res.body, msg);
        } else {
          try {
            final body = json.decode(res.body);
            if (body is Map && body['message'] != null) {
              msg = body['message'];
            }
          } catch (_) {}
        }
        throw msg;
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat membuat kategori.';
    }
  }

  static Future<void> updateKategori(int id, Map<String, dynamic> payload) async {
    final token = await _requireToken();
    final uri = Uri.parse('$baseUrl/admin/kategori-layanan/$id');

    try {
      final res = await http
          .put(uri, headers: _headers(token), body: json.encode(payload))
          .timeout(_timeout);

      if (res.statusCode != 200) {
        String msg = 'Gagal mengupdate kategori (kode ${res.statusCode})';
        if (res.statusCode == 422) {
          msg = _extractValidationMessage(res.body, msg);
        } else {
          try {
            final body = json.decode(res.body);
            if (body is Map && body['message'] != null) {
              msg = body['message'];
            }
          } catch (_) {}
        }
        throw msg;
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat mengupdate kategori.';
    }
  }

  static Future<void> toggleKategori(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('$baseUrl/admin/kategori-layanan/$id/toggle');

    try {
      final res = await http.patch(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(_timeout);

      if (res.statusCode != 200) {
        String msg = 'Gagal mengubah status kategori (${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        throw msg;
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat mengubah status kategori.';
    }
  }

  static Future<void> deleteKategori(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('$baseUrl/admin/kategori-layanan/$id');

    try {
      final res = await http.delete(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(_timeout);

      if (res.statusCode != 200) {
        String msg = 'Gagal menghapus kategori (kode ${res.statusCode})';
        if (res.statusCode == 422) {
          msg = _extractValidationMessage(res.body, msg);
        } else {
          try {
            final body = json.decode(res.body);
            if (body is Map && body['message'] != null) {
              msg = body['message'];
            }
          } catch (_) {}
        }
        throw msg;
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat menghapus kategori.';
    }
  }

  static Future<void> deleteGambar(int id) async {
    final token = await _requireToken();
    final uri = Uri.parse('$baseUrl/admin/kategori-layanan/$id/gambar');

    try {
      final res = await http.delete(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(_timeout);

      if (res.statusCode != 200) {
        String msg = 'Gagal menghapus gambar (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        throw msg;
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat menghapus gambar.';
    }
  }

  static Future<void> uploadGambar({
    required int kategoriId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    final token = await _requireToken();
    final url = Uri.parse('$baseUrl/admin/kategori-layanan/$kategoriId/gambar');
    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (kIsWeb) {
      if (imageBytes == null) throw 'File gambar web tidak ditemukan.';
      request.files.add(
        http.MultipartFile.fromBytes(
          'gambar',
          imageBytes,
          filename: fileName ?? 'kategori.jpg',
        ),
      );
    } else {
      if (imageFile == null) throw 'File gambar tidak ditemukan.';
      request.files.add(
        await http.MultipartFile.fromPath('gambar', imageFile.path),
      );
    }

    try {
      final streamed = await request.send().timeout(_uploadTimeout);
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        String msg = 'Gagal upload gambar (kode ${res.statusCode})';
        if (res.statusCode == 422) {
          msg = _extractValidationMessage(res.body, msg);
        } else {
          try {
            final body = json.decode(res.body);
            if (body is Map && body['message'] != null) {
              msg = body['message'];
            }
          } catch (_) {}
        }
        throw msg;
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat mengunggah gambar kategori.';
    }
  }
}

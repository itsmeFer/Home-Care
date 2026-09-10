import 'dart:async';
import 'dart:convert';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class DetailLayananService {
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

  static Future<List<KategoriLayananItem>> fetchKategori() async {
    try {
      final url = Uri.parse('$baseUrl/admin/kategori-layanan');
      final res = await http.get(url, headers: await _authHeaders()).timeout(_timeout);

      if (res.statusCode != 200) {
        throw 'Gagal mengambil kategori (${res.statusCode})';
      }

      final body = json.decode(res.body);
      final List data = (body['data'] as List?) ?? [];
      return data.map((e) => KategoriLayananItem.fromJson(e)).toList();
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat kategori.';
    }
  }

  static Future<LayananDetail> fetchDetail(int layananId) async {
    try {
      final url = Uri.parse('$baseUrl/layanan/$layananId');
      final res = await http.get(url, headers: await _authHeaders()).timeout(_timeout);

      if (res.statusCode != 200) {
        throw 'Gagal mengambil detail layanan (kode ${res.statusCode})';
      }

      final body = json.decode(res.body);
      if (body is Map && body['success'] == true && body['data'] != null) {
        return LayananDetail.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw body['message'] ?? 'Data layanan tidak ditemukan.';
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat detail layanan.';
    }
  }

  static Future<List<KoordinatorItem>> fetchKoordinatorLayanan(int layananId) async {
    try {
      final url = Uri.parse('$baseUrl/admin/layanan/$layananId/koordinator');
      final res = await http.get(url, headers: await _authHeaders()).timeout(_timeout);

      if (res.statusCode != 200) {
        throw 'Gagal mengambil koordinator layanan (${res.statusCode})';
      }

      final body = json.decode(res.body);
      final List data = (body['data'] as List?) ?? [];
      return data.map((e) => KoordinatorItem.fromJson(e)).toList();
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat koordinator layanan.';
    }
  }

  static Future<List<KoordinatorItem>> fetchAllKoordinator() async {
    try {
      final url = Uri.parse('$baseUrl/admin/koordinator');
      final res = await http.get(url, headers: await _authHeaders()).timeout(_timeout);

      if (res.statusCode != 200) {
        throw 'Gagal mengambil daftar koordinator (${res.statusCode})';
      }

      final body = json.decode(res.body);
      final List data = (body['data'] as List?) ?? [];
      return data.map((e) => KoordinatorItem.fromJson(e)).toList();
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat daftar semua koordinator.';
    }
  }

  static Future<void> syncKoordinator(int layananId, List<int> koordinatorIds) async {
    try {
      final url = Uri.parse('$baseUrl/admin/layanan/$layananId/koordinator');
      final res = await http
          .put(
            url,
            headers: await _authHeaders(jsonBody: true),
            body: json.encode({'koordinator_ids': koordinatorIds}),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(
            res.body, 'Gagal menyimpan koordinator (${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat sinkronisasi koordinator.';
    }
  }

  static Future<void> updateKoordinatorPivot({
    required int layananId,
    required int koordinatorId,
    required bool aktif,
    String? catatan,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/admin/layanan/$layananId/koordinator/$koordinatorId');
      final res = await http
          .patch(
            url,
            headers: await _authHeaders(jsonBody: true),
            body: json.encode({'aktif': aktif, 'catatan': catatan}),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(
            res.body, 'Gagal update status koordinator (${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat mengubah status koordinator.';
    }
  }

  static Future<void> updateLayanan(int layananId, Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/layanan/$layananId');
      final res = await http
          .put(
            url,
            headers: await _authHeaders(jsonBody: true),
            body: json.encode(payload),
          )
          .timeout(_timeout);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(
            res.body, 'Gagal mengupdate layanan (kode ${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat mengupdate layanan.';
    }
  }

  static Future<void> deleteLayanan(int layananId) async {
    try {
      final url = Uri.parse('$baseUrl/layanan/$layananId');
      final res = await http
          .delete(url, headers: await _authHeaders())
          .timeout(_timeout);

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw _extractErrorMessage(
            res.body, 'Gagal menghapus layanan (kode ${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat menghapus layanan.';
    }
  }

  static Future<void> uploadGambarLayanan({
    required int layananId,
    required List<int> compressedBytes,
    required String filename,
  }) async {
    final token = await _requireToken();
    final url = Uri.parse('$baseUrl/layanan/$layananId/gambar');

    final request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    final multipartFile = http.MultipartFile.fromBytes(
      'gambar',
      compressedBytes,
      filename: filename,
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(multipartFile);

    try {
      final streamed = await request.send().timeout(_uploadTimeout);
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        throw _extractErrorMessage(
            res.body, 'Gagal mengupload gambar (kode ${res.statusCode})');
      }
    } on TimeoutException {
      throw 'Koneksi waktu habis saat mengupload gambar layanan.';
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/features/support_it/domain/support_it_models.dart';
import 'package:http/http.dart' as http;

class SupportItService {
  static const Duration _timeout = Duration(seconds: 15);
  static String get baseUrl => ApiConstants.apiBase;

  static Future<String> _requireToken() async {
    final token = ((await StorageService.getToken()) ?? '').trim();
    if (token.isEmpty) {
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
        if (body['message'] is String && (body['message'] as String).isNotEmpty) {
          return body['message'] as String;
        }
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
      }
    } catch (_) {}
    return fallback;
  }

  static Future<void> submitReport(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$baseUrl/support-tickets');
      final res = await http
          .post(
            url,
            headers: await _headers(jsonBody: true),
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return;
      }

      throw _extractErrorMessage(res.body, 'Gagal mengirim laporan.');
    } on TimeoutException {
      throw 'Koneksi waktu habis saat mengirim laporan ke tim IT.';
    }
  }

  static Future<List<SupportTicket>> fetchTickets({
    String? status,
    String? priority,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (priority != null && priority.isNotEmpty) {
        queryParams['priority'] = priority;
      }

      final uri = Uri.parse(
        '$baseUrl/support-tickets',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final res = await http.get(uri, headers: await _headers()).timeout(_timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['success'] == true) {
          final data = decoded['data'];
          if (data is List) {
            return data
                .whereType<Map>()
                .map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
        }
      }

      throw _extractErrorMessage(res.body, 'Gagal memuat riwayat laporan.');
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat riwayat laporan IT.';
    }
  }
}

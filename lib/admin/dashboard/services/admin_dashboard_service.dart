import 'dart:async';
import 'dart:convert';
import 'package:home_care/admin/dashboard/models/admin_dashboard_models.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:http/http.dart' as http;

class AdminDashboardService {
  static const Duration _timeout = Duration(seconds: 15);

  static String get baseUrl => ApiConstants.apiBase;

  static Future<String> _requireToken() async {
    final token = await StorageService.getToken();
    if (token == null || token.trim().isEmpty) {
      throw 'Sesi login telah berakhir. Silakan login ulang.';
    }
    return token;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _requireToken();
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<DashboardStatistics> fetchStatistics() async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$baseUrl/admin/fee/users-list/statistics');

      final res = await http.get(uri, headers: headers).timeout(_timeout);
      final dynamic decoded = jsonDecode(res.body);

      if (res.statusCode == 200 && decoded is Map && decoded['success'] == true) {
        final data = decoded['data'] as Map<String, dynamic>? ?? {};
        return DashboardStatistics.fromJson(data);
      }

      throw decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Gagal memuat statistik pengguna.';
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat data statistik.';
    }
  }

  static Future<List<AdminUserItem>> fetchUsersByRole(String roleSlug) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$baseUrl/admin/fee/users-list').replace(
        queryParameters: {
          'role_slug': roleSlug,
          'per_page': '100',
          'sort_by': 'created_at',
          'sort_order': 'desc',
        },
      );

      final res = await http.get(uri, headers: headers).timeout(_timeout);
      final dynamic decoded = jsonDecode(res.body);

      if (res.statusCode == 200 && decoded is Map && decoded['success'] == true) {
        final rawList = (decoded['data']?['data'] as List<dynamic>?) ?? [];
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => AdminUserItem.fromJson(e))
            .toList();
      }

      throw decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Gagal memuat daftar pengguna.';
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat daftar pengguna.';
    }
  }

  static Future<AdminUserDetail> fetchUserDetail(int userId) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$baseUrl/admin/fee/users-list/$userId');

      final res = await http.get(uri, headers: headers).timeout(_timeout);
      final dynamic decoded = jsonDecode(res.body);

      if (res.statusCode == 200 && decoded is Map && decoded['success'] == true) {
        final rawData = decoded['data'] as Map<String, dynamic>? ?? {};
        return AdminUserDetail.fromJson(rawData);
      }

      throw decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Gagal memuat detail pengguna.';
    } on TimeoutException {
      throw 'Koneksi waktu habis saat memuat detail pengguna.';
    }
  }

  static Future<void> logout() async {
    try {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse('$baseUrl/logout');
        await http.post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Ignore network errors on logout to allow local session cleanup
    } finally {
      await StorageService.clearAuth();
    }
  }
}

import 'dart:async';
import 'package:home_care/admin/dashboard/models/admin_dashboard_models.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/services/storage_service.dart';

class AdminDashboardService {
  AdminDashboardService._();

  static Future<DashboardStatistics> fetchStatistics() async {
    final res = await ApiClient.get('/admin/fee/users-list/statistics');
    if (res is Map && res['data'] is Map) {
      final data = Map<String, dynamic>.from(res['data'] as Map);
      return DashboardStatistics.fromJson(data);
    }
    if (res is Map && res['success'] == false) {
      throw res['message']?.toString() ?? 'Gagal memuat statistik pengguna.';
    }
    return const DashboardStatistics(
      summary: DashboardSummary(),
      roleStats: [],
    );
  }

  static Future<List<AdminUserItem>> fetchUsersByRole(String roleSlug) async {
    final res = await ApiClient.get(
      '/admin/fee/users-list',
      queryParams: {
        'role_slug': roleSlug,
        'per_page': '100',
        'sort_by': 'created_at',
        'sort_order': 'desc',
      },
    );

    if (res is Map) {
      final data = res['data'];
      List rawList = [];
      if (data is Map && data['data'] is List) {
        rawList = data['data'] as List;
      } else if (data is List) {
        rawList = data;
      }
      return rawList
          .whereType<Map>()
          .map((e) => AdminUserItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<AdminUserDetail> fetchUserDetail(int userId) async {
    final res = await ApiClient.get('/admin/fee/users-list/$userId');
    if (res is Map && res['data'] is Map) {
      final rawData = Map<String, dynamic>.from(res['data'] as Map);
      return AdminUserDetail.fromJson(rawData);
    }
    throw 'Gagal memuat detail pengguna.';
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post('/logout');
    } catch (_) {
      // Ignore network errors on logout to allow local session cleanup
    } finally {
      await StorageService.clearAuth();
    }
  }
}

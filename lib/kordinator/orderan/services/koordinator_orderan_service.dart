import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/orders/domain/order_models.dart';
import 'package:intl/intl.dart';

class KoordinatorOrderanService {
  static Future<List<OrderKoordinator>> fetchOrders({
    String? status,
    String? search,
    DateTime? tanggalDari,
    DateTime? tanggalSampai,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (tanggalDari != null) {
      queryParams['tanggal_mulai_dari'] =
          DateFormat('yyyy-MM-dd').format(tanggalDari);
    }

    if (tanggalSampai != null) {
      queryParams['tanggal_mulai_sampai'] =
          DateFormat('yyyy-MM-dd').format(tanggalSampai);
    }

    final res = await ApiClient.get(
      '/koordinator/order-layanan',
      queryParams: queryParams.isEmpty ? null : queryParams,
    );

    if (res is Map && res['data'] is List) {
      final List list = res['data'] as List;
      return list
          .whereType<Map>()
          .map((e) => OrderKoordinator.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> fetchDetail(int orderId) async {
    final res = await ApiClient.get('/koordinator/order-layanan/$orderId');
    if (res is Map && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchPerawatList() async {
    final res = await ApiClient.get('/koordinator/perawat-list');
    if (res is Map && res['data'] is List) {
      final List<dynamic> data = res['data'];
      return data
          .whereType<Map>()
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> assignPerawat({
    required int orderId,
    required int perawatId,
  }) async {
    final res = await ApiClient.post(
      '/koordinator/order-layanan/$orderId/assign-perawat',
      body: {'perawat_id': perawatId.toString()},
    );
    if (res is Map && res['data'] is Map) {
      return Map<String, dynamic>.from(res['data'] as Map);
    }
    return {};
  }
}

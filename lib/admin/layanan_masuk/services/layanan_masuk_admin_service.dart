import 'package:home_care/admin/layanan_masuk/models/order_detail_admin_model.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/orders/domain/order_models.dart';

class LayananMasukAdminService {
  static Future<List<OrderLayananAdmin>> fetchOrders({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final decoded = await ApiClient.get(
      '/admin/order-layanan',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (decoded is Map<String, dynamic> && decoded['success'] == true) {
      final List<dynamic> data = decoded['data'] ?? [];
      return data
          .whereType<Map>()
          .map((e) => OrderLayananAdmin.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw decoded is Map
        ? (decoded['message']?.toString() ?? 'Gagal memuat data order layanan.')
        : 'Gagal memuat data order layanan.';
  }

  static Future<OrderLayananDetailAdmin> fetchOrderDetail(int orderId) async {
    final decoded = await ApiClient.get('/admin/order-layanan/$orderId');

    if (decoded is Map<String, dynamic> &&
        decoded['success'] == true &&
        decoded['data'] is Map) {
      return OrderLayananDetailAdmin.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    }
    throw decoded is Map
        ? (decoded['message']?.toString() ?? 'Gagal memuat detail order.')
        : 'Gagal memuat detail order.';
  }

  static Future<List<KoordinatorOption>> fetchKoordinators() async {
    final decoded = await ApiClient.get('/admin/koordinator-list');

    if (decoded is Map<String, dynamic> && decoded['success'] == true) {
      final List<dynamic> data = decoded['data'] ?? [];
      return data
          .whereType<Map>()
          .map((e) => KoordinatorOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<OrderLayananDetailAdmin> assignKoordinator(
    int orderId,
    int koordinatorId,
  ) async {
    final decoded = await ApiClient.post(
      '/admin/order-layanan/$orderId/assign-koordinator',
      body: {'koordinator_id': koordinatorId.toString()},
    );

    if (decoded is Map<String, dynamic> && decoded['success'] == true) {
      return OrderLayananDetailAdmin.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    }
    throw decoded is Map
        ? (decoded['message']?.toString() ?? 'Gagal menyimpan penugasan.')
        : 'Gagal menyimpan penugasan.';
  }
}

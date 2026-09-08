import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/orders/domain/order_models.dart';

/// Repository untuk penanganan pesanan dan alur tracking bagi seluruh role.
class OrderRepository {
  const OrderRepository();

  /// Mengambil daftar histori pesanan pasien.
  Future<List<OrderLayananItem>> getPasienOrders({
    String? status,
    int? page,
  }) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (page != null) params['page'] = page.toString();

    final response = await ApiClient.get(
      ApiConstants.pasienHistoriOrder,
      queryParams: params.isNotEmpty ? params : null,
    );

    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(OrderLayananItem.fromJson)
        .toList();
  }

  /// Mengambil daftar pesanan aktif (berjalan) untuk pasien.
  Future<List<OrderLayananItem>> getPasienOrdersAktif() async {
    final response = await ApiClient.get(ApiConstants.pasienOrdersAktif);
    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(OrderLayananItem.fromJson)
        .toList();
  }

  /// Mengambil daftar order yang ditugaskan ke perawat yang sedang login.
  Future<List<OrderLayananItem>> getPerawatOrders({
    String? status,
    String? q,
    String? dari,
    String? sampai,
  }) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (dari != null && dari.isNotEmpty) params['tanggal_dari'] = dari;
    if (sampai != null && sampai.isNotEmpty) params['tanggal_sampai'] = sampai;

    final response = await ApiClient.get(
      ApiConstants.perawatOrderLayanan,
      queryParams: params.isNotEmpty ? params : null,
    );

    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(OrderLayananItem.fromJson)
        .toList();
  }

  /// Mengambil daftar order untuk koordinator wilayah.
  Future<List<OrderLayananItem>> getKoordinatorOrders({
    String? status,
    String? q,
    String? dari,
    String? sampai,
  }) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (dari != null && dari.isNotEmpty) params['tanggal_dari'] = dari;
    if (sampai != null && sampai.isNotEmpty) params['tanggal_sampai'] = sampai;

    final response = await ApiClient.get(
      ApiConstants.koordinatorOrderLayanan,
      queryParams: params.isNotEmpty ? params : null,
    );

    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(OrderLayananItem.fromJson)
        .toList();
  }

  /// Mengambil daftar seluruh orderan masuk (Admin).
  Future<List<OrderLayananItem>> getAdminOrders({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await ApiClient.get(
      ApiConstants.adminOrderLayanan,
      queryParams: params.isNotEmpty ? params : null,
    );

    final List data = _extractListData(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(OrderLayananItem.fromJson)
        .toList();
  }

  /// Mengambil detail pesanan berdasarkan ID dan role pemanggil.
  Future<Map<String, dynamic>> getOrderDetail(
    int id, {
    String role = 'pasien',
  }) async {
    final String url;
    switch (role.toLowerCase()) {
      case 'perawat':
        url = ApiConstants.perawatOrderDetail(id);
        break;
      case 'koordinator':
        url = ApiConstants.koordinatorOrderDetail(id);
        break;
      case 'admin':
        url = ApiConstants.adminOrderLayananDetail(id);
        break;
      case 'pasien':
      default:
        url = ApiConstants.pasienHistoriOrderDetail(id);
        break;
    }

    final response = await ApiClient.get(url);
    if (response is Map<String, dynamic>) {
      if (response['data'] is Map) {
        return Map<String, dynamic>.from(response['data'] as Map);
      }
      return response;
    }
    return {'id': id, 'raw': response};
  }

  /// Membuat draft pesanan baru (Pasien).
  Future<Map<String, dynamic>> createOrderDraft(
    Map<String, dynamic> payload,
  ) async {
    final response = await ApiClient.post(
      ApiConstants.pasienOrderDraftStore,
      body: payload,
    );
    if (response is Map<String, dynamic>) return response;
    return {'success': true, 'data': response};
  }

  /// Membatalkan pesanan (Pasien).
  Future<Map<String, dynamic>> cancelOrder(
    int orderId, {
    required String alasan,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.pasienOrderCancel(orderId),
      body: {'alasan': alasan.trim()},
    );
    if (response is Map<String, dynamic>) return response;
    return {'success': true, 'data': response};
  }

  /// Memberikan rating dan komentar setelah pesanan selesai (Pasien).
  Future<Map<String, dynamic>> rateOrder(
    int orderId, {
    required int rating,
    String? komentar,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.pasienOrderRating(orderId),
      body: {
        'rating': rating,
        if (komentar != null && komentar.isNotEmpty) 'komentar': komentar.trim(),
      },
    );
    if (response is Map<String, dynamic>) return response;
    return {'success': true, 'data': response};
  }

  // --- Perawat Action Endpoints ---

  /// Perawat menerima penugasan order.
  Future<void> perawatTerimaOrder(int orderId) async {
    await ApiClient.post(ApiConstants.perawatOrderTerima(orderId));
  }

  /// Perawat menolak penugasan order.
  Future<void> perawatTolakOrder(int orderId, {String? alasan}) async {
    await ApiClient.post(
      ApiConstants.perawatOrderTolak(orderId),
      body: alasan != null ? {'alasan': alasan.trim()} : null,
    );
  }

  /// Perawat menandai sudah sampai di lokasi pasien.
  Future<void> perawatSampaiLokasi(int orderId) async {
    await ApiClient.post(ApiConstants.perawatOrderSampai(orderId));
  }

  /// Perawat memulai sesi visit / tindakan medis.
  Future<void> perawatMulaiVisit(int orderId) async {
    await ApiClient.post(ApiConstants.perawatOrderMulaiVisit(orderId));
  }

  /// Perawat menyelesaikan layanan.
  Future<void> perawatSelesaiOrder(int orderId) async {
    await ApiClient.post(ApiConstants.perawatOrderSelesai(orderId));
  }

  // --- Koordinator Action Endpoints ---

  /// Koordinator menugaskan perawat ke pesanan.
  Future<void> assignPerawatToOrder({
    required int orderId,
    required int perawatId,
  }) async {
    await ApiClient.post(
      ApiConstants.koordinatorOrderAssign(orderId),
      body: {'perawat_id': perawatId},
    );
  }

  static List _extractListData(dynamic response) {
    if (response == null) return [];
    if (response is List) return response;
    if (response is Map) {
      if (response['data'] is List) return response['data'] as List;
      if (response['data'] is Map && response['data']['data'] is List) {
        return response['data']['data'] as List;
      }
    }
    return [];
  }
}

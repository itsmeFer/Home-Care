import 'dart:convert';
import 'package:home_care/admin/layanan_masuk/models/order_detail_admin_model.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:http/http.dart' as http;

class LayananMasukAdminService {
  static String get baseUrl => ApiConstants.apiBase;

  static Future<String> _requireToken() async {
    final token = await StorageService.getToken();
    if (token == null || token.trim().isEmpty) {
      throw 'Sesi login admin telah berakhir. Silakan login ulang.';
    }
    return token.trim();
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _requireToken();
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<OrderLayananDetailAdmin> fetchOrderDetail(int orderId) async {
    final uri = Uri.parse('$baseUrl/admin/order-layanan/$orderId');
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == true && decoded['data'] is Map) {
        return OrderLayananDetailAdmin.fromJson(
          Map<String, dynamic>.from(decoded['data'] as Map),
        );
      }
      throw decoded['message']?.toString() ?? 'Gagal memuat detail order.';
    } else if (response.statusCode == 404) {
      throw 'Order tidak ditemukan (404).';
    } else if (response.statusCode == 401) {
      throw 'Sesi login admin telah berakhir. Silakan login ulang.';
    } else {
      throw 'Gagal memuat detail. Kode: ${response.statusCode}';
    }
  }

  static Future<List<KoordinatorOption>> fetchKoordinators() async {
    final uri = Uri.parse('$baseUrl/admin/koordinator-list');
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (decoded['success'] == true) {
        final List<dynamic> data = decoded['data'] ?? [];
        return data
            .whereType<Map>()
            .map((e) => KoordinatorOption.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return [];
  }

  static Future<OrderLayananDetailAdmin> assignKoordinator(
    int orderId,
    int koordinatorId,
  ) async {
    final uri = Uri.parse('$baseUrl/admin/order-layanan/$orderId/assign-koordinator');
    final headers = await _headers();

    final response = await http.post(
      uri,
      headers: headers,
      body: {'koordinator_id': koordinatorId.toString()},
    );

    final decoded = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && decoded['success'] == true) {
      return OrderLayananDetailAdmin.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    } else if (response.statusCode == 422) {
      throw decoded['message']?.toString() ?? 'Validasi gagal (422).';
    } else {
      throw decoded['message']?.toString() ??
          'Gagal menyimpan penugasan. Kode: ${response.statusCode}';
    }
  }
}

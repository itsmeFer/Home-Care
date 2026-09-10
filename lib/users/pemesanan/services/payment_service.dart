import 'package:flutter/foundation.dart';
import 'package:home_care/core/network/api_client.dart';

class PaymentService {
  const PaymentService();

  Future<Map<String, dynamic>?> fetchDraft(int draftId) async {
    try {
      final res = await ApiClient.get('/pasien/order-draft/$draftId');
      if (res is Map && res['success'] == true) {
        final data = res['data'];
        if (data is Map && data['draft'] is Map) {
          return Map<String, dynamic>.from(data['draft'] as Map);
        } else if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching draft: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> payDraft(int draftId, String method) async {
    try {
      final res = await ApiClient.post(
        '/pasien/order-draft/$draftId/bayar',
        body: {'method': method},
      );
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return (res['data'] as Map).cast<String, dynamic>();
      }
      throw Exception(res is Map ? (res['message'] ?? 'Gagal membuat pembayaran') : 'Gagal membuat pembayaran');
    } catch (e) {
      debugPrint('Error paying draft: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> checkStatus(int draftId) async {
    try {
      final res = await ApiClient.get('/pasien/order-draft/$draftId/status');
      if (res is Map && res['data'] != null) {
        if (res['data'] is Map) {
          return Map<String, dynamic>.from(res['data'] as Map);
        }
        return Map<String, dynamic>.from(res);
      }
      return null;
    } catch (e) {
      debugPrint('Error checking status: $e');
      return null;
    }
  }
}

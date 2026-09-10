import 'package:flutter/foundation.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:http/http.dart' as http;

class BookingService {
  const BookingService();

  Future<List<Addon>> fetchAddons(int layananId) async {
    try {
      final res = await ApiClient.get('/pasien/layanan/$layananId/addons');
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data.map((e) => Addon.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching addons: $e');
      return [];
    }
  }

  Future<List<Layanan>> fetchRelatedServices() async {
    try {
      final res = await ApiClient.get('/pasien/layanan');
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data.map((e) => Layanan.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching related services: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final res = await ApiClient.get('/me');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        final data = res['data'] as Map<String, dynamic>;
        if (data['pasien'] is Map) {
          return Map<String, dynamic>.from(data['pasien'] as Map);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> submitDraft({
    required Map<String, String> fields,
    Uint8List? kondisiBytes,
    String? kondisiFileName,
  }) async {
    final uri = Uri.parse('${ApiConstants.apiBase}/pasien/order-layanan');
    final request = http.MultipartRequest('POST', uri);
    request.fields.addAll(fields);

    if (kondisiBytes != null && kondisiFileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'kondisi_pasien',
          kondisiBytes,
          filename: kondisiFileName,
        ),
      );
    }

    final res = await ApiClient.sendMultipart(request);
    if (res is Map && res['success'] == true) {
      return (res['data'] as Map).cast<String, dynamic>();
    }
    throw Exception(res is Map ? (res['message'] ?? 'Gagal membuat draft') : 'Gagal membuat draft');
  }
}

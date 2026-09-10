import 'package:flutter/foundation.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

class LayananService {
  const LayananService();

  Future<List<Layanan>> fetchLayanan() async {
    try {
      final res = await ApiClient.get('/layanan');
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data
            .map(
              (e) => Layanan.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching layanan: $e');
      rethrow;
    }
  }

  Future<List<KategoriLayananItem>> fetchKategori() async {
    try {
      final res = await ApiClient.get('/kategori-layanan');
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data
            .map(
              (e) => KategoriLayananItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching kategori layanan: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchPatientProfile() async {
    try {
      final res = await ApiClient.get('/me');
      if (res is Map && res['data'] is Map) {
        final data = res['data'] as Map<String, dynamic>;
        return data['pasien'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching profile in layanan: $e');
      return null;
    }
  }
}

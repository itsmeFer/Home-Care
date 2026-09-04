import 'package:flutter/foundation.dart';
import 'package:home_care/core/network/api_client.dart';

class WilayahItem {
  final String id;
  final String name;

  const WilayahItem({required this.id, required this.name});

  factory WilayahItem.fromJson(Map<String, dynamic> json) {
    return WilayahItem(
      id: (json['id'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
    );
  }

  Map<String, String> toMap() => {'id': id, 'name': name};
}

class WilayahService {
  static Future<List<Map<String, String>>> fetchProvinsi() async {
    try {
      final res = await ApiClient.get('/wilayah/provinsi');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List)
            .map<Map<String, String>>((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return {
                'id': (m['id'] ?? '').toString().trim(),
                'name': (m['name'] ?? '').toString().trim(),
              };
            })
            .where((e) => e['id']!.isNotEmpty && e['name']!.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching provinsi: $e');
      return [];
    }
  }

  static Future<List<Map<String, String>>> fetchKota(String provinsiId) async {
    try {
      final res = await ApiClient.get('/wilayah/kota/$provinsiId');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List)
            .map<Map<String, String>>((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return {
                'id': (m['id'] ?? '').toString().trim(),
                'name': (m['name'] ?? '').toString().trim(),
              };
            })
            .where((e) => e['id']!.isNotEmpty && e['name']!.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching kota: $e');
      return [];
    }
  }

  static Future<List<Map<String, String>>> fetchKecamatan(String kotaId) async {
    try {
      final res = await ApiClient.get('/wilayah/kecamatan/$kotaId');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List)
            .map<Map<String, String>>((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return {
                'id': (m['id'] ?? '').toString().trim(),
                'name': (m['name'] ?? '').toString().trim(),
              };
            })
            .where((e) => e['id']!.isNotEmpty && e['name']!.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching kecamatan: $e');
      return [];
    }
  }

  static Future<List<Map<String, String>>> fetchKelurahan(String kecamatanId) async {
    try {
      final res = await ApiClient.get('/wilayah/kelurahan/$kecamatanId');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List)
            .map<Map<String, String>>((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return {
                'id': (m['id'] ?? '').toString().trim(),
                'name': (m['name'] ?? '').toString().trim(),
              };
            })
            .where((e) => e['id']!.isNotEmpty && e['name']!.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching kelurahan: $e');
      return [];
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:http/http.dart' as http;

class UserProfileService {
  const UserProfileService();

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final res = await ApiClient.get('/me');
      if (res is Map && res['data'] is Map) {
        return res['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    int pasienId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await ApiClient.put('/pasien/$pasienId', body: payload);
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return (res['data'] as Map).cast<String, dynamic>();
      }
      throw Exception(res['message'] ?? 'Gagal memperbarui profil');
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<String?> uploadProfilePhotoBytes({
    required int pasienId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.apiBase}/pasien/$pasienId/foto-profil');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes('foto', bytes, filename: fileName),
      );
      final res = await ApiClient.sendMultipart(request);
      if (res is Map && res['success'] == true) {
        final data = res['data'];
        if (data is Map) {
          return data['foto_profil_url']?.toString() ??
              data['foto_profil']?.toString();
        }
        return res['foto_profil_url']?.toString() ??
            res['foto_url']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return null;
    }
  }
}

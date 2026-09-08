import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/services/storage_service.dart';

/// Repository untuk penanganan autentikasi dan manajemen sesi pengguna.
class AuthRepository {
  const AuthRepository();

  /// Melakukan login pengguna dengan username/email dan password.
  /// Menyimpan token ke StorageService dan data profil sesi ke SharedPreferences.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.login,
      body: {
        'username': username.trim(),
        'password': password.trim(),
      },
      requiresAuth: false,
    );

    if (response is Map<String, dynamic>) {
      final token =
          (response['token'] ?? response['access_token'])?.toString() ?? '';
      if (token.isNotEmpty) {
        await StorageService.saveToken(token);
      }

      if (response['data'] != null && response['data'] is Map) {
        final data = Map<String, dynamic>.from(response['data'] as Map);
        final prefs = await StorageService.instance;

        if (data['user_id'] != null) {
          await prefs.setInt(
            'user_id',
            int.tryParse('${data['user_id']}') ?? 0,
          );
        }
        if (data['pasien_id'] != null) {
          await prefs.setInt(
            'pasien_id',
            int.tryParse('${data['pasien_id']}') ?? 0,
          );
        }
        if (data['perawat_id'] != null) {
          await prefs.setInt(
            'perawat_id',
            int.tryParse('${data['perawat_id']}') ?? 0,
          );
        }
        if (data['koordinator_id'] != null) {
          await prefs.setInt(
            'koordinator_id',
            int.tryParse('${data['koordinator_id']}') ?? 0,
          );
        }

        await prefs.setString(
          'nama_lengkap',
          (data['nama_lengkap'] ?? '').toString(),
        );
        await prefs.setString('email', (data['email'] ?? '').toString());
        await prefs.setString(
          'no_rekam_medis',
          (data['no_rekam_medis'] ?? '').toString(),
        );

        if (data['role'] != null) {
          await prefs.setString('role', data['role'].toString());
        }
      }

      return response;
    }

    return {'success': true, 'data': response};
  }

  /// Melakukan pendaftaran akun pengguna baru.
  Future<Map<String, dynamic>> register({
    required String namaLengkap,
    required String noHp,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.register,
      body: {
        'nama_lengkap': namaLengkap.trim(),
        'no_hp': noHp.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      requiresAuth: false,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true, 'data': response};
  }

  /// Mengambil data user yang sedang aktif dari backend.
  Future<Map<String, dynamic>> getMe() async {
    final response = await ApiClient.get(ApiConstants.me);
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'data': response};
  }

  /// Melakukan logout server-side dan membersihkan sesi lokal via StorageService.
  Future<void> logout() async {
    try {
      await ApiClient.post(ApiConstants.logout);
    } catch (_) {
      // Abaikan jika network error, logout lokal harus tetap bersih
    } finally {
      await StorageService.clearAuth();
    }
  }

  /// Mengecek status verifikasi email akun pengguna.
  Future<Map<String, dynamic>> checkVerificationStatus(String email) async {
    final response = await ApiClient.post(
      ApiConstants.checkVerificationStatus,
      body: {'email': email.trim()},
      requiresAuth: false,
    );
    if (response is Map<String, dynamic>) return response;
    return {'success': true, 'data': response};
  }

  /// Mengirim ulang email verifikasi.
  Future<Map<String, dynamic>> resendVerification(String email) async {
    final response = await ApiClient.post(
      ApiConstants.resendVerification,
      body: {'email': email.trim()},
      requiresAuth: false,
    );
    if (response is Map<String, dynamic>) return response;
    return {'success': true, 'data': response};
  }

  /// Permintaan reset password melalui email.
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await ApiClient.post(
      ApiConstants.forgotPassword,
      body: {'email': email.trim()},
      requiresAuth: false,
    );
    if (response is Map<String, dynamic>) return response;
    return {'success': true, 'data': response};
  }

  /// Menghapus akun pengguna saat ini dan membersihkan sesi.
  Future<void> deleteAccount() async {
    try {
      await ApiClient.delete(ApiConstants.deleteAccount);
    } finally {
      await StorageService.clearAuth();
    }
  }
}

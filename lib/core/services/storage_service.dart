import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static const String keyAuthToken = 'auth_token';
  static const String keyLegacyToken = 'token';
  static const String keyUserRole = 'role';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserPhone = 'user_phone';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<String?> getToken() async {
    try {
      final secureToken = await _secureStorage.read(key: keyAuthToken);
      if (secureToken != null && secureToken.trim().isNotEmpty) {
        return secureToken.trim();
      }
    } catch (_) {}

    // Fallback & automatic migration from SharedPreferences (for existing active sessions)
    final prefs = await instance;
    final legacyAuth = prefs.getString(keyAuthToken);
    if (legacyAuth != null && legacyAuth.trim().isNotEmpty) {
      final clean = legacyAuth.trim();
      try {
        await _secureStorage.write(key: keyAuthToken, value: clean);
        await prefs.remove(keyAuthToken);
      } catch (_) {}
      return clean;
    }

    final legacyToken = prefs.getString(keyLegacyToken);
    if (legacyToken != null && legacyToken.trim().isNotEmpty) {
      final clean = legacyToken.trim();
      try {
        await _secureStorage.write(key: keyAuthToken, value: clean);
        await prefs.remove(keyLegacyToken);
      } catch (_) {}
      return clean;
    }

    return null;
  }

  static Future<bool> saveToken(String token) async {
    final clean = token.trim();
    try {
      await _secureStorage.write(key: keyAuthToken, value: clean);
    } catch (_) {}

    final prefs = await instance;
    await prefs.setString(keyLegacyToken, clean);
    return await prefs.setString(keyAuthToken, clean);
  }

  static Future<String?> getRole() async {
    final prefs = await instance;
    return prefs.getString(keyUserRole);
  }

  static Future<bool> saveRole(String role) async {
    final prefs = await instance;
    return await prefs.setString(keyUserRole, role.trim().toLowerCase());
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAuth() async {
    try {
      await _secureStorage.delete(key: keyAuthToken);
    } catch (_) {}

    final prefs = await instance;
    await prefs.remove(keyAuthToken);
    await prefs.remove(keyLegacyToken);
    await prefs.remove(keyUserRole);
    await prefs.remove(keyUserId);
    await prefs.remove('pasien_id');
    await prefs.remove('perawat_id');
    await prefs.remove('koordinator_id');
    await prefs.remove('nama_lengkap');
    await prefs.remove('email');
    await prefs.remove('no_rekam_medis');
    await prefs.remove('role');
    await prefs.remove('role_slug');
    await prefs.remove('user_role');
    await prefs.remove('name');
    await prefs.remove(keyUserName);
    await prefs.remove(keyUserEmail);
    await prefs.remove(keyUserPhone);
  }

  static Future<String?> getString(String key) async {
    final prefs = await instance;
    return prefs.getString(key);
  }

  static Future<bool> setString(String key, String value) async {
    final prefs = await instance;
    return await prefs.setString(key, value);
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await instance;
    return prefs.getBool(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    final prefs = await instance;
    return await prefs.setBool(key, value);
  }

  static Future<int?> getInt(String key) async {
    final prefs = await instance;
    return prefs.getInt(key);
  }

  static Future<bool> setInt(String key, int value) async {
    final prefs = await instance;
    return await prefs.setInt(key, value);
  }
}

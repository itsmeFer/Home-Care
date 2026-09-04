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

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<String?> getToken() async {
    final prefs = await instance;
    final token = prefs.getString(keyAuthToken);
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }
    final legacy = prefs.getString(keyLegacyToken);
    if (legacy != null && legacy.trim().isNotEmpty) {
      return legacy.trim();
    }
    return null;
  }

  static Future<bool> saveToken(String token) async {
    final prefs = await instance;
    await prefs.setString(keyLegacyToken, token.trim());
    return await prefs.setString(keyAuthToken, token.trim());
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
    final prefs = await instance;
    await prefs.remove(keyAuthToken);
    await prefs.remove(keyLegacyToken);
    await prefs.remove(keyUserRole);
    await prefs.remove(keyUserId);
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

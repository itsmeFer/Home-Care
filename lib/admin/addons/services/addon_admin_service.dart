import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';

class AddonAdminService {
  static String get baseUrl => ApiConstants.apiBase;

  static Future<Map<String, String>> _authHeaders({bool jsonContent = true}) async {
    final token = await StorageService.getToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception("Token login tidak ditemukan. Silakan login ulang.");
    }

    final headers = <String, String>{
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    if (jsonContent) {
      headers["Content-Type"] = "application/json";
    }

    return headers;
  }

  static Map<String, dynamic>? _safeJson(String source) {
    try {
      return jsonDecode(source) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // ADD-ONS ENDPOINTS
  // -------------------------------------------------------------

  static Future<List<dynamic>> fetchCategoriesDropdown() async {
    final uri = Uri.parse("$baseUrl/admin/addon-categories/all");
    final res = await http
        .get(uri, headers: await _authHeaders())
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body["data"] ?? [];
    }
    throw Exception("Gagal ambil kategori dropdown (${res.statusCode})");
  }

  static Future<Map<String, dynamic>> fetchAddons({
    int page = 1,
    int perPage = 15,
    String? q,
    int? categoryId,
    int? isActive,
  }) async {
    final params = <String, String>{
      "per_page": perPage.toString(),
      "page": page.toString(),
    };
    if (q != null && q.trim().isNotEmpty) params["q"] = q.trim();
    if (categoryId != null) params["category_id"] = categoryId.toString();
    if (isActive != null) params["is_active"] = isActive.toString();

    final uri = Uri.parse("$baseUrl/admin/addons").replace(queryParameters: params);
    final res = await http
        .get(uri, headers: await _authHeaders())
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body["data"] ?? {};
    }
    throw Exception("Gagal ambil add-ons (${res.statusCode})");
  }

  static Future<void> toggleAddon(int id, bool newValue) async {
    final uri = Uri.parse("$baseUrl/admin/addons/$id/toggle");
    final res = await http
        .patch(
          uri,
          headers: await _authHeaders(),
          body: jsonEncode({"aktif": newValue}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception("Gagal toggle status (${res.statusCode})");
    }
  }

  static Future<void> deleteAddon(int id) async {
    final uri = Uri.parse("$baseUrl/admin/addons/$id");
    final res = await http
        .delete(uri, headers: await _authHeaders())
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception("Gagal hapus add-on (${res.statusCode})");
    }
  }

  static Future<String> submitAddon({
    required bool isEdit,
    int? id,
    required Map<String, String> fields,
    bool removeGambar = false,
    XFile? pickedImage,
  }) async {
    final uri = Uri.parse(isEdit ? "$baseUrl/admin/addons/$id" : "$baseUrl/admin/addons");
    final req = http.MultipartRequest("POST", uri);
    if (isEdit) req.fields["_method"] = "PUT";

    req.fields.addAll(fields);
    if (isEdit) {
      req.fields["remove_gambar"] = removeGambar ? "1" : "0";
    }

    if (pickedImage != null) {
      req.files.add(await http.MultipartFile.fromPath("gambar", pickedImage.path));
    }

    final headers = await _authHeaders(jsonContent: false);
    req.headers.addAll(headers);

    final streamed = await req.send().timeout(const Duration(seconds: 25));
    final res = await http.Response.fromStream(streamed).timeout(const Duration(seconds: 25));
    final body = _safeJson(res.body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return body?["message"]?.toString() ?? "Sukses";
    }
    throw Exception(body?["message"]?.toString() ?? "Gagal simpan (${res.statusCode})");
  }

  // -------------------------------------------------------------
  // CATEGORIES ENDPOINTS
  // -------------------------------------------------------------

  static Future<Map<String, dynamic>> fetchCategoryCrud({
    int page = 1,
    int perPage = 15,
    String? q,
    int? isActive,
  }) async {
    final params = <String, String>{
      "per_page": perPage.toString(),
      "page": page.toString(),
    };
    if (q != null && q.trim().isNotEmpty) params["q"] = q.trim();
    if (isActive != null) params["is_active"] = isActive.toString();

    final uri = Uri.parse("$baseUrl/admin/addon-categories").replace(queryParameters: params);
    final res = await http
        .get(uri, headers: await _authHeaders())
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body["data"] ?? {};
    }
    throw Exception("Gagal ambil kategori (${res.statusCode})");
  }

  static Future<String> createCategory(Map<String, dynamic> payload) async {
    final uri = Uri.parse("$baseUrl/admin/addon-categories");
    final res = await http
        .post(uri, headers: await _authHeaders(), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));
    final body = _safeJson(res.body);

    if (res.statusCode == 201 || res.statusCode == 200) {
      return body?["message"]?.toString() ?? "Kategori dibuat";
    }
    throw Exception(body?["message"]?.toString() ?? "Gagal create (${res.statusCode})");
  }

  static Future<String> updateCategory(int id, Map<String, dynamic> payload) async {
    final uri = Uri.parse("$baseUrl/admin/addon-categories/$id");
    final res = await http
        .put(uri, headers: await _authHeaders(), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));
    final body = _safeJson(res.body);

    if (res.statusCode == 200) {
      return body?["message"]?.toString() ?? "Kategori diupdate";
    }
    throw Exception(body?["message"]?.toString() ?? "Gagal update (${res.statusCode})");
  }

  static Future<String> deleteCategory(int id) async {
    final uri = Uri.parse("$baseUrl/admin/addon-categories/$id");
    final res = await http
        .delete(uri, headers: await _authHeaders())
        .timeout(const Duration(seconds: 15));
    final body = _safeJson(res.body);

    if (res.statusCode == 200) {
      return body?["message"]?.toString() ?? "Kategori dihapus";
    }
    throw Exception(body?["message"]?.toString() ?? "Gagal hapus (${res.statusCode})");
  }

  static Future<String> toggleCategory(int id, bool newValue) async {
    final uri = Uri.parse("$baseUrl/admin/addon-categories/$id/toggle");
    final res = await http
        .patch(
          uri,
          headers: await _authHeaders(),
          body: jsonEncode({"is_active": newValue}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _safeJson(res.body);

    if (res.statusCode == 200) {
      return body?["message"]?.toString() ?? "Status kategori diubah";
    }
    throw Exception(body?["message"]?.toString() ?? "Gagal toggle (${res.statusCode})");
  }

  static Future<String> reorderCategories(List<Map<String, dynamic>> items) async {
    final uri = Uri.parse("$baseUrl/admin/addon-categories/reorder");
    final res = await http
        .post(uri, headers: await _authHeaders(), body: jsonEncode({"items": items}))
        .timeout(const Duration(seconds: 15));
    final body = _safeJson(res.body);

    if (res.statusCode == 200) {
      return body?["message"]?.toString() ?? "Urutan kategori diupdate";
    }
    throw Exception(body?["message"]?.toString() ?? "Gagal reorder (${res.statusCode})");
  }
}

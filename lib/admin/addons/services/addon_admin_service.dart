import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:home_care/admin/addons/models/addon_admin_model.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service tersentralisasi untuk manajemen Add-ons dan Kategori di Admin Panel.
/// Menggunakan `ApiClient` (terintegrasi token otomatis, 401 auto-logout, timeout 25s).
class AddonAdminService {
  AddonAdminService._();

  // -------------------------------------------------------------
  // ADD-ONS ENDPOINTS
  // -------------------------------------------------------------

  /// Mengambil daftar kategori untuk dropdown form.
  static Future<List<AddonCategoryItem>> fetchCategoriesDropdown() async {
    final res = await ApiClient.get('/admin/addon-categories/all');
    if (res is Map && res['data'] is List) {
      final List list = res['data'] as List;
      return list
          .whereType<Map>()
          .map((e) => AddonCategoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  /// Mengambil list add-on dengan filter dan pagination strongly-typed.
  static Future<AddonPaginationResult<AddonItem>> fetchAddons({
    int page = 1,
    int perPage = 15,
    String? q,
    int? categoryId,
    int? isActive,
  }) async {
    final queryParams = <String, dynamic>{
      'per_page': perPage.toString(),
      'page': page.toString(),
    };
    if (q != null && q.trim().isNotEmpty) queryParams['q'] = q.trim();
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    final res = await ApiClient.get(
      '/admin/addons',
      queryParams: queryParams,
    );

    if (res is Map && res['data'] is Map) {
      final pageData = res['data'] as Map<String, dynamic>;
      final rawList = pageData['data'] as List? ?? [];
      final items = rawList
          .whereType<Map>()
          .map((e) => AddonItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return AddonPaginationResult<AddonItem>(
        items: items,
        currentPage: int.tryParse(pageData['current_page']?.toString() ?? '1') ?? 1,
        lastPage: int.tryParse(pageData['last_page']?.toString() ?? '1') ?? 1,
        total: int.tryParse(pageData['total']?.toString() ?? '0') ?? 0,
        perPage: int.tryParse(pageData['per_page']?.toString() ?? '$perPage') ?? perPage,
      );
    }

    return AddonPaginationResult<AddonItem>(
      items: [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
      perPage: perPage,
    );
  }

  /// Mengubah status aktif/nonaktif add-on.
  static Future<void> toggleAddon(int id, bool newValue) async {
    await ApiClient.patch(
      '/admin/addons/$id/toggle',
      body: {'aktif': newValue},
    );
  }

  /// Menghapus add-on berdasarkan ID.
  static Future<void> deleteAddon(int id) async {
    await ApiClient.delete('/admin/addons/$id');
  }

  /// Membuat atau memperbarui Add-on (mendukung multipart foto dan kompresi byte).
  static Future<String> submitAddon({
    required bool isEdit,
    int? id,
    required Map<String, String> fields,
    bool removeGambar = false,
    Uint8List? compressedImageBytes,
    String? fileName,
    XFile? fallbackFile,
  }) async {
    final path = isEdit ? '/admin/addons/$id' : '/admin/addons';
    final uri = Uri.parse('${ApiConstants.apiBase}$path');
    final req = http.MultipartRequest('POST', uri);

    if (isEdit) {
      req.fields['_method'] = 'PUT';
      req.fields['remove_gambar'] = removeGambar ? '1' : '0';
    }

    req.fields.addAll(fields);

    // Lampirkan gambar (prioritaskan byte terkompresi)
    if (compressedImageBytes != null && fileName != null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'gambar',
          compressedImageBytes,
          filename: fileName,
        ),
      );
    } else if (fallbackFile != null) {
      final bytes = await fallbackFile.readAsBytes();
      req.files.add(
        http.MultipartFile.fromBytes(
          'gambar',
          bytes,
          filename: fallbackFile.name,
        ),
      );
    }

    final res = await ApiClient.sendMultipart(req);
    if (res is Map) {
      return res['message']?.toString() ?? 'Data Add-on berhasil disimpan';
    }
    return 'Data Add-on berhasil disimpan';
  }

  // -------------------------------------------------------------
  // CATEGORIES ENDPOINTS
  // -------------------------------------------------------------

  /// Mengambil daftar kategori dengan pagination dan pencarian.
  static Future<AddonPaginationResult<AddonCategoryItem>> fetchCategoryCrud({
    int page = 1,
    int perPage = 15,
    String? q,
    int? isActive,
  }) async {
    final queryParams = <String, dynamic>{
      'per_page': perPage.toString(),
      'page': page.toString(),
    };
    if (q != null && q.trim().isNotEmpty) queryParams['q'] = q.trim();
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    final res = await ApiClient.get(
      '/admin/addon-categories',
      queryParams: queryParams,
    );

    if (res is Map && res['data'] is Map) {
      final pageData = res['data'] as Map<String, dynamic>;
      final rawList = pageData['data'] as List? ?? [];
      final items = rawList
          .whereType<Map>()
          .map((e) => AddonCategoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return AddonPaginationResult<AddonCategoryItem>(
        items: items,
        currentPage: int.tryParse(pageData['current_page']?.toString() ?? '1') ?? 1,
        lastPage: int.tryParse(pageData['last_page']?.toString() ?? '1') ?? 1,
        total: int.tryParse(pageData['total']?.toString() ?? '0') ?? 0,
        perPage: int.tryParse(pageData['per_page']?.toString() ?? '$perPage') ?? perPage,
      );
    }

    return AddonPaginationResult<AddonCategoryItem>(
      items: [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
      perPage: perPage,
    );
  }

  /// Membuat kategori baru.
  static Future<String> createCategory(Map<String, dynamic> payload) async {
    final res = await ApiClient.post('/admin/addon-categories', body: payload);
    if (res is Map) {
      return res['message']?.toString() ?? 'Kategori berhasil dibuat';
    }
    return 'Kategori berhasil dibuat';
  }

  /// Memperbarui kategori yang ada.
  static Future<String> updateCategory(int id, Map<String, dynamic> payload) async {
    final res = await ApiClient.put('/admin/addon-categories/$id', body: payload);
    if (res is Map) {
      return res['message']?.toString() ?? 'Kategori berhasil diperbarui';
    }
    return 'Kategori berhasil diperbarui';
  }

  /// Menghapus kategori.
  static Future<String> deleteCategory(int id) async {
    final res = await ApiClient.delete('/admin/addon-categories/$id');
    if (res is Map) {
      return res['message']?.toString() ?? 'Kategori berhasil dihapus';
    }
    return 'Kategori berhasil dihapus';
  }

  /// Mengubah status aktif kategori.
  static Future<String> toggleCategory(int id, bool newValue) async {
    final res = await ApiClient.patch(
      '/admin/addon-categories/$id/toggle',
      body: {'is_active': newValue},
    );
    if (res is Map) {
      return res['message']?.toString() ?? 'Status kategori berhasil diubah';
    }
    return 'Status kategori berhasil diubah';
  }

  /// Menyimpan urutan baru kategori (Reorder).
  static Future<String> reorderCategories(List<Map<String, dynamic>> items) async {
    final res = await ApiClient.post(
      '/admin/addon-categories/reorder',
      body: {'items': items},
    );
    if (res is Map) {
      return res['message']?.toString() ?? 'Urutan kategori berhasil disimpan';
    }
    return 'Urutan kategori berhasil disimpan';
  }
}

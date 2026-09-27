import 'package:home_care/core/constants/api_constants.dart';

/// DTO Model untuk Item Add-on pada Admin Panel.
class AddonItem {
  final int id;
  final String kodeAddon;
  final String namaAddon;
  final String deskripsi;
  final double hargaFix;
  final String? hargaFixFormatted;
  final bool isQtyEnabled;
  final bool aktif;
  final int? addonCategoryId;
  final String? categoryName;
  final String? gambarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const AddonItem({
    required this.id,
    this.kodeAddon = '',
    required this.namaAddon,
    required this.deskripsi,
    required this.hargaFix,
    this.hargaFixFormatted,
    required this.isQtyEnabled,
    required this.aktif,
    this.addonCategoryId,
    this.categoryName,
    this.gambarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory AddonItem.fromJson(Map<String, dynamic> json) {
    // Parsing harga fleksibel (bisa num, string, atau null)
    double parsedHarga = 0.0;
    final rawHarga = json['harga_fix_raw'] ?? json['harga_fix'] ?? json['harga'];
    if (rawHarga is num) {
      parsedHarga = rawHarga.toDouble();
    } else if (rawHarga is String) {
      parsedHarga = double.tryParse(rawHarga) ?? 0.0;
    }

    // Parsing status aktif & qty
    final bool parsedAktif = json['aktif'] == true ||
        json['aktif'] == 1 ||
        json['aktif'] == '1' ||
        json['is_active'] == true ||
        json['is_active'] == 1;

    final bool parsedQty = json['is_qty_enabled'] == true ||
        json['is_qty_enabled'] == 1 ||
        json['is_qty_enabled'] == '1';

    // Parsing kategori
    int? catId;
    String? catName;
    if (json['addon_category_id'] != null) {
      catId = int.tryParse(json['addon_category_id'].toString());
    }
    if (json['category'] is Map) {
      final catMap = json['category'] as Map<String, dynamic>;
      catId ??= int.tryParse(catMap['id']?.toString() ?? '');
      catName = catMap['name']?.toString();
    } else if (json['category_name'] != null) {
      catName = json['category_name']?.toString();
    }

    // Parsing gambar
    final rawGambar = json['gambar_url'] ?? json['gambar'];
    final String? fullGambar = rawGambar != null && rawGambar.toString().isNotEmpty
        ? ApiConstants.resolveMediaUrl(rawGambar.toString())
        : null;

    return AddonItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kodeAddon: json['kode_addon']?.toString() ?? '',
      namaAddon: json['nama_addon']?.toString() ?? json['nama']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString() ?? '',
      hargaFix: parsedHarga,
      hargaFixFormatted: json['harga_fix_formatted']?.toString(),
      isQtyEnabled: parsedQty,
      aktif: parsedAktif,
      addonCategoryId: catId,
      categoryName: catName,
      gambarUrl: fullGambar,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode_addon': kodeAddon,
      'nama_addon': namaAddon,
      'deskripsi': deskripsi,
      'harga_fix_raw': hargaFix,
      'addon_category_id': addonCategoryId,
      'is_qty_enabled': isQtyEnabled,
      'aktif': aktif,
      'gambar_url': gambarUrl,
    };
  }

  AddonItem copyWith({
    int? id,
    String? kodeAddon,
    String? namaAddon,
    String? deskripsi,
    double? hargaFix,
    String? hargaFixFormatted,
    bool? isQtyEnabled,
    bool? aktif,
    int? addonCategoryId,
    String? categoryName,
    String? gambarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddonItem(
      id: id ?? this.id,
      kodeAddon: kodeAddon ?? this.kodeAddon,
      namaAddon: namaAddon ?? this.namaAddon,
      deskripsi: deskripsi ?? this.deskripsi,
      hargaFix: hargaFix ?? this.hargaFix,
      hargaFixFormatted: hargaFixFormatted ?? this.hargaFixFormatted,
      isQtyEnabled: isQtyEnabled ?? this.isQtyEnabled,
      aktif: aktif ?? this.aktif,
      addonCategoryId: addonCategoryId ?? this.addonCategoryId,
      categoryName: categoryName ?? this.categoryName,
      gambarUrl: gambarUrl ?? this.gambarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// DTO Model untuk Kategori Add-on pada Admin Panel.
class AddonCategoryItem {
  final int id;
  final String name;
  final String description;
  final bool isActive;
  final int orderPos;
  final int addonsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AddonCategoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    this.orderPos = 0,
    this.addonsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory AddonCategoryItem.fromJson(Map<String, dynamic> json) {
    final bool parsedActive = json['is_active'] == true ||
        json['is_active'] == 1 ||
        json['is_active'] == '1' ||
        json['aktif'] == true ||
        json['aktif'] == 1;

    return AddonCategoryItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? json['nama']?.toString() ?? '',
      description: json['description']?.toString() ?? json['deskripsi']?.toString() ?? '',
      isActive: parsedActive,
      orderPos: int.tryParse(json['order_pos']?.toString() ?? '0') ?? 0,
      addonsCount: int.tryParse(json['addons_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'order_pos': orderPos,
    };
  }

  AddonCategoryItem copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
    int? orderPos,
    int? addonsCount,
  }) {
    return AddonCategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      orderPos: orderPos ?? this.orderPos,
      addonsCount: addonsCount ?? this.addonsCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Generic Pagination Wrapper untuk Data Add-on dan Kategori.
class AddonPaginationResult<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  const AddonPaginationResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  bool get hasNextPage => currentPage < lastPage;
  bool get isEmpty => items.isEmpty;
}

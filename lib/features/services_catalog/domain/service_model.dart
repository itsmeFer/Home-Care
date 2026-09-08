import 'package:home_care/core/constants/api_constants.dart';

export 'package:home_care/features/orders/domain/addon_model.dart';

/// Canonical Service Model untuk seluruh aplikasi HomeCare.
/// Mengonsolidasi duplikasi model Layanan dari modul User, Admin, Banners, dan Fee Management.
class ServiceModel {
  final int id;
  final String kodeLayanan;
  final String namaLayanan;
  final String? deskripsi;
  final String? kategori;
  final String tipeLayanan;
  final int? jumlahVisit;
  final double hargaFix;
  final int? durasiMenit;
  final String? syaratPerawat;
  final String? lokasiTersedia;
  final bool aktif;
  final String? gambarUrl;
  final String? createdAt;
  final String? updatedAt;

  ServiceModel({
    required this.id,
    required this.kodeLayanan,
    required this.namaLayanan,
    this.deskripsi,
    this.kategori,
    this.tipeLayanan = 'single',
    this.jumlahVisit,
    required this.hargaFix,
    this.durasiMenit,
    this.syaratPerawat,
    this.lokasiTersedia,
    this.aktif = true,
    this.gambarUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Kompatibilitas untuk admin modul yang menggunakan hargaDasar
  double get hargaDasar => hargaFix;

  /// Kompatibilitas untuk modul fee management
  String get nama => namaLayanan;

  String get tipeLayananLabel {
    switch (tipeLayanan.toLowerCase()) {
      case 'paket':
        return 'Paket';
      case 'single':
      default:
        return 'Single';
    }
  }

  String get syaratPerawatLabel {
    switch (syaratPerawat?.toLowerCase()) {
      case 'icu':
        return 'ICU';
      case 'luka':
        return 'Perawat Luka';
      case 'fisio':
        return 'Fisioterapi';
      case 'anak':
        return 'Perawat Anak';
      case 'lainnya':
        return 'Lainnya';
      case 'umum':
      default:
        return 'Umum';
    }
  }

  String get lokasiLabel {
    switch (lokasiTersedia?.toLowerCase()) {
      case 'rumah':
        return 'Rumah';
      case 'rumah_sakit':
        return 'Rumah Sakit';
      case 'keduanya':
      default:
        return 'Rumah & RS';
    }
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    int? parseNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    double parseHarga(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    bool parseBool(dynamic v, {bool defaultValue = true}) {
      if (v == null) return defaultValue;
      if (v is bool) return v;
      final str = v.toString().toLowerCase().trim();
      return str == '1' || str == 'true';
    }

    String? kategoriVal;
    if (json['kategori'] != null) {
      if (json['kategori'] is Map) {
        kategoriVal = (json['kategori']['nama_kategori'] ?? json['kategori']['nama'])?.toString();
      } else {
        kategoriVal = json['kategori']?.toString();
      }
    }

    final rawHarga = json['harga_fix'] ?? json['harga_dasar'] ?? json['harga'];
    final rawGambar = json['gambar_url'] ?? json['gambar'] ?? json['foto'];

    return ServiceModel(
      id: parseId(json['id']),
      kodeLayanan: json['kode_layanan']?.toString() ?? '',
      namaLayanan: (json['nama_layanan'] ?? json['nama'] ?? '').toString(),
      deskripsi: json['deskripsi']?.toString(),
      kategori: kategoriVal,
      tipeLayanan: json['tipe_layanan']?.toString() ?? 'single',
      jumlahVisit: parseNullableInt(json['jumlah_visit']),
      hargaFix: parseHarga(rawHarga),
      durasiMenit: parseNullableInt(json['durasi_menit']),
      syaratPerawat: json['syarat_perawat']?.toString(),
      lokasiTersedia: json['lokasi_tersedia']?.toString(),
      aktif: parseBool(json['aktif'], defaultValue: true),
      gambarUrl: ApiConstants.resolveMediaUrl(rawGambar),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kode_layanan': kodeLayanan,
    'nama_layanan': namaLayanan,
    'deskripsi': deskripsi,
    'kategori': kategori,
    'tipe_layanan': tipeLayanan,
    'jumlah_visit': jumlahVisit,
    'harga_fix': hargaFix,
    'harga_dasar': hargaFix,
    'durasi_menit': durasiMenit,
    'syarat_perawat': syaratPerawat,
    'lokasi_tersedia': lokasiTersedia,
    'aktif': aktif,
    'gambar_url': gambarUrl,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

/// Type aliases untuk mempertahankan backward compatibility 100%
typedef Layanan = ServiceModel;
typedef LayananDetail = ServiceModel;
typedef LayananSearchResult = ServiceModel;
typedef LayananModel = ServiceModel;

/// Canonical Service Category Model
class ServiceCategory {
  final int id;
  final String namaKategori;
  final String slug;
  final String? deskripsi;
  final String? gambarUrl;
  final String? icon;
  final String? warna;
  final int urutan;
  final bool aktif;
  final int jumlahLayanan;

  ServiceCategory({
    required this.id,
    required this.namaKategori,
    required this.slug,
    this.deskripsi,
    this.gambarUrl,
    this.icon,
    this.warna,
    this.urutan = 0,
    this.aktif = true,
    this.jumlahLayanan = 0,
  });

  /// Kompatibilitas dengan home_page.dart (yang menggunakan iconName)
  String? get iconName => icon;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? fallback;
    }

    bool parseBool(dynamic v, {bool fallback = true}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      final str = v.toString().toLowerCase().trim();
      return str == '1' || str == 'true';
    }

    final rawGambar = json['gambar_url'] ?? json['gambar'] ?? json['icon_url'];

    return ServiceCategory(
      id: parseInt(json['id']),
      namaKategori: (json['nama_kategori'] ?? json['nama'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      deskripsi: json['deskripsi']?.toString(),
      gambarUrl: ApiConstants.resolveMediaUrl(rawGambar),
      icon: (json['icon'] ?? json['icon_name'])?.toString(),
      warna: json['warna']?.toString(),
      urutan: parseInt(json['urutan']),
      aktif: parseBool(json['aktif']),
      jumlahLayanan: parseInt(json['jumlah_layanan'] ?? json['layanan_count']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama_kategori': namaKategori,
    'slug': slug,
    'deskripsi': deskripsi,
    'gambar_url': gambarUrl,
    'icon': icon,
    'warna': warna,
    'urutan': urutan,
    'aktif': aktif,
    'jumlah_layanan': jumlahLayanan,
  };
}

typedef LayananCategory = ServiceCategory;
typedef KategoriLayananItem = ServiceCategory;

/// Model Koordinator Layanan untuk kebutuhan mapping koordinator per layanan (Admin)
class KoordinatorItem {
  final int id;
  final String namaLengkap;
  final String? kodeKoordinator;
  final String? wilayah;
  final bool isActive;
  final bool? pivotAktif;
  final String? pivotCatatan;

  KoordinatorItem({
    required this.id,
    required this.namaLengkap,
    this.kodeKoordinator,
    this.wilayah,
    required this.isActive,
    this.pivotAktif,
    this.pivotCatatan,
  });

  factory KoordinatorItem.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'] as Map<String, dynamic>?;
    final koordinator = json['koordinator'] as Map<String, dynamic>?;

    final rawNama = json['nama_lengkap'] ??
        json['nama'] ??
        json['full_name'] ??
        json['name'] ??
        koordinator?['nama_lengkap'] ??
        'Koordinator #${json['id']}';

    final rawIsActive = json['is_active'] ??
        json['aktif'] ??
        koordinator?['is_active'] ??
        koordinator?['aktif'];

    final bool active = rawIsActive == null
        ? true
        : (rawIsActive is bool
            ? rawIsActive
            : rawIsActive.toString() == '1' ||
                rawIsActive.toString().toLowerCase() == 'true');

    bool? pAktif;
    if (pivot != null && pivot['is_active'] != null) {
      final pVal = pivot['is_active'];
      pAktif = pVal is bool
          ? pVal
          : pVal.toString() == '1' || pVal.toString().toLowerCase() == 'true';
    }

    return KoordinatorItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      namaLengkap: rawNama.toString(),
      kodeKoordinator: (json['kode_koordinator'] ??
              koordinator?['kode_koordinator'])
          ?.toString(),
      wilayah: (json['wilayah'] ?? koordinator?['wilayah'])?.toString(),
      isActive: active,
      pivotAktif: pAktif,
      pivotCatatan: pivot?['catatan']?.toString(),
    );
  }
}

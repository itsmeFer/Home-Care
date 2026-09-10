import 'package:home_care/core/constants/api_constants.dart';

num parseNum(dynamic x) {
  if (x == null) return 0;
  if (x is num) return x;
  return num.tryParse(x.toString()) ?? 0;
}

bool parseBool(dynamic x) {
  if (x is bool) return x;
  if (x is num) return x != 0;
  if (x is String) return x == '1' || x.toLowerCase() == 'true';
  return false;
}

class FeeTimelinePoint {
  final DateTime date;
  final double amount;

  FeeTimelinePoint({required this.date, required this.amount});

  factory FeeTimelinePoint.fromJson(Map<String, dynamic> json) {
    return FeeTimelinePoint(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
    );
  }
}

class FeeByLayanan {
  final int layananId;
  final String layananNama;
  final double totalFee;

  FeeByLayanan({
    required this.layananId,
    required this.layananNama,
    required this.totalFee,
  });

  factory FeeByLayanan.fromJson(Map<String, dynamic> json) {
    return FeeByLayanan(
      layananId: json['layanan_id'] is int ? json['layanan_id'] : int.tryParse(json['layanan_id']?.toString() ?? '') ?? 0,
      layananNama: json['layanan_nama']?.toString() ?? '-',
      totalFee: (json['total_fee'] is num) ? (json['total_fee'] as num).toDouble() : double.tryParse(json['total_fee']?.toString() ?? '') ?? 0.0,
    );
  }
}

class LeaderboardItem {
  final int userId;
  final String nama;
  final double totalFee;

  LeaderboardItem({
    required this.userId,
    required this.nama,
    required this.totalFee,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      nama: json['nama']?.toString() ?? 'User',
      totalFee: (json['total_fee'] is num) ? (json['total_fee'] as num).toDouble() : double.tryParse(json['total_fee']?.toString() ?? '') ?? 0.0,
    );
  }
}

class SimpleUserOption {
  final int id;
  final String name;
  final String? email;
  final String? role;

  SimpleUserOption({
    required this.id,
    required this.name,
    this.email,
    this.role,
  });

  factory SimpleUserOption.fromJson(Map<String, dynamic> json) {
    return SimpleUserOption(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['display_name']?.toString() ?? json['name']?.toString() ?? 'User',
      email: json['email']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class Layanan {
  final int id;
  final String nama;
  final num hargaFix;
  final String? gambarUrl;

  Layanan({
    required this.id,
    required this.nama,
    required this.hargaFix,
    required this.gambarUrl,
  });

  factory Layanan.fromJson(Map<String, dynamic> j) => Layanan(
    id: (j['id'] as num).toInt(),
    nama: (j['nama_layanan'] ?? j['nama'] ?? '').toString(),
    hargaFix: parseNum(j['harga_fix']),
    gambarUrl: ApiConstants.resolveMediaUrl(j['gambar_url'] ?? j['gambar']),
  );
}

class Addon {
  final int id;
  final String nama;
  final num hargaFix;
  final String? gambarUrl;

  Addon({
    required this.id,
    required this.nama,
    required this.hargaFix,
    required this.gambarUrl,
  });

  factory Addon.fromJson(Map<String, dynamic> j) => Addon(
    id: (j['id'] as num).toInt(),
    nama: (j['nama_addon'] ?? j['nama'] ?? '').toString(),
    hargaFix: parseNum(j['harga_fix']),
    gambarUrl: ApiConstants.resolveMediaUrl(j['gambar_url'] ?? j['gambar']),
  );
}

class RoleOption {
  final int id;
  final String name;
  final String slug;

  RoleOption({required this.id, required this.name, required this.slug});

  factory RoleOption.fromJson(Map<String, dynamic> j) => RoleOption(
    id: (j['id'] as num).toInt(),
    name: (j['name'] ?? '').toString(),
    slug: (j['slug'] ?? '').toString(),
  );
}

class SelectableUser {
  final int id;
  final String role;
  final String email;
  final String displayName;
  final String? noHp;
  final String? fotoUrl;

  SelectableUser({
    required this.id,
    required this.role,
    required this.email,
    required this.displayName,
    required this.noHp,
    required this.fotoUrl,
  });

  factory SelectableUser.fromJson(Map<String, dynamic> j) => SelectableUser(
    id: (j['id'] as num).toInt(),
    role: (j['role'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
    displayName: (j['display_name'] ?? j['name'] ?? '').toString(),
    noHp: j['no_hp']?.toString(),
    fotoUrl: ApiConstants.resolveMediaUrl(j['foto_url'] ?? j['avatar_url'] ?? j['foto']),
  );
}

class FeeRule {
  final int id;
  final int? layananId;
  final int? addonId;
  final int? userId;
  final String namaPenerima;
  final String? emailPenerima;
  final String? noHpPenerima;
  final String? bankNama;
  final String? bankKode;
  final String? noRekening;
  final String? atasNamaRekening;
  final num percent;
  final bool isActive;
  final String? fotoUrl;

  FeeRule({
    required this.id,
    this.layananId,
    this.addonId,
    required this.userId,
    required this.namaPenerima,
    required this.emailPenerima,
    required this.noHpPenerima,
    required this.bankNama,
    required this.bankKode,
    required this.noRekening,
    required this.atasNamaRekening,
    required this.percent,
    required this.isActive,
    required this.fotoUrl,
  });

  factory FeeRule.fromJson(Map<String, dynamic> j) {
    final user =
        (j['user'] is Map) ? (j['user'] as Map<String, dynamic>) : null;
    final rawFoto =
        j['foto_url'] ??
        j['avatar_url'] ??
        j['foto'] ??
        user?['foto_url'] ??
        user?['avatar_url'] ??
        user?['foto'] ??
        user?['gambar'] ??
        user?['photo'];

    return FeeRule(
      id: (j['id'] as num).toInt(),
      layananId:
          j['layanan_id'] == null ? null : (j['layanan_id'] as num).toInt(),
      addonId: j['addon_id'] == null ? null : (j['addon_id'] as num).toInt(),
      userId: j['user_id'] == null ? null : (j['user_id'] as num).toInt(),
      namaPenerima: (j['nama_penerima'] ?? '').toString(),
      emailPenerima: j['email_penerima']?.toString(),
      noHpPenerima: j['no_hp_penerima']?.toString(),
      bankNama: j['bank_nama']?.toString(),
      bankKode: j['bank_kode']?.toString(),
      noRekening: j['no_rekening']?.toString(),
      atasNamaRekening: j['atas_nama_rekening']?.toString(),
      percent: parseNum(j['percent']),
      isActive: parseBool(j['is_active']),
      fotoUrl: ApiConstants.resolveMediaUrl(rawFoto),
    );
  }
}

class FeeSimItem {
  final int id;
  final int? userId;
  final String nama;
  final String? fotoUrl;
  final num percent;
  final num nominal;
  final String? bankNama;
  final String? noRekening;
  final String? atasNama;

  FeeSimItem({
    required this.id,
    required this.userId,
    required this.nama,
    required this.fotoUrl,
    required this.percent,
    required this.nominal,
    required this.bankNama,
    required this.noRekening,
    required this.atasNama,
  });

  factory FeeSimItem.fromJson(Map<String, dynamic> j) => FeeSimItem(
    id: (j['id'] as num).toInt(),
    userId: j['user_id'] == null ? null : (j['user_id'] as num).toInt(),
    nama: (j['nama_penerima'] ?? '').toString(),
    fotoUrl: ApiConstants.resolveMediaUrl(j['foto_url'] ?? j['avatar_url'] ?? j['foto']),
    percent: parseNum(j['percent']),
    nominal: parseNum(j['nominal']),
    bankNama: j['bank_nama']?.toString(),
    noRekening: j['no_rekening']?.toString(),
    atasNama: j['atas_nama_rekening']?.toString(),
  );
}

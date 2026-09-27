import 'package:home_care/core/constants/api_constants.dart';

class Koordinator {
  final int? id;
  final String? kodeKoordinator;
  final String? namaLengkap;
  final String? email;
  final String? nik;
  final bool? isActive;
  final String? noHp;
  final String? jabatan;
  final String? wilayah;
  final String? alamat;
  final String? foto;

  const Koordinator({
    this.id,
    this.kodeKoordinator,
    this.namaLengkap,
    this.email,
    this.nik,
    this.isActive,
    this.noHp,
    this.jabatan,
    this.wilayah,
    this.alamat,
    this.foto,
  });

  factory Koordinator.fromJson(Map<String, dynamic> json) {
    final profil = json['koordinator'] as Map<String, dynamic>?;

    final dynamic fotoRaw = profil?['foto_url'] ?? profil?['foto'];
    final String? fullFoto = ApiConstants.resolveMediaUrl(fotoRaw);

    return Koordinator(
      id: json['id'] as int?,
      kodeKoordinator: profil?['kode_koordinator']?.toString(),
      namaLengkap: (profil?['nama_lengkap'] ?? json['name'])?.toString(),
      email: json['email']?.toString(),
      nik: profil?['nik']?.toString(),
      isActive: profil == null || !profil.containsKey('is_active')
          ? null
          : (profil['is_active'] is bool
              ? profil['is_active'] as bool
              : profil['is_active'].toString() == '1'),
      noHp: profil?['no_hp']?.toString(),
      jabatan: profil?['jabatan']?.toString(),
      wilayah: profil?['wilayah']?.toString(),
      alamat: profil?['alamat']?.toString(),
      foto: fullFoto,
    );
  }

  Koordinator copyWith({
    int? id,
    String? kodeKoordinator,
    String? namaLengkap,
    String? email,
    String? nik,
    bool? isActive,
    String? noHp,
    String? jabatan,
    String? wilayah,
    String? alamat,
    String? foto,
  }) {
    return Koordinator(
      id: id ?? this.id,
      kodeKoordinator: kodeKoordinator ?? this.kodeKoordinator,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      nik: nik ?? this.nik,
      isActive: isActive ?? this.isActive,
      noHp: noHp ?? this.noHp,
      jabatan: jabatan ?? this.jabatan,
      wilayah: wilayah ?? this.wilayah,
      alamat: alamat ?? this.alamat,
      foto: foto ?? this.foto,
    );
  }

  String? get inisial {
    if (namaLengkap == null || namaLengkap!.trim().isEmpty) return null;
    final parts = namaLengkap!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

import 'package:home_care/core/constants/api_constants.dart';

class Koordinator {
  final int? id;
  final String? namaLengkap;
  final String? email;
  final bool? isActive;
  final String? noHp;
  final String? wilayah;
  final String? alamat;
  final String? foto;

  Koordinator({
    this.id,
    this.namaLengkap,
    this.email,
    this.isActive,
    this.noHp,
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
      namaLengkap: (profil?['nama_lengkap'] ?? json['name'])?.toString(),
      email: json['email']?.toString(),
      isActive:
          profil == null || !profil.containsKey('is_active')
              ? null
              : (profil['is_active'] is bool
                  ? profil['is_active'] as bool
                  : profil['is_active'].toString() == '1'),
      noHp: profil?['no_hp']?.toString(),
      wilayah: profil?['wilayah']?.toString(),
      alamat: profil?['alamat']?.toString(),
      foto: fullFoto,
    );
  }

  String? get inisial {
    if (namaLengkap == null || namaLengkap!.isEmpty) return null;
    final parts = namaLengkap!.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

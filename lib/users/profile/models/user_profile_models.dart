import 'package:home_care/core/constants/api_constants.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      phone: json['phone']?.toString() ?? json['no_hp']?.toString(),
      avatar: json['avatar']?.toString() ?? json['foto_profil']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
    'avatar': avatar,
  };
}

class PasienModel {
  final int id;
  final int userId;
  final String? namaLengkap;
  final String? noRekamMedis;
  final String? nik;
  final String? noHp;
  final String? email;
  final String? jenisKelamin;
  final DateTime? tanggalLahir;
  final String? tempatLahir;
  final String? alamat;
  final String? provinsi;
  final String? kota;
  final String? kecamatan;
  final String? kelurahan;
  final String? provinsiId;
  final String? kotaId;
  final String? kecamatanId;
  final String? kelurahanId;
  final String? kodePos;
  final String? golonganDarah;
  final String? alergi;
  final String? penyakitMenahun;
  final String? fotoProfil;
  final String? fotoProfilUrl;

  const PasienModel({
    required this.id,
    required this.userId,
    this.namaLengkap,
    this.noRekamMedis,
    this.nik,
    this.noHp,
    this.email,
    this.jenisKelamin,
    this.tanggalLahir,
    this.tempatLahir,
    this.alamat,
    this.provinsi,
    this.kota,
    this.kecamatan,
    this.kelurahan,
    this.provinsiId,
    this.kotaId,
    this.kecamatanId,
    this.kelurahanId,
    this.kodePos,
    this.golonganDarah,
    this.alergi,
    this.penyakitMenahun,
    this.fotoProfil,
    this.fotoProfilUrl,
  });

  factory PasienModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['tanggal_lahir']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    final rawFoto = json['foto_profil_url'] ?? json['foto_profil'];
    String? resolvedUrl;
    if (rawFoto is String && rawFoto.isNotEmpty) {
      resolvedUrl = ApiConstants.resolveMediaUrl(rawFoto);
    }

    return PasienModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      namaLengkap: json['nama_lengkap']?.toString(),
      noRekamMedis: json['no_rekam_medis']?.toString(),
      nik: json['nik']?.toString(),
      noHp: json['no_hp']?.toString(),
      email: json['email']?.toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      tanggalLahir: parsedDate,
      tempatLahir: json['tempat_lahir']?.toString(),
      alamat: json['alamat']?.toString(),
      provinsi: json['provinsi']?.toString(),
      kota: json['kota']?.toString(),
      kecamatan: json['kecamatan']?.toString(),
      kelurahan: json['kelurahan']?.toString(),
      provinsiId: json['provinsi_id']?.toString(),
      kotaId: json['kota_id']?.toString(),
      kecamatanId: json['kecamatan_id']?.toString(),
      kelurahanId: json['kelurahan_id']?.toString(),
      kodePos: json['kode_pos']?.toString(),
      golonganDarah: json['golongan_darah']?.toString(),
      alergi: json['alergi']?.toString(),
      penyakitMenahun: json['penyakit_menahun']?.toString(),
      fotoProfil: json['foto_profil']?.toString(),
      fotoProfilUrl: resolvedUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'nama_lengkap': namaLengkap,
    'no_rekam_medis': noRekamMedis,
    'nik': nik,
    'no_hp': noHp,
    'email': email,
    'jenis_kelamin': jenisKelamin,
    'tanggal_lahir': tanggalLahir?.toIso8601String(),
    'tempat_lahir': tempatLahir,
    'alamat': alamat,
    'provinsi': provinsi,
    'kota': kota,
    'kecamatan': kecamatan,
    'kelurahan': kelurahan,
    'provinsi_id': provinsiId,
    'kota_id': kotaId,
    'kecamatan_id': kecamatanId,
    'kelurahan_id': kelurahanId,
    'kode_pos': kodePos,
    'golongan_darah': golonganDarah,
    'alergi': alergi,
    'penyakit_menahun': penyakitMenahun,
    'foto_profil': fotoProfil,
    'foto_profil_url': fotoProfilUrl,
  };

  bool get isComplete {
    return (namaLengkap != null && namaLengkap!.trim().isNotEmpty) &&
        (noHp != null && noHp!.trim().isNotEmpty) &&
        (jenisKelamin != null && jenisKelamin!.trim().isNotEmpty) &&
        (tanggalLahir != null) &&
        (alamat != null && alamat!.trim().isNotEmpty) &&
        (kecamatan != null && kecamatan!.trim().isNotEmpty) &&
        (kota != null && kota!.trim().isNotEmpty) &&
        (kodePos != null && kodePos!.trim().isNotEmpty);
  }
}

class UserProfileData {
  final UserModel user;
  final PasienModel? pasien;

  const UserProfileData({
    required this.user,
    this.pasien,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'] is Map ? json['user'] as Map<String, dynamic> : <String, dynamic>{};
    final rawPasien = json['pasien'] is Map ? json['pasien'] as Map<String, dynamic> : null;

    return UserProfileData(
      user: UserModel.fromJson(rawUser),
      pasien: rawPasien != null ? PasienModel.fromJson(rawPasien) : null,
    );
  }
}

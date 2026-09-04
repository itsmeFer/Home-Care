import 'package:flutter/material.dart';
import 'package:home_care/core/constants/api_constants.dart';

class PerawatModel {
  final int id;
  final int? userId;
  final String? kodePerawat;
  final String namaLengkap;
  final String? nik;
  final String? jenisKelamin;
  final String? tanggalLahir;
  final String? tempatLahir;
  final String? noHp;
  final String? email;
  final String? profesi;
  final String? keahlian;
  final String? noStr;
  final String? noSip;
  final int tahunPengalaman;
  final String? tempatKerjaTerakhir;
  final String? wilayah;
  final String? alamat;
  final String? kontakDaruratNama;
  final String? kontakDaruratNoHp;
  final String? kontakDaruratHubungan;

  final int? koordinatorId;
  final String? koordinatorNama;
  final String? kodeKoordinator;

  final String statusVerifikasi;
  final String? catatanVerifikasi;
  final String? verifiedAt;
  final bool isActive;

  final double avgRatingPerawat;
  final int totalRatingPerawat;
  final String? foto;
  final String? fotoKtp;
  final String? ijazah;
  final String? strFile;
  final String? sipFile;
  final String? sertifikatBtcls;
  final String? sertifikatPpra;
  final String? sertifikatLainnya;

  PerawatModel({
    required this.id,
    this.userId,
    this.kodePerawat,
    required this.namaLengkap,
    this.nik,
    this.jenisKelamin,
    this.tanggalLahir,
    this.tempatLahir,
    this.noHp,
    this.email,
    this.profesi,
    this.keahlian,
    this.noStr,
    this.noSip,
    this.tahunPengalaman = 0,
    this.tempatKerjaTerakhir,
    this.wilayah,
    this.alamat,
    this.kontakDaruratNama,
    this.kontakDaruratNoHp,
    this.kontakDaruratHubungan,
    this.koordinatorId,
    this.koordinatorNama,
    this.kodeKoordinator,
    required this.statusVerifikasi,
    this.catatanVerifikasi,
    this.verifiedAt,
    this.isActive = true,
    this.avgRatingPerawat = 0,
    this.totalRatingPerawat = 0,
    this.foto,
    this.fotoKtp,
    this.ijazah,
    this.strFile,
    this.sipFile,
    this.sertifikatBtcls,
    this.sertifikatPpra,
    this.sertifikatLainnya,
  });

  String? get inisial {
    if (namaLengkap.trim().isEmpty) return null;
    final parts = namaLengkap.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get labelJenisKelamin {
    if (jenisKelamin == 'L') return 'Laki-laki';
    if (jenisKelamin == 'P') return 'Perempuan';
    return '-';
  }

  String get labelStatusVerifikasi {
    switch (statusVerifikasi.toLowerCase()) {
      case 'verified':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Color get chipColorVerifikasi {
    switch (statusVerifikasi.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  factory PerawatModel.fromJson(Map<String, dynamic> json) {
    final koor = json['koordinator'];
    String? koorNama;
    if (koor is Map) {
      koorNama = (koor['nama_lengkap'] ??
              koor['nama'] ??
              koor['name'] ??
              koor['user']?['name'])
          ?.toString();
    }

    final rawFoto = json['foto_url'] ??
        json['avatar_url'] ??
        json['foto'] ??
        json['user']?['foto_url'] ??
        json['user']?['avatar_url'];

    return PerawatModel(
      id: _toInt(json['id']),
      userId: _toNullableInt(json['user_id']),
      kodePerawat: json['kode_perawat']?.toString(),
      namaLengkap: (json['nama_lengkap'] ?? json['nama'] ?? '').toString(),
      nik: json['nik']?.toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      tanggalLahir: json['tanggal_lahir']?.toString(),
      tempatLahir: json['tempat_lahir']?.toString(),
      noHp: json['no_hp']?.toString(),
      email: (json['email'] ??
              json['email_login_perawat'] ??
              json['user']?['email'])
          ?.toString(),
      profesi: json['profesi']?.toString(),
      keahlian: json['keahlian']?.toString(),
      noStr: json['no_str']?.toString(),
      noSip: json['no_sip']?.toString(),
      tahunPengalaman: _toInt(json['tahun_pengalaman']),
      tempatKerjaTerakhir: json['tempat_kerja_terakhir']?.toString(),
      wilayah: json['wilayah']?.toString(),
      alamat: json['alamat']?.toString(),
      kontakDaruratNama: json['kontak_darurat_nama']?.toString(),
      kontakDaruratNoHp: json['kontak_darurat_no_hp']?.toString(),
      kontakDaruratHubungan: json['kontak_darurat_hubungan']?.toString(),
      koordinatorId: _toNullableInt(json['koordinator_id']),
      koordinatorNama: json['nama_koordinator']?.toString() ?? koorNama,
      kodeKoordinator: json['kode_koordinator']?.toString(),
      statusVerifikasi: (json['status_verifikasi'] ?? 'pending').toString(),
      catatanVerifikasi: json['catatan_verifikasi']?.toString(),
      verifiedAt: json['verified_at']?.toString(),
      isActive: (json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active']?.toString() == '1'),
      avgRatingPerawat: _toDouble(json['avg_rating_perawat']),
      totalRatingPerawat: _toInt(json['total_rating_perawat']),
      foto: ApiConstants.resolveMediaUrl(rawFoto),
      fotoKtp: ApiConstants.resolveMediaUrl(json['foto_ktp']),
      ijazah: ApiConstants.resolveMediaUrl(json['ijazah']),
      strFile: ApiConstants.resolveMediaUrl(json['str_file']),
      sipFile: ApiConstants.resolveMediaUrl(json['sip_file']),
      sertifikatBtcls: ApiConstants.resolveMediaUrl(json['sertifikat_btcls']),
      sertifikatPpra: ApiConstants.resolveMediaUrl(json['sertifikat_ppra']),
      sertifikatLainnya: ApiConstants.resolveMediaUrl(json['sertifikat_lainnya']),
    );
  }

  static int _toInt(dynamic x) {
    if (x == null) return 0;
    if (x is int) return x;
    return int.tryParse('$x') ?? 0;
  }

  static int? _toNullableInt(dynamic x) {
    if (x == null) return null;
    if (x is int) return x;
    return int.tryParse('$x');
  }

  static double _toDouble(dynamic x) {
    if (x == null) return 0.0;
    if (x is double) return x;
    if (x is int) return x.toDouble();
    return double.tryParse('$x') ?? 0.0;
  }
}

typedef Perawat = PerawatModel;

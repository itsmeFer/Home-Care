import 'dart:io';
import 'package:flutter/foundation.dart';

class KategoriLayanan {
  final int? id;
  final String? namaKategori;
  final String? slug;
  final String? deskripsi;
  final String? gambar;
  final String? gambarUrl;
  final String? icon;
  final String? warna;
  final int? urutan;
  final bool? aktif;
  final int? createdBy;
  final int? updatedBy;

  KategoriLayanan({
    this.id,
    this.namaKategori,
    this.slug,
    this.deskripsi,
    this.gambar,
    this.gambarUrl,
    this.icon,
    this.warna,
    this.urutan,
    this.aktif,
    this.createdBy,
    this.updatedBy,
  });

  factory KategoriLayanan.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());

    bool? toBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      return v.toString() == '1' || v.toString().toLowerCase() == 'true';
    }

    return KategoriLayanan(
      id: toInt(json['id']),
      namaKategori: json['nama_kategori']?.toString(),
      slug: json['slug']?.toString(),
      deskripsi: json['deskripsi']?.toString(),
      gambar: json['gambar']?.toString(),
      gambarUrl: json['gambar_url']?.toString(),
      icon: json['icon']?.toString(),
      warna: json['warna']?.toString(),
      urutan: toInt(json['urutan']),
      aktif: toBool(json['aktif']),
      createdBy: toInt(json['created_by']),
      updatedBy: toInt(json['updated_by']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_kategori': namaKategori,
      'slug': slug,
      'deskripsi': deskripsi,
      'gambar': gambar,
      'gambar_url': gambarUrl,
      'icon': icon,
      'warna': warna,
      'urutan': urutan,
      'aktif': aktif,
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }
}

class KategoriFormResult {
  final Map<String, dynamic> payload;
  final File? imageFile;
  final Uint8List? imageBytes;
  final String? imageName;

  KategoriFormResult({
    required this.payload,
    this.imageFile,
    this.imageBytes,
    this.imageName,
  });
}

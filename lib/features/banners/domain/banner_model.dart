import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:home_care/core/utils/app_formatters.dart';

class CurrencyFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    int value = int.parse(digitsOnly);
    String formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

double parseRupiah(String text) {
  if (text.isEmpty) return 0;
  String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
  return double.tryParse(digitsOnly) ?? 0;
}

String formatRupiah(double value) => AppFormatters.formatRupiah(value);

class LayananModel {
  final int id;
  final String kodeLayanan;
  final String namaLayanan;
  final double hargaFix;
  final String? kategori;
  final String? gambarUrl;

  LayananModel({
    required this.id,
    required this.kodeLayanan,
    required this.namaLayanan,
    required this.hargaFix,
    this.kategori,
    this.gambarUrl,
  });

  factory LayananModel.fromJson(Map<String, dynamic> j) {
    return LayananModel(
      id: j['id'],
      kodeLayanan: j['kode_layanan'] ?? '',
      namaLayanan: j['nama_layanan'] ?? '',
      hargaFix: _safeDouble(j['harga_fix']),
      kategori: j['kategori'],
      gambarUrl: j['gambar_url'],
    );
  }

  static double _safeDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class BannerModel {
  final int id;
  final int? layananId;
  final String? judul;
  final String? subtitle;
  final String? gambarUrl;
  final int urutan;
  final bool aktif;
  final String tipeCard;
  final String tipeDiskon;
  final double nilaiDiskon;
  final double? maxDiskon;
  final String? kodePromo;
  final double minTransaksi;
  final String? teksDiskon;
  final Map<String, dynamic>? layanan;

  BannerModel({
    required this.id,
    this.layananId,
    this.judul,
    this.subtitle,
    this.gambarUrl,
    required this.urutan,
    required this.aktif,
    this.tipeCard = 'landscape',
    this.tipeDiskon = 'none',
    this.nilaiDiskon = 0,
    this.maxDiskon,
    this.kodePromo,
    this.minTransaksi = 0,
    this.teksDiskon,
    this.layanan,
  });

  factory BannerModel.fromJson(Map<String, dynamic> j) {
    return BannerModel(
      id: j['id'],
      layananId: j['layanan_id'],
      judul: j['judul'],
      subtitle: j['subtitle'],
      gambarUrl: j['gambar_url'],
      urutan: j['urutan'] ?? 0,
      aktif: j['aktif'] ?? false,
      tipeCard: j['tipe_card'] ?? 'landscape',
      tipeDiskon: j['tipe_diskon'] ?? 'none',
      nilaiDiskon: _safeDouble(j['nilai_diskon']),
      maxDiskon: j['max_diskon'] != null ? _safeDouble(j['max_diskon']) : null,
      kodePromo: j['kode_promo'],
      minTransaksi: _safeDouble(j['min_transaksi']),
      teksDiskon: j['teks_diskon'],
      layanan: j['layanan'],
    );
  }

  static double _safeDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

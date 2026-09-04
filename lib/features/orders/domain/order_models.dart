import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class OrderLayananItem {
  final int id;
  final String kodeOrder;
  final String statusOrder;
  final String namaLayanan;
  final String? tanggalMulai;
  final String? jamMulai;
  final Map<String, dynamic>? pasien;
  final Map<String, dynamic>? perawat;
  final Map<String, dynamic>? koordinator;

  OrderLayananItem({
    required this.id,
    required this.kodeOrder,
    required this.statusOrder,
    required this.namaLayanan,
    this.tanggalMulai,
    this.jamMulai,
    this.pasien,
    this.perawat,
    this.koordinator,
  });

  factory OrderLayananItem.fromJson(Map<String, dynamic> json) {
    return OrderLayananItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      kodeOrder: json['kode_order']?.toString() ?? '-',
      statusOrder: json['status_order']?.toString() ?? 'pending',
      namaLayanan: json['nama_layanan']?.toString() ??
          (json['layanan']?['nama_layanan']?.toString() ?? '-'),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      jamMulai: json['jam_mulai']?.toString(),
      pasien: json['pasien'] is Map
          ? Map<String, dynamic>.from(json['pasien'] as Map)
          : null,
      perawat: json['perawat'] is Map
          ? Map<String, dynamic>.from(json['perawat'] as Map)
          : null,
      koordinator: json['koordinator'] is Map
          ? Map<String, dynamic>.from(json['koordinator'] as Map)
          : null,
    );
  }
}

typedef OrderLayananPerawat = OrderLayananItem;
typedef OrderKoordinator = OrderLayananItem;

class OrderStatusHelper {
  OrderStatusHelper._();

  static String label(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'menunggu_penugasan':
        return 'Menunggu Penugasan';
      case 'mendapatkan_perawat':
        return 'Perawat Ditugaskan';
      case 'sedang_dalam_perjalanan':
        return 'Dalam Perjalanan';
      case 'sampai_ditempat':
        return 'Sampai di Lokasi';
      case 'sedang_berjalan':
        return 'Sedang Berjalan';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return (status ?? '-').replaceAll('_', ' ');
    }
  }

  static Color color(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
      case 'menunggu_penugasan':
        return AppColors.warning;
      case 'mendapatkan_perawat':
      case 'sedang_dalam_perjalanan':
      case 'sampai_ditempat':
      case 'sedang_berjalan':
        return AppColors.info;
      case 'selesai':
        return AppColors.success;
      case 'dibatalkan':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  static Color backgroundColor(String? status) {
    return color(status).withAlpha(30);
  }
}

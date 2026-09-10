import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class OrderHistoryStatusHelper {
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'menunggu_pembayaran':
        return HCColors.pending;
      case 'menunggu_penugasan':
        return HCColors.warning;
      case 'mendapatkan_perawat':
        return Colors.blue;
      case 'sedang_dalam_perjalanan':
        return Colors.indigo;
      case 'sampai_ditempat':
        return Colors.deepPurple;
      case 'selesai':
        return HCColors.success;
      case 'dibatalkan':
        return HCColors.danger;
      case 'expired':
        return HCColors.textMuted;
      default:
        return HCColors.textMuted;
    }
  }

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'menunggu_pembayaran':
        return 'Belum Bayar';
      case 'menunggu_penugasan':
        return 'Penugasan';
      case 'mendapatkan_perawat':
        return 'Ditugaskan';
      case 'sedang_dalam_perjalanan':
        return 'Perjalanan';
      case 'sampai_ditempat':
        return 'Di Lokasi';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'expired':
        return 'Kadaluarsa';
      default:
        return status;
    }
  }

  static Color paymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'belum_bayar':
      case 'gagal':
      case 'expired':
        return HCColors.danger;
      case 'pending':
      case 'menunggu_pembayaran':
        return HCColors.warning;
      case 'dibayar':
      case 'lunas':
        return HCColors.success;
      default:
        return HCColors.textMuted;
    }
  }

  static String paymentStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'belum_bayar':
        return 'Belum Bayar';
      case 'pending':
      case 'menunggu_pembayaran':
        return 'Menunggu Verifikasi';
      case 'dibayar':
        return 'Sudah Dibayar';
      case 'lunas':
        return 'Lunas';
      case 'gagal':
        return 'Gagal';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

/// Model terpadu item pesanan (Order) untuk seluruh role (Pasien, Perawat, Koordinator, Admin).
/// Mengonsolidasi OrderLayananItem, OrderHistory, dan OrderLayananAdmin.
class OrderLayananItem {
  final int id;
  final String kodeOrder;
  final String statusOrder;
  final String statusPembayaran;
  final String namaLayanan;
  final String? tipeLayanan;
  final String? tanggalMulai;
  final String? jamMulai;
  final double totalBayar;
  final String? metodePembayaran;
  final int? qty;
  final String? gambarLayanan;
  final bool isDraft;
  final int? draftId;
  final bool hasRating;
  final String? expiredAt;

  final Map<String, dynamic>? pasien;
  final Map<String, dynamic>? perawat;
  final Map<String, dynamic>? koordinator;
  final Map<String, dynamic>? layanan;
  final List<dynamic>? addons;

  final String? alamatLengkap;
  final String? catatan;
  final int? durasiMenitPerVisit;
  final int? jumlahVisitDipesan;
  final String? createdAt;
  final String? updatedAt;

  OrderLayananItem({
    required this.id,
    required this.kodeOrder,
    required this.statusOrder,
    this.statusPembayaran = 'belum_bayar',
    required this.namaLayanan,
    this.tipeLayanan,
    this.tanggalMulai,
    this.jamMulai,
    this.totalBayar = 0.0,
    this.metodePembayaran,
    this.qty = 1,
    this.gambarLayanan,
    this.isDraft = false,
    this.draftId,
    this.hasRating = false,
    this.expiredAt,
    this.pasien,
    this.perawat,
    this.koordinator,
    this.layanan,
    this.addons,
    this.alamatLengkap,
    this.catatan,
    this.durasiMenitPerVisit,
    this.jumlahVisitDipesan,
    this.createdAt,
    this.updatedAt,
  });

  /// Getter alias gambarUrl
  String? get gambarUrl => gambarLayanan;

  String get statusLabel => OrderStatusHelper.label(statusOrder);
  Color get statusColor => OrderStatusHelper.color(statusOrder);
  Color get statusBgColor => OrderStatusHelper.backgroundColor(statusOrder);

  String get paymentStatusLabel =>
      OrderStatusHelper.paymentLabel(statusPembayaran);
  Color get paymentStatusColor =>
      OrderStatusHelper.paymentColor(statusPembayaran);

  bool get canCancel => OrderStatusHelper.canCancel(statusOrder);
  bool get canRate =>
      OrderStatusHelper.canRate(statusOrder, hasRating: hasRating);

  factory OrderLayananItem.fromJson(Map<String, dynamic> json) {
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

    double parseTotal(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    String? gambar;
    if (json['layanan'] != null && json['layanan'] is Map) {
      gambar = json['layanan']['gambar_url']?.toString();
    }
    gambar ??= json['gambar_layanan']?.toString() ?? json['gambar_url']?.toString();

    final isDraft = json['is_draft'] == true;
    final draftId = parseNullableInt(json['draft_id']);

    bool hasRating = false;
    if (json.containsKey('has_rating') && json['has_rating'] != null) {
      hasRating = json['has_rating'] == true ||
          json['has_rating'] == 1 ||
          json['has_rating'].toString() == '1';
    }

    return OrderLayananItem(
      id: parseId(json['id']),
      kodeOrder: json['kode_order']?.toString() ?? '-',
      statusOrder: json['status_order']?.toString() ?? 'pending',
      statusPembayaran: json['status_pembayaran']?.toString() ?? 'belum_bayar',
      namaLayanan: json['nama_layanan']?.toString() ??
          (json['layanan']?['nama_layanan']?.toString() ?? '-'),
      tipeLayanan: json['tipe_layanan']?.toString(),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      jamMulai: json['jam_mulai']?.toString(),
      totalBayar: parseTotal(json['total_bayar']),
      metodePembayaran: json['metode_pembayaran']?.toString(),
      qty: parseNullableInt(json['qty']) ?? 1,
      gambarLayanan: gambar,
      isDraft: isDraft,
      draftId: draftId,
      hasRating: hasRating,
      expiredAt: json['expired_at']?.toString(),
      pasien: json['pasien'] is Map
          ? Map<String, dynamic>.from(json['pasien'] as Map)
          : null,
      perawat: json['perawat'] is Map
          ? Map<String, dynamic>.from(json['perawat'] as Map)
          : null,
      koordinator: json['koordinator'] is Map
          ? Map<String, dynamic>.from(json['koordinator'] as Map)
          : null,
      layanan: json['layanan'] is Map
          ? Map<String, dynamic>.from(json['layanan'] as Map)
          : null,
      addons: json['addons'] is List ? json['addons'] as List : null,
      alamatLengkap:
          (json['alamat_lengkap'] ?? json['alamat'])?.toString(),
      catatan: json['catatan']?.toString(),
      durasiMenitPerVisit: parseNullableInt(json['durasi_menit_per_visit']),
      jumlahVisitDipesan: parseNullableInt(json['jumlah_visit_dipesan']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kode_order': kodeOrder,
    'status_order': statusOrder,
    'status_pembayaran': statusPembayaran,
    'nama_layanan': namaLayanan,
    'tipe_layanan': tipeLayanan,
    'tanggal_mulai': tanggalMulai,
    'jam_mulai': jamMulai,
    'total_bayar': totalBayar,
    'metode_pembayaran': metodePembayaran,
    'qty': qty,
    'gambar_layanan': gambarLayanan,
    'is_draft': isDraft,
    'draft_id': draftId,
    'has_rating': hasRating,
    'expired_at': expiredAt,
    'pasien': pasien,
    'perawat': perawat,
    'koordinator': koordinator,
    'layanan': layanan,
    'addons': addons,
    'alamat_lengkap': alamatLengkap,
    'catatan': catatan,
    'durasi_menit_per_visit': durasiMenitPerVisit,
    'jumlah_visit_dipesan': jumlahVisitDipesan,
  };
}

/// Type aliases untuk kompatibilitas ke berbagai layer UI
typedef OrderLayananPerawat = OrderLayananItem;
typedef OrderKoordinator = OrderLayananItem;
typedef OrderLayananAdmin = OrderLayananItem;
typedef OrderHistory = OrderLayananItem;

/// Helper untuk label, warna, dan status validasi order
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

  static String paymentLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'sudah_bayar':
      case 'paid':
        return 'Sudah Dibayar';
      case 'menunggu_verifikasi':
        return 'Menunggu Verifikasi';
      case 'kadaluarsa':
      case 'expired':
        return 'Kadaluarsa';
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'belum_bayar':
      case 'unpaid':
      default:
        return 'Belum Bayar';
    }
  }

  static Color paymentColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'sudah_bayar':
      case 'paid':
        return AppColors.success;
      case 'menunggu_verifikasi':
        return AppColors.warning;
      case 'kadaluarsa':
      case 'dibatalkan':
        return AppColors.danger;
      case 'belum_bayar':
      default:
        return AppColors.textSecondary;
    }
  }

  static bool canCancel(String? status) {
    final s = status?.toLowerCase() ?? '';
    return ['pending', 'menunggu_penugasan', 'mendapatkan_perawat'].contains(s);
  }

  static bool canRate(String? status, {bool hasRating = false}) {
    final s = status?.toLowerCase() ?? '';
    return s == 'selesai' && !hasRating;
  }
}

/// Model step tracking untuk progress alur visit perawat
class OrderTrackingStep {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;
  final String? timestamp;

  const OrderTrackingStep({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    this.isCompleted = false,
    this.isActive = false,
    this.timestamp,
  });
}

/// Helper untuk menghasilkan langkah alur pesanan & tracking
class OrderTrackingHelper {
  OrderTrackingHelper._();

  static const List<Map<String, dynamic>> _stepDefinitions = [
    {
      'key': 'pending',
      'title': 'Pesanan Dibuat',
      'description': 'Menunggu konfirmasi pemesanan',
      'icon': IconlyLight.document,
    },
    {
      'key': 'menunggu_penugasan',
      'title': 'Menunggu Penugasan',
      'description': 'Koordinator sedang menugaskan perawat',
      'icon': IconlyLight.search,
    },
    {
      'key': 'mendapatkan_perawat',
      'title': 'Perawat Ditugaskan',
      'description': 'Perawat siap melayani kunjungan',
      'icon': IconlyLight.profile,
    },
    {
      'key': 'sedang_dalam_perjalanan',
      'title': 'Dalam Perjalanan',
      'description': 'Perawat sedang menuju alamat pasien',
      'icon': IconlyLight.send,
    },
    {
      'key': 'sampai_ditempat',
      'title': 'Sampai di Lokasi',
      'description': 'Perawat telah tiba di alamat tujuan',
      'icon': IconlyLight.location,
    },
    {
      'key': 'sedang_berjalan',
      'title': 'Tindakan Berlangsung',
      'description': 'Pelayanan medis sedang dilakukan',
      'icon': IconlyLight.activity,
    },
    {
      'key': 'selesai',
      'title': 'Layanan Selesai',
      'description': 'Pelayanan telah berhasil diselesaikan',
      'icon': IconlyLight.tickSquare,
    },
  ];

  static List<OrderTrackingStep> getTrackingSteps(
    String? currentStatus, {
    Map<String, dynamic>? timestamps,
  }) {
    final status = (currentStatus ?? 'pending').toLowerCase();

    if (status == 'dibatalkan') {
      return [
        OrderTrackingStep(
          key: 'dibatalkan',
          title: 'Pesanan Dibatalkan',
          description: 'Pesanan ini telah dibatalkan',
          icon: IconlyLight.closeSquare,
          isCompleted: true,
          isActive: true,
          timestamp: timestamps?['dibatalkan']?.toString(),
        ),
      ];
    }

    final currentIndex =
        _stepDefinitions.indexWhere((s) => s['key'] == status);
    final activeIdx = currentIndex == -1 ? 0 : currentIndex;

    return _stepDefinitions.asMap().entries.map((entry) {
      final idx = entry.key;
      final def = entry.value;
      final key = def['key'] as String;

      return OrderTrackingStep(
        key: key,
        title: def['title'] as String,
        description: def['description'] as String,
        icon: def['icon'] as IconData,
        isCompleted: idx <= activeIdx,
        isActive: idx == activeIdx,
        timestamp: timestamps?[key]?.toString(),
      );
    }).toList();
  }
}

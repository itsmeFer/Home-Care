import 'package:home_care/core/constants/api_constants.dart';

class KoordinatorOption {
  final int id;
  final String nama;
  final String? wilayah;

  const KoordinatorOption({
    required this.id,
    required this.nama,
    this.wilayah,
  });

  String get displayName =>
      (wilayah == null || wilayah!.isEmpty) ? nama : '$nama - ($wilayah)';

  factory KoordinatorOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return KoordinatorOption(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      nama: json['nama_lengkap']?.toString() ??
          json['nama']?.toString() ??
          '-',
      wilayah: json['wilayah']?.toString(),
    );
  }
}

class OrderDetailPasien {
  final String nama;
  final String? noRekamMedis;
  final String? noHp;
  final String? email;

  const OrderDetailPasien({
    required this.nama,
    this.noRekamMedis,
    this.noHp,
    this.email,
  });

  factory OrderDetailPasien.fromJson(Map<String, dynamic> json) {
    return OrderDetailPasien(
      nama: json['nama']?.toString() ??
          json['nama_lengkap']?.toString() ??
          json['full_name']?.toString() ??
          '-',
      noRekamMedis: json['no_rekam_medis']?.toString(),
      noHp: json['no_hp']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class OrderDetailPerawat {
  final int? id;
  final String nama;

  const OrderDetailPerawat({this.id, required this.nama});

  factory OrderDetailPerawat.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return OrderDetailPerawat(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? ''),
      nama: json['nama']?.toString() ??
          json['nama_lengkap']?.toString() ??
          json['full_name']?.toString() ??
          '-',
    );
  }
}

class OrderDetailKoordinator {
  final int? id;
  final String nama;
  final String? wilayah;
  final String? noHp;

  const OrderDetailKoordinator({
    this.id,
    required this.nama,
    this.wilayah,
    this.noHp,
  });

  factory OrderDetailKoordinator.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return OrderDetailKoordinator(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? ''),
      nama: json['nama']?.toString() ??
          json['nama_lengkap']?.toString() ??
          json['full_name']?.toString() ??
          '-',
      wilayah: json['wilayah']?.toString(),
      noHp: json['no_hp']?.toString(),
    );
  }
}

class OrderDetailPaymentInfo {
  final String? channel;
  final String? buktiPembayaran;

  const OrderDetailPaymentInfo({this.channel, this.buktiPembayaran});

  factory OrderDetailPaymentInfo.fromJson(Map<String, dynamic> json) {
    return OrderDetailPaymentInfo(
      channel: json['channel']?.toString(),
      buktiPembayaran: json['bukti_pembayaran']?.toString(),
    );
  }
}

class OrderDetailAddonItem {
  final String namaAddon;
  final dynamic hargaSatuan;
  final int qty;
  final dynamic subtotal;
  final String? deskripsi;

  const OrderDetailAddonItem({
    required this.namaAddon,
    this.hargaSatuan,
    required this.qty,
    this.subtotal,
    this.deskripsi,
  });

  factory OrderDetailAddonItem.fromJson(Map<String, dynamic> json) {
    final addonDetail = json['addon'] as Map<String, dynamic>?;

    return OrderDetailAddonItem(
      namaAddon: json['nama_addon']?.toString() ??
          addonDetail?['nama_addon']?.toString() ??
          '-',
      hargaSatuan: json['harga_satuan'],
      qty: (json['qty'] is int)
          ? json['qty'] as int
          : int.tryParse(json['qty']?.toString() ?? '1') ?? 1,
      subtotal: json['subtotal'],
      deskripsi: addonDetail?['deskripsi']?.toString(),
    );
  }
}

class OrderLayananDetailAdmin {
  final int id;
  final String kodeOrder;
  final String statusOrder;
  final String statusPembayaran;
  final String namaLayanan;
  final String? tipeLayanan;
  final String? tanggalMulai;
  final String? jamMulai;
  final dynamic durasiMenitPerVisit;
  final dynamic jumlahVisitDipesan;
  final dynamic qty;

  final OrderDetailPasien? pasien;
  final OrderDetailPerawat? perawat;
  final OrderDetailKoordinator? koordinator;
  final int? koordinatorId;

  final String? alamatLengkap;
  final String? kecamatan;
  final String? kota;
  final dynamic latitude;
  final dynamic longitude;
  final String? catatanPasien;

  final dynamic hargaSatuan;
  final dynamic subtotal;
  final dynamic diskon;
  final dynamic biayaTambahan;
  final dynamic addonsTotal;
  final dynamic totalBayar;
  final String? metodePembayaran;
  final String? dibayarPada;
  final OrderDetailPaymentInfo? paymentInfo;

  final List<OrderDetailAddonItem> addons;
  final String? kondisiPasien;
  final String? fotoHadir;
  final String? fotoSelesai;

  const OrderLayananDetailAdmin({
    required this.id,
    required this.kodeOrder,
    required this.statusOrder,
    required this.statusPembayaran,
    required this.namaLayanan,
    this.tipeLayanan,
    this.tanggalMulai,
    this.jamMulai,
    this.durasiMenitPerVisit,
    this.jumlahVisitDipesan,
    this.qty,
    this.pasien,
    this.perawat,
    this.koordinator,
    this.koordinatorId,
    this.alamatLengkap,
    this.kecamatan,
    this.kota,
    this.latitude,
    this.longitude,
    this.catatanPasien,
    this.hargaSatuan,
    this.subtotal,
    this.diskon,
    this.biayaTambahan,
    this.addonsTotal,
    this.totalBayar,
    this.metodePembayaran,
    this.dibayarPada,
    this.paymentInfo,
    this.addons = const [],
    this.kondisiPasien,
    this.fotoHadir,
    this.fotoSelesai,
  });

  static String? resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    var cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConstants.apiBase}/media/$cleanPath';
  }

  factory OrderLayananDetailAdmin.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    final rawKoorId = json['koordinator_id'];
    final koordinatorId = rawKoorId is int
        ? rawKoorId
        : int.tryParse(rawKoorId?.toString() ?? '');

    final pasienMap = json['pasien'] is Map
        ? Map<String, dynamic>.from(json['pasien'] as Map)
        : null;
    final perawatMap = json['perawat'] is Map
        ? Map<String, dynamic>.from(json['perawat'] as Map)
        : null;
    final koordinatorMap = json['koordinator'] is Map
        ? Map<String, dynamic>.from(json['koordinator'] as Map)
        : null;
    final paymentInfoMap = json['payment_info'] is Map
        ? Map<String, dynamic>.from(json['payment_info'] as Map)
        : null;

    final rawAddons = json['order_addons'] as List?;
    final addons = rawAddons != null
        ? rawAddons
            .whereType<Map>()
            .map((e) =>
                OrderDetailAddonItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <OrderDetailAddonItem>[];

    return OrderLayananDetailAdmin(
      id: id,
      kodeOrder: json['kode_order']?.toString() ?? '-',
      statusOrder: json['status_order']?.toString() ?? 'pending',
      statusPembayaran: json['status_pembayaran']?.toString() ?? 'belum_bayar',
      namaLayanan: json['nama_layanan']?.toString() ?? '-',
      tipeLayanan: json['tipe_layanan']?.toString(),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      jamMulai: json['jam_mulai']?.toString(),
      durasiMenitPerVisit: json['durasi_menit_per_visit'],
      jumlahVisitDipesan: json['jumlah_visit_dipesan'],
      qty: json['qty'] ?? 1,
      pasien: pasienMap != null ? OrderDetailPasien.fromJson(pasienMap) : null,
      perawat: perawatMap != null ? OrderDetailPerawat.fromJson(perawatMap) : null,
      koordinator: koordinatorMap != null
          ? OrderDetailKoordinator.fromJson(koordinatorMap)
          : null,
      koordinatorId: koordinatorId,
      alamatLengkap: json['alamat_lengkap']?.toString(),
      kecamatan: json['kecamatan']?.toString(),
      kota: json['kota']?.toString(),
      latitude: json['latitude'],
      longitude: json['longitude'],
      catatanPasien: json['catatan_pasien']?.toString(),
      hargaSatuan: json['harga_satuan'],
      subtotal: json['subtotal'],
      diskon: json['diskon'],
      biayaTambahan: json['biaya_tambahan'],
      addonsTotal: json['addons_total'],
      totalBayar: json['total_bayar'],
      metodePembayaran: json['metode_pembayaran']?.toString(),
      dibayarPada: json['dibayar_pada']?.toString(),
      paymentInfo: paymentInfoMap != null
          ? OrderDetailPaymentInfo.fromJson(paymentInfoMap)
          : null,
      addons: addons,
      kondisiPasien: json['kondisi_pasien']?.toString(),
      fotoHadir: json['foto_hadir']?.toString(),
      fotoSelesai: json['foto_selesai']?.toString(),
    );
  }
}

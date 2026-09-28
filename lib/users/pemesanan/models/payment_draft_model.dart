class PaymentDraftModel {
  final int id;
  final String namaLayanan;
  final String? tanggalMulai;
  final String? jamMulai;
  final String alamatLengkap;
  final int totalBayar;
  final String status;
  final int? orderId;

  const PaymentDraftModel({
    required this.id,
    required this.namaLayanan,
    this.tanggalMulai,
    this.jamMulai,
    required this.alamatLengkap,
    required this.totalBayar,
    required this.status,
    this.orderId,
  });

  factory PaymentDraftModel.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total_bayar'] ?? json['total_harga'] ?? json['total'];
    final parsedTotal = int.tryParse(rawTotal?.toString() ?? '') ?? 0;

    final rawOrderId = json['order_id'];
    final parsedOrderId = int.tryParse(rawOrderId?.toString() ?? '');

    return PaymentDraftModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      namaLayanan: json['nama_layanan']?.toString() ?? 'Layanan',
      tanggalMulai: json['tanggal_mulai']?.toString(),
      jamMulai: json['jam_mulai']?.toString(),
      alamatLengkap: json['alamat_lengkap']?.toString() ?? json['alamat']?.toString() ?? '-',
      totalBayar: parsedTotal,
      status: json['status']?.toString() ?? 'pending',
      orderId: parsedOrderId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama_layanan': namaLayanan,
    'tanggal_mulai': tanggalMulai,
    'jam_mulai': jamMulai,
    'alamat_lengkap': alamatLengkap,
    'total_bayar': totalBayar,
    'status': status,
    'order_id': orderId,
  };
}

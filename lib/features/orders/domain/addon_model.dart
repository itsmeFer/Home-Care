class Addon {
  final int id;
  final String namaAddon;
  final double hargaFix;
  final bool isQtyEnabled;
  int qty;

  Addon({
    required this.id,
    required this.namaAddon,
    required this.hargaFix,
    required this.isQtyEnabled,
    this.qty = 1,
  });

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      id: (json['id'] ?? 0) as int,
      namaAddon: (json['nama_addon'] ?? '').toString(),
      hargaFix: _parseDouble(json['harga_fix']),
      isQtyEnabled:
          json['is_qty_enabled'] == 1 ||
          json['is_qty_enabled'] == true ||
          json['is_qty_enabled'] == '1',
      qty: (json['qty'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama_addon': namaAddon,
    'harga_fix': hargaFix,
    'is_qty_enabled': isQtyEnabled,
    'qty': qty,
  };

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

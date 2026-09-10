import 'package:home_care/features/nurses/domain/nurse_model.dart';

export 'package:home_care/features/nurses/domain/nurse_model.dart';

typedef PerawatAdmin = PerawatModel;

class PerawatDetailModel {
  final PerawatModel perawat;
  final List<KoordinatorItem> koordinatorOptions;

  PerawatDetailModel({
    required this.perawat,
    required this.koordinatorOptions,
  });
}

class KoordinatorItem {
  final int id;
  final String nama;
  final String? kode;
  final String? noHp;
  final bool? isActive;
  final String? emailLogin;

  KoordinatorItem({
    required this.id,
    required this.nama,
    this.kode,
    this.noHp,
    this.isActive,
    this.emailLogin,
  });

  factory KoordinatorItem.fromJson(Map<String, dynamic> j) {
    final nama = (j['nama_lengkap'] ??
            j['nama'] ??
            j['name'] ??
            j['user']?['name'] ??
            'Koordinator #${j['id'] ?? ''}')
        .toString();

    return KoordinatorItem(
      id: (j['id'] ?? 0) is int
          ? (j['id'] ?? 0)
          : int.tryParse('${j['id']}') ?? 0,
      nama: nama,
      kode: j['kode_koordinator']?.toString(),
      noHp: j['no_hp']?.toString(),
      isActive: j['is_active'] == true ||
          j['is_active'] == 1 ||
          j['is_active']?.toString() == '1',
      emailLogin: j['email_login']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'kode_koordinator': kode,
      'no_hp': noHp,
      'is_active': isActive,
      'email_login': emailLogin,
    };
  }
}

class PerawatFormResult {
  final Map<String, dynamic> payload;
  final int? koordinatorId;

  PerawatFormResult({
    required this.payload,
    required this.koordinatorId,
  });

  Map<String, dynamic> toPayloadWithoutKoordinator() {
    final map = Map<String, dynamic>.from(payload);
    map.remove('koordinator_id');
    return map;
  }
}

class PerawatVerifyResult {
  final String status;
  final String? note;

  PerawatVerifyResult(this.status, this.note);
}

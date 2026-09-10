export 'package:home_care/features/banners/domain/banner_model.dart' hide LayananModel;
export 'package:home_care/features/services_catalog/domain/service_model.dart';

class Testimonial {
  final int id;
  final String nama;
  final int rating;
  final String komentar;
  final String? layanan;
  final String tanggal;
  final String avatarUrl;

  const Testimonial({
    required this.id,
    required this.nama,
    required this.rating,
    required this.komentar,
    this.layanan,
    required this.tanggal,
    required this.avatarUrl,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    return Testimonial(
      id: json['id'] ?? 0,
      nama: json['nama']?.toString() ?? 'Sahabat Care',
      rating:
          json['rating'] is int
              ? json['rating']
              : int.tryParse(json['rating'].toString()) ?? 5,
      komentar: json['komentar']?.toString() ?? '',
      layanan: json['layanan']?.toString(),
      tanggal: json['tanggal']?.toString() ?? '',
      avatarUrl:
          json['avatar_url']?.toString() ??
          'https://ui-avatars.com/api/?name=S&background=0BA5A7&color=fff',
    );
  }
}

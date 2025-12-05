import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/users/pesanLayanan.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Ganti sesuai API-mu
const String kBaseUrl = 'http://192.168.1.6:8000/api';

class Layanan {
  final int id;
  final String namaLayanan;
  final String? deskripsi;
  final String? kategori;
  final String tipeLayanan;
  final int? jumlahVisit;
  final double hargaDasar;
  final int? durasiMenit;
  final String? syaratPerawat;
  final String? lokasiTersedia;
  final bool aktif;
  final String? gambarUrl;

  Layanan({
    required this.id,
    required this.namaLayanan,
    this.deskripsi,
    this.kategori,
    required this.tipeLayanan,
    this.jumlahVisit,
    required this.hargaDasar,
    this.durasiMenit,
    this.syaratPerawat,
    this.lokasiTersedia,
    required this.aktif,
    this.gambarUrl,
  });

  factory Layanan.fromJson(Map<String, dynamic> json) {
    return Layanan(
      id: json['id'] as int,
      namaLayanan: json['nama_layanan'] ?? '',
      deskripsi: json['deskripsi'],
      kategori: json['kategori'],
      tipeLayanan: json['tipe_layanan'] ?? 'single',
      jumlahVisit: json['jumlah_visit'],
      hargaDasar: (json['harga_dasar'] is int || json['harga_dasar'] is double)
          ? (json['harga_dasar'] as num).toDouble()
          : double.tryParse(json['harga_dasar']?.toString() ?? '') ?? 0.0,
      durasiMenit: json['durasi_menit'],
      syaratPerawat: json['syarat_perawat'],
      lokasiTersedia: json['lokasi_tersedia'],
      aktif: (json['aktif'] == 1 || json['aktif'] == true),
      gambarUrl: json['gambar_url'],
    );
  }
}

class PilihLayananPage extends StatefulWidget {
  const PilihLayananPage({Key? key}) : super(key: key);

  @override
  State<PilihLayananPage> createState() => _PilihLayananPageState();
}

class _PilihLayananPageState extends State<PilihLayananPage> {
  bool _isLoading = true;
  String? _error;
  List<Layanan> _layananList = [];

  @override
  void initState() {
    super.initState();
    _fetchLayanan();
  }

  Future<void> _fetchLayanan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Token tidak ditemukan. Silakan login ulang.';
        });
        return;
      }

      final uri = Uri.parse('$kBaseUrl/layanan?aktif=1');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final success = body['success'] == true;

        if (!success) {
          setState(() {
            _isLoading = false;
            _error = body['message']?.toString() ?? 'Gagal memuat layanan.';
          });
          return;
        }

        final List<dynamic> data = body['data'] ?? [];
        final list = data.map((e) => Layanan.fromJson(e)).toList();

        setState(() {
          _isLoading = false;
          _layananList = list;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login berakhir. Silakan login ulang.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _error =
              'Gagal memuat layanan. Kode: ${response.statusCode} ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Layanan')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchLayanan,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_layananList.isEmpty) {
      return Center(
        child: Text(
          'Belum ada layanan tersedia.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLayanan,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _layananList.length,
        itemBuilder: (context, index) {
          final layanan = _layananList[index];
          return _buildLayananCard(layanan);
        },
      ),
    );
  }

  Widget _buildLayananCard(Layanan layanan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // ⬇️ koordinatorId DIHAPUS — backend yang pilih & reuse koordinator
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PesanLayananPage(
                layanan: layanan,
              ),
            ),
          );

          // Kalau mau, setelah order berhasil bisa cek result (data order) di sini
          if (result != null) {
            Navigator.pop(context, result);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail gambar layanan
              _buildThumbnail(layanan),
              const SizedBox(width: 12),
              // Detail teks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layanan.namaLayanan,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (layanan.kategori != null &&
                        layanan.kategori!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          layanan.kategori!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (layanan.deskripsi != null &&
                        layanan.deskripsi!.trim().isNotEmpty)
                      Text(
                        layanan.deskripsi!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Spacer(),
                        if (layanan.durasiMenit != null)
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${layanan.durasiMenit} menit',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        if (layanan.tipeLayanan == 'paket')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.blue.withOpacity(0.1),
                            ),
                            child: Text(
                              'Paket ${layanan.jumlahVisit ?? '-'}x visit',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        if (layanan.syaratPerawat != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.green.withOpacity(0.1),
                            ),
                            child: Text(
                              'Perawat: ${layanan.syaratPerawat}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Layanan layanan) {
    if (layanan.gambarUrl == null || layanan.gambarUrl!.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.medical_services),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        layanan.gambarUrl!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.broken_image),
          );
        },
      ),
    );
  }
}

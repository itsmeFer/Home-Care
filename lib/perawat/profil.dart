import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PerawatProfilPage extends StatefulWidget {
  const PerawatProfilPage({super.key});

  @override
  State<PerawatProfilPage> createState() => _PerawatProfilPageState();
}

// ===============================
// KONFIG BASE URL + HELPER MEDIA
// ===============================

const String kApiBase = 'http://192.168.1.6:8000/api';
const String kBaseUrl = 'http://192.168.1.6:8000';

/// Ubah path dari DB menjadi URL yang aman CORS via /api/media
String? resolveMediaUrl(String? raw) {
  if (raw == null) return null;
  var v = raw.trim();
  if (v.isEmpty) return null;

  // Kalau sudah bentuk api/media → langsung pakai
  if (v.contains('/api/media/')) {
    if (!v.startsWith('http://') && !v.startsWith('https://')) {
      return '$kBaseUrl$v';
    }
    return v;
  }

  // Kalau full URL: http://192.168.1.6:8000/storage/...
  if (v.startsWith('http://') || v.startsWith('https://')) {
    final uri = Uri.parse(v);
    v = uri.path; // contoh: /storage/perawat/...
  }

  // Hilangkan slash di depan
  if (v.startsWith('/')) v = v.substring(1);

  // Hilangkan "storage/" di depan kalau ada
  if (v.startsWith('storage/')) {
    v = v.substring('storage/'.length); // jadi: perawat/foto/xxx.jpg
  }

  // Sekarang v bentuknya perawat/... → gabung ke api/media
  return '$kBaseUrl/api/media/$v';
}

class _PerawatProfilPageState extends State<PerawatProfilPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profil;

  @override
  void initState() {
    super.initState();
    _fetchProfil();
  }

  Future<void> _fetchProfil() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _error = 'Token tidak ditemukan. Silakan login ulang.';
          _isLoading = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse('$kApiBase/perawat/profil'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) {
        setState(() {
          _error = 'Gagal memuat profil (${res.statusCode})';
          _isLoading = false;
        });
        return;
      }

      final body = json.decode(res.body);
      if (body['success'] != true) {
        setState(() {
          _error = body['message'] ?? 'Gagal memuat profil';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _profil = body['data'] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildRow({required String label, String? value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(':  '),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageItem(String label, String? rawUrl) {
    final url = resolveMediaUrl(rawUrl);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          url == null || url.isEmpty
              ? const Text('-')
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) =>
                        const Text('Gambar tidak tersedia'),
                  ),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profil = _profil;
    final fotoUrl = resolveMediaUrl(profil?['foto'] as String?);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Perawat'),
        backgroundColor: const Color(0xFF0BA5A7),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfil,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // ====== HEADER CARD (NAMA + PROFESI) ======
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor:
                                    const Color(0xFF0BA5A7).withOpacity(.1),
                                backgroundImage: (fotoUrl != null)
                                    ? NetworkImage(fotoUrl)
                                    : null,
                                child: (fotoUrl != null)
                                    ? null
                                    : Text(
                                        (profil?['nama_lengkap'] ?? 'P')
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                profil?['nama_lengkap'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profil?['profesi'] ?? 'Perawat',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kode: ${profil?['kode_perawat'] ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ====== DATA PRIBADI ======
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data Pribadi',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildRow(
                                label: 'NIK',
                                value: profil?['nik'] as String?,
                              ),
                              _buildRow(
                                label: 'Jenis Kelamin',
                                value: _mapGender(profil?['jenis_kelamin']),
                              ),
                              _buildRow(
                                label: 'Tempat Lahir',
                                value: profil?['tempat_lahir'] as String?,
                              ),
                              _buildRow(
                                label: 'Tanggal Lahir',
                                value: profil?['tanggal_lahir']?.toString(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ====== KONTAK & AREA ======
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kontak & Area Kerja',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildRow(
                                label: 'No. HP',
                                value: profil?['no_hp'] as String?,
                              ),
                              _buildRow(
                                label: 'Email',
                                value: profil?['email'] as String?,
                              ),
                              _buildRow(
                                label: 'Wilayah',
                                value: profil?['wilayah'] as String?,
                              ),
                              _buildRow(
                                label: 'Alamat',
                                value: profil?['alamat'] as String?,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ====== PROFESIONAL ======
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data Profesional',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildRow(
                                label: 'Keahlian',
                                value: profil?['keahlian'] as String?,
                              ),
                              _buildRow(
                                label: 'No. STR',
                                value: profil?['no_str'] as String?,
                              ),
                              _buildRow(
                                label: 'No. SIP',
                                value: profil?['no_sip'] as String?,
                              ),
                              _buildRow(
                                label: 'Pengalaman (tahun)',
                                value: profil?['tahun_pengalaman']?.toString(),
                              ),
                              _buildRow(
                                label: 'Tempat Kerja Terakhir',
                                value:
                                    profil?['tempat_kerja_terakhir'] as String?,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ====== KONTAK DARURAT ======
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kontak Darurat',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildRow(
                                label: 'Nama',
                                value:
                                    profil?['kontak_darurat_nama'] as String?,
                              ),
                              _buildRow(
                                label: 'No. HP',
                                value: profil?['kontak_darurat_no_hp']
                                    as String?,
                              ),
                              _buildRow(
                                label: 'Hubungan',
                                value: profil?['kontak_darurat_hubungan']
                                    as String?,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ====== STATUS ======
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildRow(
                                label: 'Status Verifikasi',
                                value:
                                    profil?['status_verifikasi'] as String?,
                              ),
                              _buildRow(
                                label: 'Aktif',
                                value: (profil?['is_active'] == true)
                                    ? 'Aktif'
                                    : 'Nonaktif',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ====== FOTO & DOKUMEN ======
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Foto & Dokumen',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _imageItem('Foto Profil', profil?['foto']),
                              _imageItem('Foto KTP', profil?['foto_ktp']),
                              _imageItem('Ijazah', profil?['ijazah']),
                              _imageItem('STR (Scan)', profil?['str_file']),
                              _imageItem('SIP (Scan)', profil?['sip_file']),
                              _imageItem('Sertifikat BTCLS',
                                  profil?['sertifikat_btcls']),
                              _imageItem('Sertifikat PPRA',
                                  profil?['sertifikat_ppra']),
                              _imageItem('Sertifikat Lainnya',
                                  profil?['sertifikat_lainnya']),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
      ),
    );
  }

  String? _mapGender(dynamic kode) {
    if (kode == null) return null;
    if (kode == 'L') return 'Laki-laki';
    if (kode == 'P') return 'Perempuan';
    return kode.toString();
  }
}

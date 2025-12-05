import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Warna HCColor
import 'package:home_care/users/HomePage.dart';

// ======================================
// KONFIG
// ======================================

const String kApiBase = 'http://192.168.1.6:8000/api';
const String kBaseUrl = 'http://192.168.1.6:8000';

String? resolveMediaUrl(String? raw) {
  if (raw == null) return null;
  var v = raw.trim();
  if (v.isEmpty) return null;

  // Kalau sudah bentuk api/media → langsung pakai
  if (v.contains('/api/media/')) {
    if (!v.startsWith('http')) {
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

// ======================================
// MODEL UNTUK LIST DI ADMIN
// ======================================

class PerawatAdmin {
  final int? id;
  final String? kodePerawat;
  final String? namaPerawat;
  final String? namaKoordinator;
  final String? noHp;
  final bool? isActive;
  final String? foto;

  final String? statusVerifikasi;
  final String? verifiedAt;
  final String? catatanVerifikasi;
  final String? verifikator; // nama_verifikator

  PerawatAdmin({
    this.id,
    this.kodePerawat,
    this.namaPerawat,
    this.namaKoordinator,
    this.noHp,
    this.isActive,
    this.foto,
    this.statusVerifikasi,
    this.verifiedAt,
    this.catatanVerifikasi,
    this.verifikator,
  });

  factory PerawatAdmin.fromJson(Map<String, dynamic> json) {
  bool? parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString();
    if (s == '1' || s.toLowerCase() == 'true') return true;
    if (s == '0' || s.toLowerCase() == 'false') return false;
    return null;
  }

  return PerawatAdmin(
    id: json['id'] as int?,
    kodePerawat: json['kode_perawat']?.toString(),
    namaPerawat:
        (json['nama_perawat'] ?? json['nama_lengkap'])?.toString(), // <-- ini
    namaKoordinator: json['nama_koordinator']?.toString(),
    noHp: json['no_hp']?.toString(),
    isActive: parseBool(json['is_active']),
    foto: json['foto']?.toString(),
    statusVerifikasi: json['status_verifikasi']?.toString(),
    verifiedAt: json['verified_at']?.toString(),
    catatanVerifikasi: json['catatan_verifikasi']?.toString(),
    verifikator: json['nama_verifikator']?.toString(),
  );
}


  String get labelStatusVerifikasi {
    switch (statusVerifikasi) {
      case 'verified':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Color get chipColorVerifikasi {
    switch (statusVerifikasi) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String get inisial {
    final nama = namaPerawat ?? '';
    if (nama.trim().isEmpty) return '?';
    final parts = nama.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// ======================================
// HALAMAN LIST PERAWAT UNTUK ADMIN
// ======================================

class LihatPerawatPage extends StatefulWidget {
  const LihatPerawatPage({super.key});

  @override
  State<LihatPerawatPage> createState() => _LihatPerawatPageState();
}

class _LihatPerawatPageState extends State<LihatPerawatPage> {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  List<PerawatAdmin> _list = [];
  final TextEditingController _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPerawat();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchPerawat({String? search}) async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _isError = true;
          _errorMessage = 'Token tidak ditemukan. Silakan login ulang.';
        });
        return;
      }

      final uri = Uri.parse('$kApiBase/admin/perawat').replace(
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );

      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        setState(() {
          _isError = true;
          _errorMessage =
              'Gagal mengambil data perawat (kode ${res.statusCode})';
        });
        return;
      }

      final body = jsonDecode(res.body);
      if (body is! Map || body['success'] != true || body['data'] == null) {
        setState(() {
          _isError = true;
          _errorMessage =
              body['message'] ?? 'Gagal membaca data perawat dari server.';
        });
        return;
      }

      final List<dynamic> data = body['data'];
      final list = data.map((e) => PerawatAdmin.fromJson(e)).toList();

      setState(() {
        _list = list;
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearch() {
    _fetchPerawat(search: _searchC.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        foregroundColor: Colors.white,
        title: const Text('Data Perawat'),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchC,
                    decoration: InputDecoration(
                      hintText:
                          'Cari nama perawat / kode / koordinator / email...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _onSearch,
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: () {
                    _searchC.clear();
                    _fetchPerawat();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isError
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage ?? 'Terjadi kesalahan',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    : _list.isEmpty
                        ? const Center(
                            child: Text('Belum ada data perawat.'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                            itemCount: _list.length,
                            itemBuilder: (ctx, i) {
                              final p = _list[i];
                              final fotoUrl = resolveMediaUrl(p.foto);

                              return Card(
                                color: Colors.white.withOpacity(0.9),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // FOTO / INISIAL
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor:
                                            HCColor.primary.withOpacity(.1),
                                        backgroundImage: (fotoUrl != null)
                                            ? NetworkImage(fotoUrl)
                                            : null,
                                        child: (fotoUrl != null)
                                            ? null
                                            : Text(
                                                p.inisial,
                                                style: TextStyle(
                                                  color: HCColor.primaryDark,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      // DETAIL
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.namaPerawat ?? '-',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Kode: ${p.kodePerawat ?? '-'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Koordinator: ${p.namaKoordinator ?? '-'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                // CHIP STATUS VERIFIKASI
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: p.chipColorVerifikasi
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Text(
                                                    p.labelStatusVerifikasi,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          p.chipColorVerifikasi,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // CHIP STATUS AKTIF
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (p.isActive ?? true)
                                                        ? Colors.green
                                                            .withOpacity(0.15)
                                                        : Colors.red
                                                            .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            999),
                                                  ),
                                                  child: Text(
                                                    (p.isActive ?? true)
                                                        ? 'Aktif'
                                                        : 'Tidak Aktif',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: (p.isActive ??
                                                              true)
                                                          ? Colors.green[700]
                                                          : Colors.red[700],
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // TGL VERIFIKASI
                                            if (p.verifiedAt != null &&
                                                p.verifiedAt!.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                'Tgl verifikasi: ${p.verifiedAt}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],

                                            // CATATAN VERIFIKASI
                                            if (p.catatanVerifikasi != null &&
                                                p.catatanVerifikasi!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Catatan: ${p.catatanVerifikasi}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],

                                            // NAMA VERIFIKATOR
                                            if (p.verifikator != null &&
                                                p.verifikator!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Diverifikasi oleh: ${p.verifikator}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

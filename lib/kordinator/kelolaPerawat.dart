import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:home_care/kordinator/detailPerawat.dart';
// pakai warna HCColor
import 'package:home_care/users/HomePage.dart';

class KelolaPerawatPage extends StatefulWidget {
  const KelolaPerawatPage({super.key});

  @override
  State<KelolaPerawatPage> createState() => _KelolaPerawatPageState();
}

class _KelolaPerawatPageState extends State<KelolaPerawatPage> {
  static const String baseUrl = 'http://192.168.1.6:8000/api';

  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  List<Perawat> _list = [];

  @override
  void initState() {
    super.initState();
    _fetchPerawat();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ====================================
  // GET LIST PERAWAT
  // ====================================
  Future<void> _fetchPerawat() async {
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
          _errorMessage = 'Token tidak ditemukan, silakan login ulang.';
        });
        return;
      }

      final url = Uri.parse('$baseUrl/koordinator/perawat');
      final res = await http.get(
        url,
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

      final body = json.decode(res.body);
      if (body is Map && body['success'] == true && body['data'] != null) {
        final List<dynamic> data = body['data'];
        final list = data.map((e) => Perawat.fromJson(e)).toList();
        setState(() {
          _list = list;
        });
      } else {
        setState(() {
          _isError = true;
          _errorMessage =
              body['message'] ?? 'Gagal mengambil data perawat dari server.';
        });
      }
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

  // verdifikasi status
  Future<void> _ubahStatusVerifikasi(
    int perawatId,
    String status, {
    String? catatan,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse(
        '$baseUrl/koordinator/perawat/$perawatId/verifikasi',
      );

      final body = <String, dynamic>{
        'status_verifikasi': status,
        if (catatan != null && catatan.trim().isNotEmpty)
          'catatan_verifikasi': catatan.trim(),
      };

      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        throw 'Gagal mengubah status verifikasi (kode ${res.statusCode})';
      }

      // 🔔 SnackBar beda-beda tergantung status
      String msg;
      Color bgColor;

      if (status == 'verified') {
        msg = 'Perawat berhasil diverifikasi ✔';
        bgColor = Colors.green;
      } else if (status == 'rejected') {
        msg = 'Perawat ditolak ❌';
        bgColor = Colors.red;
      } else if (status == 'pending') {
        msg = 'Status dikembalikan ke draft ⏪';
        bgColor = Colors.orange;
      } else {
        msg = 'Status verifikasi diperbarui';
        bgColor = HCColor.primary;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bgColor));

      _fetchPerawat(); // refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _tanyaCatatanDanUbahStatus(Perawat p, String status) async {
    final controller = TextEditingController();

    final hasil = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          status == 'verified' ? 'Verifikasi Perawat' : 'Tolak Perawat',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Perawat: ${p.namaLengkap ?? '-'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Catatan verifikasi (opsional)',
                hintText: status == 'verified'
                    ? 'Contoh: Berkas lengkap dan valid'
                    : 'Contoh: Berkas tidak lengkap / data tidak sesuai',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (hasil == true) {
      await _ubahStatusVerifikasi(p.id!, status, catatan: controller.text);
    }
  }

  // ====================================
  // CREATE PERAWAT
  // ====================================
  Future<void> _createPerawat(Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/koordinator/perawat');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (res.statusCode != 201 && res.statusCode != 200) {
        String msg = 'Gagal menambah perawat (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perawat berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchPerawat();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambah perawat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ====================================
  // UPDATE PERAWAT
  // ====================================
  Future<void> _updatePerawat(int id, Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/koordinator/perawat/$id');
      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (res.statusCode != 200) {
        String msg = 'Gagal mengupdate perawat (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perawat berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchPerawat();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupdate perawat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ====================================
  // DELETE PERAWAT
  // ====================================
  Future<void> _deletePerawat(Perawat p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Perawat'),
        content: Text(
          'Yakin ingin menghapus perawat "${p.namaLengkap ?? '-'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/koordinator/perawat/${p.id}');
      final res = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        String msg = 'Gagal menghapus perawat (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perawat berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _list.removeWhere((e) => e.id == p.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus perawat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openForm({Perawat? perawat}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PerawatFormDialog(perawat: perawat),
    );

    if (result == null) return;

    if (perawat == null) {
      await _createPerawat(result);
    } else {
      await _updatePerawat(perawat.id!, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        title: const Text(
          'Kelola Perawat',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: _fetchPerawat, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Perawat'),
      ),
      body: _isLoading
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
          ? const Center(child: Text('Belum ada perawat, tambahkan dulu.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _list.length,

              itemBuilder: (_, i) {
                final p = _list[i];
                final bool canToggleActive = p.statusVerifikasi == 'verified';

                // 👉 ambil URL foto (lewat /api/media biar aman CORS)
                final String? fotoUrl = resolveMediaUrl(p.foto);

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailPerawatPage(perawat: p),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: HCColor.primary.withOpacity(.1),
                            backgroundImage:
                                (fotoUrl != null && fotoUrl.isNotEmpty)
                                ? NetworkImage(fotoUrl)
                                : null,
                            child: (fotoUrl != null && fotoUrl.isNotEmpty)
                                ? null
                                : Text(
                                    p.inisial ?? '?',
                                    style: TextStyle(
                                      color: HCColor.primaryDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.namaLengkap ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    // chip verifikasi
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: p.chipColorVerifikasi
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        p.labelStatusVerifikasi,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: p.chipColorVerifikasi,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // chip aktif / tidak aktif
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (p.isActive ?? true)
                                            ? Colors.green.withOpacity(0.15)
                                            : Colors.red.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        (p.isActive ?? true)
                                            ? 'Aktif'
                                            : 'Tidak Aktif',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: (p.isActive ?? true)
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      p.labelJenisKelamin,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (p.tahunPengalaman != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${p.tahunPengalaman} thn pengalaman',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                if (p.keahlian != null &&
                                    p.keahlian!.isNotEmpty)
                                  Text(
                                    'Keahlian: ${p.keahlian}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (p.profesi != null && p.profesi!.isNotEmpty)
                                  Text(
                                    'Profesi: ${p.profesi}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (p.noHp != null && p.noHp!.isNotEmpty)
                                  Text(
                                    'No HP: ${p.noHp}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (p.wilayah != null && p.wilayah!.isNotEmpty)
                                  Text(
                                    'Wilayah: ${p.wilayah}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Switch(
                                  value: p.isActive ?? false,
                                  onChanged: canToggleActive
                                      ? (val) {
                                          if (p.id != null) {
                                            _updatePerawat(p.id!, {
                                              'is_active': val,
                                            });
                                          }
                                        }
                                      : null, // <= kalau null, Switch otomatis disabled
                                  activeColor: HCColor.primary,
                                ),
                              ),
                              if (!canToggleActive) ...[
                                const SizedBox(height: 2),
                                Text(
                                  p.statusVerifikasi == 'pending'
                                      ? 'Aktif setelah terverifikasi'
                                      : 'Perawat ditolak',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 4),

                              if (p.statusVerifikasi == 'pending') ...[
                                Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _tanyaCatatanDanUbahStatus(
                                            p,
                                            'verified',
                                          ),
                                      child: const Text(
                                        'Verifikasi',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _tanyaCatatanDanUbahStatus(
                                            p,
                                            'rejected',
                                          ),
                                      child: const Text(
                                        'Tolak',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                              ] else ...[
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _ubahStatusVerifikasi(p.id!, 'pending'),
                                  child: const Text(
                                    'Kembalikan ke Draft',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],

                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deletePerawat(p),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ====================================
// MODEL PERAWAT
// ====================================

class Perawat {
  final int? id;
  final String? kodePerawat;
  final String? namaLengkap;
  final String? nik;
  final String? jenisKelamin; // L / P
  final String? tanggalLahir;
  final String? tempatLahir;

  final String? noHp;
  final String? email;
  final String? profesi;
  final String? keahlian;
  final String? noStr;
  final String? noSip;

  final int? tahunPengalaman;
  final String? tempatKerjaTerakhir;

  final String? wilayah;
  final String? alamat;

  final String? kontakDaruratNama;
  final String? kontakDaruratNoHp;
  final String? kontakDaruratHubungan;

  final bool? isActive;

  // 🔥 STATUS VERIFIKASI
  final String? statusVerifikasi;
  final String? verifiedAt;
  final String? catatanVerifikasi;

  // 👉 TAMBAHAN UNTUK FOTO & DOKUMEN
  final String? foto;
  final String? fotoKtp;
  final String? ijazah;
  final String? strFile;
  final String? sipFile;
  final String? sertifikatBtcls;
  final String? sertifikatPpra;
  final String? sertifikatLainnya;

  Perawat({
    this.id,
    this.kodePerawat,
    this.namaLengkap,
    this.nik,
    this.jenisKelamin,
    this.tanggalLahir,
    this.tempatLahir,
    this.noHp,
    this.email,
    this.profesi,
    this.keahlian,
    this.noStr,
    this.noSip,
    this.tahunPengalaman,
    this.tempatKerjaTerakhir,
    this.wilayah,
    this.alamat,
    this.kontakDaruratNama,
    this.kontakDaruratNoHp,
    this.kontakDaruratHubungan,
    this.isActive,

    // 🔥 status verifikasi
    this.statusVerifikasi,
    this.verifiedAt,
    this.catatanVerifikasi,

    // dokumen
    this.foto,
    this.fotoKtp,
    this.ijazah,
    this.strFile,
    this.sipFile,
    this.sertifikatBtcls,
    this.sertifikatPpra,
    this.sertifikatLainnya,
  });

  factory Perawat.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String && v.trim().isNotEmpty) {
        return int.tryParse(v);
      }
      return null;
    }

    return Perawat(
      id: json['id'] as int?,
      kodePerawat: json['kode_perawat']?.toString(),
      namaLengkap: json['nama_lengkap']?.toString(),
      nik: json['nik']?.toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      tanggalLahir: json['tanggal_lahir']?.toString(),
      tempatLahir: json['tempat_lahir']?.toString(),
      noHp: json['no_hp']?.toString(),
      email: json['email']?.toString(),
      profesi: json['profesi']?.toString(),
      keahlian: json['keahlian']?.toString(),
      noStr: json['no_str']?.toString(),
      noSip: json['no_sip']?.toString(),
      tahunPengalaman: parseInt(json['tahun_pengalaman']),
      tempatKerjaTerakhir: json['tempat_kerja_terakhir']?.toString(),
      wilayah: json['wilayah']?.toString(),
      alamat: json['alamat']?.toString(),
      kontakDaruratNama: json['kontak_darurat_nama']?.toString(),
      kontakDaruratNoHp: json['kontak_darurat_no_hp']?.toString(),
      kontakDaruratHubungan: json['kontak_darurat_hubungan']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : (json['is_active'] is bool
                ? json['is_active']
                : json['is_active'].toString() == '1'),

      // 🔥 status verifikasi
      statusVerifikasi: json['status_verifikasi']?.toString(),
      verifiedAt: json['verified_at']?.toString(),
      catatanVerifikasi: json['catatan_verifikasi']?.toString(),

      // 👉 MAP FIELD FOTO & DOKUMEN
      foto: json['foto']?.toString(),
      fotoKtp: json['foto_ktp']?.toString(),
      ijazah: json['ijazah']?.toString(),
      strFile: json['str_file']?.toString(),
      sipFile: json['sip_file']?.toString(),
      sertifikatBtcls: json['sertifikat_btcls']?.toString(),
      sertifikatPpra: json['sertifikat_ppra']?.toString(),
      sertifikatLainnya: json['sertifikat_lainnya']?.toString(),
    );
  }

  String? get inisial {
    if (namaLengkap == null || namaLengkap!.isEmpty) return null;
    final parts = namaLengkap!.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get labelJenisKelamin {
    if (jenisKelamin == 'L') return 'Laki-laki';
    if (jenisKelamin == 'P') return 'Perempuan';
    return '-';
  }

  // 🔥 helper status verifikasi
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
}

const String kBaseUrl = 'http://192.168.1.6:8000';

String? resolveMediaUrl(String? raw) {
  if (raw == null) return null;
  var v = raw.trim();
  if (v.isEmpty) return null;

  // Kalau sudah bentuk api/media → langsung pakai
  if (v.contains('/api/media/')) {
    // kalau belum ada domain, tambahkan
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

// ====================================
// FORM DIALOG PERAWAT
// ====================================

class _PerawatFormDialog extends StatefulWidget {
  final Perawat? perawat;

  const _PerawatFormDialog({this.perawat});

  @override
  State<_PerawatFormDialog> createState() => _PerawatFormDialogState();
}

class _PerawatFormDialogState extends State<_PerawatFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaC;
  late TextEditingController _nikC;
  String? _jenisKelamin; // 'L' atau 'P'
  late TextEditingController _tanggalLahirC;
  late TextEditingController _tempatLahirC;

  late TextEditingController _noHpC;
  late TextEditingController _emailC;
  late TextEditingController _profesiC;
  late TextEditingController _keahlianC;
  late TextEditingController _noStrC;
  late TextEditingController _noSipC;

  late TextEditingController _tahunPengalamanC;
  late TextEditingController _tempatKerjaTerakhirC;

  late TextEditingController _wilayahC;
  late TextEditingController _alamatC;

  late TextEditingController _kontakDaruratNamaC;
  late TextEditingController _kontakDaruratNoHpC;
  late TextEditingController _kontakDaruratHubunganC;

  final ImagePicker _picker = ImagePicker();

  XFile? _fotoFile;
  String? _fotoBase64;

  XFile? _fotoKtpFile;
  String? _fotoKtpBase64;

  XFile? _ijazahFile;
  String? _ijazahBase64;

  XFile? _strFile;
  String? _strFileBase64;

  XFile? _sipFile;
  String? _sipFileBase64;

  XFile? _btclsFile;
  String? _btclsBase64;

  XFile? _ppraFile;
  String? _ppraBase64;

  XFile? _sertifLainFile;
  String? _sertifLainBase64;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final p = widget.perawat;

    _namaC = TextEditingController(text: p?.namaLengkap ?? '');
    _nikC = TextEditingController(text: p?.nik ?? '');
    _jenisKelamin = p?.jenisKelamin;
    _tanggalLahirC = TextEditingController(text: p?.tanggalLahir ?? '');
    _tempatLahirC = TextEditingController(text: p?.tempatLahir ?? '');

    _noHpC = TextEditingController(text: p?.noHp ?? '');
    _emailC = TextEditingController(text: p?.email ?? '');
    _profesiC = TextEditingController(text: p?.profesi ?? '');
    _keahlianC = TextEditingController(text: p?.keahlian ?? '');
    _noStrC = TextEditingController(text: p?.noStr ?? '');
    _noSipC = TextEditingController(text: p?.noSip ?? '');

    _tahunPengalamanC = TextEditingController(
      text: p?.tahunPengalaman?.toString() ?? '',
    );
    _tempatKerjaTerakhirC = TextEditingController(
      text: p?.tempatKerjaTerakhir ?? '',
    );

    _wilayahC = TextEditingController(text: p?.wilayah ?? '');
    _alamatC = TextEditingController(text: p?.alamat ?? '');

    _kontakDaruratNamaC = TextEditingController(
      text: p?.kontakDaruratNama ?? '',
    );
    _kontakDaruratNoHpC = TextEditingController(
      text: p?.kontakDaruratNoHp ?? '',
    );
    _kontakDaruratHubunganC = TextEditingController(
      text: p?.kontakDaruratHubungan ?? '',
    );

    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _namaC.dispose();
    _nikC.dispose();
    _tanggalLahirC.dispose();
    _tempatLahirC.dispose();
    _noHpC.dispose();
    _emailC.dispose();
    _profesiC.dispose();
    _keahlianC.dispose();
    _noStrC.dispose();
    _noSipC.dispose();
    _tahunPengalamanC.dispose();
    _tempatKerjaTerakhirC.dispose();
    _wilayahC.dispose();
    _alamatC.dispose();
    _kontakDaruratNamaC.dispose();
    _kontakDaruratNoHpC.dispose();
    _kontakDaruratHubunganC.dispose();
    super.dispose();
  }

  Future<void> _pickImage({
    required void Function(XFile file, String base64) onPicked,
  }) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    // asumsi default jpg; kalau mau lebih presisi bisa cek extension
    String mime = 'image/jpeg';
    final path = picked.path.toLowerCase();
    if (path.endsWith('.png')) mime = 'image/png';
    if (path.endsWith('.webp')) mime = 'image/webp';

    final b64 = 'data:$mime;base64,${base64Encode(bytes)}';

    setState(() {
      onPicked(picked, b64);
    });
  }

  Future<void> _pickFoto() async {
    await _pickImage(
      onPicked: (file, b64) {
        _fotoFile = file;
        _fotoBase64 = b64;
      },
    );
  }

  Future<void> _pickFotoKtp() async {
    await _pickImage(
      onPicked: (file, b64) {
        _fotoKtpFile = file;
        _fotoKtpBase64 = b64;
      },
    );
  }

  Future<void> _pickIjazah() async {
    await _pickImage(
      onPicked: (file, b64) {
        _ijazahFile = file;
        _ijazahBase64 = b64;
      },
    );
  }

  // dan seterusnya untuk STR, SIP, BTCLS, PPRA, lainnya:
  Future<void> _pickStrFile() async {
    await _pickImage(
      onPicked: (file, b64) {
        _strFile = file;
        _strFileBase64 = b64;
      },
    );
  }

  Future<void> _pickSipFile() async {
    await _pickImage(
      onPicked: (file, b64) {
        _sipFile = file;
        _sipFileBase64 = b64;
      },
    );
  }

  Future<void> _pickBtclsFile() async {
    await _pickImage(
      onPicked: (file, b64) {
        _btclsFile = file;
        _btclsBase64 = b64;
      },
    );
  }

  Future<void> _pickPpraFile() async {
    await _pickImage(
      onPicked: (file, b64) {
        _ppraFile = file;
        _ppraBase64 = b64;
      },
    );
  }

  Future<void> _pickSertifLainFile() async {
    await _pickImage(
      onPicked: (file, b64) {
        _sertifLainFile = file;
        _sertifLainBase64 = b64;
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.perawat != null;

    int? tahunPengalaman;
    if (_tahunPengalamanC.text.trim().isNotEmpty) {
      tahunPengalaman = int.tryParse(_tahunPengalamanC.text.trim());
    }

    final payload = <String, dynamic>{
      'nama_lengkap': _namaC.text.trim(),
      'nik': _nikC.text.trim().isEmpty ? null : _nikC.text.trim(),
      'jenis_kelamin': _jenisKelamin,
      'tanggal_lahir': _tanggalLahirC.text.trim().isNotEmpty
          ? _tanggalLahirC.text.trim()
          : null,
      'tempat_lahir': _tempatLahirC.text.trim().isNotEmpty
          ? _tempatLahirC.text.trim()
          : null,

      'no_hp': _noHpC.text.trim().isNotEmpty ? _noHpC.text.trim() : null,
      'email': _emailC.text.trim().isNotEmpty ? _emailC.text.trim() : null,

      'profesi': _profesiC.text.trim(),
      'keahlian': _keahlianC.text.trim(),
      'no_str': _noStrC.text.trim(),
      'no_sip': _noSipC.text.trim(),

      'tahun_pengalaman': tahunPengalaman,
      'tempat_kerja_terakhir': _tempatKerjaTerakhirC.text.trim(),

      'wilayah': _wilayahC.text.trim(),
      'alamat': _alamatC.text.trim(),

      'kontak_darurat_nama': _kontakDaruratNamaC.text.trim(),
      'kontak_darurat_no_hp': _kontakDaruratNoHpC.text.trim(),
      'kontak_darurat_hubungan': _kontakDaruratHubunganC.text.trim(),

      'is_active': _isActive,

      // ========= DOKUMEN BASE64 =========
      'foto_base64': _fotoBase64,
      'foto_ktp_base64': _fotoKtpBase64,
      'ijazah_base64': _ijazahBase64,
      'str_file_base64': _strFileBase64,
      'sip_file_base64': _sipFileBase64,
      'sertifikat_btcls_base64': _btclsBase64,
      'sertifikat_ppra_base64': _ppraBase64,
      'sertifikat_lainnya_base64': _sertifLainBase64,
    };

    // untuk update, kosong/null dibuang biar nggak overwrite paksa
    if (isEdit) {
      payload.removeWhere((key, value) {
        if (value == null) return true;
        if (value is String && value.trim().isEmpty) return true;
        return false;
      });
    }

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.perawat != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Perawat' : 'Tambah Perawat'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nama lengkap
                TextFormField(
                  controller: _namaC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // NIK
                TextFormField(
                  controller: _nikC,
                  decoration: const InputDecoration(
                    labelText: 'NIK',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),

                // Jenis Kelamin
                DropdownButtonFormField<String>(
                  value: _jenisKelamin,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                  ],
                  onChanged: (val) {
                    setState(() => _jenisKelamin = val);
                  },
                ),
                const SizedBox(height: 10),

                // Tempat lahir
                TextFormField(
                  controller: _tempatLahirC,
                  decoration: const InputDecoration(
                    labelText: 'Tempat Lahir',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // Tanggal lahir (sementara manual YYYY-MM-DD)
                TextFormField(
                  controller: _tanggalLahirC,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // No HP
                TextFormField(
                  controller: _noHpC,
                  decoration: const InputDecoration(
                    labelText: 'No HP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),

                // Email
                TextFormField(
                  controller: _emailC,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty && !v.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Profesi
                TextFormField(
                  controller: _profesiC,
                  decoration: const InputDecoration(
                    labelText: 'Profesi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // Keahlian
                TextFormField(
                  controller: _keahlianC,
                  decoration: const InputDecoration(
                    labelText: 'Keahlian',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // No STR
                TextFormField(
                  controller: _noStrC,
                  decoration: const InputDecoration(
                    labelText: 'No STR',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // No SIP
                TextFormField(
                  controller: _noSipC,
                  decoration: const InputDecoration(
                    labelText: 'No SIP',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // Tahun pengalaman
                TextFormField(
                  controller: _tahunPengalamanC,
                  decoration: const InputDecoration(
                    labelText: 'Tahun Pengalaman',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),

                // Tempat kerja terakhir
                TextFormField(
                  controller: _tempatKerjaTerakhirC,
                  decoration: const InputDecoration(
                    labelText: 'Tempat Kerja Terakhir',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // Wilayah
                TextFormField(
                  controller: _wilayahC,
                  decoration: const InputDecoration(
                    labelText: 'Wilayah Kerja',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // Alamat
                TextFormField(
                  controller: _alamatC,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 10),

                // Kontak darurat - nama
                TextFormField(
                  controller: _kontakDaruratNamaC,
                  decoration: const InputDecoration(
                    labelText: 'Kontak Darurat - Nama',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // Kontak darurat - no hp
                TextFormField(
                  controller: _kontakDaruratNoHpC,
                  decoration: const InputDecoration(
                    labelText: 'Kontak Darurat - No HP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),

                // Kontak darurat - hubungan
                TextFormField(
                  controller: _kontakDaruratHubunganC,
                  decoration: const InputDecoration(
                    labelText: 'Kontak Darurat - Hubungan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Dokumen Pendukung',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // Foto profil
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFoto,
                        icon: const Icon(Icons.person),
                        label: Text(
                          _fotoFile != null
                              ? 'Ganti Foto Perawat'
                              : 'Upload Foto Perawat',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Foto KTP
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFotoKtp,
                        icon: const Icon(Icons.credit_card),
                        label: Text(
                          _fotoKtpFile != null
                              ? 'Ganti Foto KTP'
                              : 'Upload Foto KTP',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Ijazah
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickIjazah,
                        icon: const Icon(Icons.school),
                        label: Text(
                          _ijazahFile != null
                              ? 'Ganti Ijazah'
                              : 'Upload Ijazah',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // STR
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickStrFile,
                        icon: const Icon(Icons.assignment),
                        label: Text(
                          _strFile != null ? 'Ganti STR' : 'Upload STR',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // SIP
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickSipFile,
                        icon: const Icon(Icons.assignment_turned_in),
                        label: Text(
                          _sipFile != null ? 'Ganti SIP' : 'Upload SIP',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sertifikat BTCLS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickBtclsFile,
                        icon: const Icon(Icons.star),
                        label: Text(
                          _btclsFile != null
                              ? 'Ganti Sertifikat BTCLS'
                              : 'Upload Sertifikat BTCLS',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sertifikat PPRA
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickPpraFile,
                        icon: const Icon(Icons.star_rate),
                        label: Text(
                          _ppraFile != null
                              ? 'Ganti Sertifikat PPRA'
                              : 'Upload Sertifikat PPRA',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sertifikat lainnya
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickSertifLainFile,
                        icon: const Icon(Icons.file_present),
                        label: Text(
                          _sertifLainFile != null
                              ? 'Ganti Sertifikat Lainnya'
                              : 'Upload Sertifikat Lainnya',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isActive,
                  title: const Text('Aktif'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() => _isActive = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: HCColor.primary),
          child: Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

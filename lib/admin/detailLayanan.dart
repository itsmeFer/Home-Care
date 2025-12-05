import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_care/users/HomePage.dart';

class DetailLayananPage extends StatefulWidget {
  final int layananId;

  const DetailLayananPage({super.key, required this.layananId});

  @override
  State<DetailLayananPage> createState() => _DetailLayananPageState();
}

class _DetailLayananPageState extends State<DetailLayananPage> {
  static const String baseUrl = 'http://192.168.1.6:8000/api';

  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  LayananDetail? _layanan;
  File? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Helper untuk gabung pesan error validasi 422 dari backend
  String _extractValidationMessage(String rawBody, String defaultMsg) {
    try {
      final body = json.decode(rawBody);
      if (body is Map) {
        final msg = body['message'];
        if (msg is String && msg.isNotEmpty) {
          return msg;
        }
        if (body['errors'] is Map) {
          final errors = body['errors'] as Map;
          final List<String> all = [];
          errors.forEach((key, value) {
            if (value is List) {
              for (var v in value) {
                all.add('$key: $v');
              }
            } else if (value is String) {
              all.add('$key: $value');
            }
          });
          if (all.isNotEmpty) return all.join('\n');
        }
      }
    } catch (_) {}
    return defaultMsg;
  }

  Future<void> _pickAndUploadImage() async {
    if (_layanan == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked == null) return; // user batal pilih gambar

      setState(() {
        _isUploadingImage = true;
      });

      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/layanan/${_layanan!.id}/gambar');

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (kIsWeb) {
        // ===========================
        // MODE WEB: pakai bytes
        // ===========================
        final bytes = await picked.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'gambar',
          bytes,
          filename: picked.name,
        );
        request.files.add(multipartFile);
      } else {
        // ===========================
        // MODE MOBILE: pakai path
        // ===========================
        request.files.add(
          await http.MultipartFile.fromPath('gambar', picked.path),
        );
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        String msg = 'Gagal mengupload gambar (kode ${res.statusCode})';
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
          content: Text('Gambar layanan berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );

      // refresh data biar gambar_url baru ke-load
      await _fetchDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupload gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _fetchDetail() async {
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

      final url = Uri.parse('$baseUrl/layanan/${widget.layananId}');
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
              'Gagal mengambil detail layanan (kode ${res.statusCode})';
        });
        return;
      }

      final body = json.decode(res.body);
      if (body is Map && body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        setState(() {
          _layanan = LayananDetail.fromJson(data);
        });
      } else {
        setState(() {
          _isError = true;
          _errorMessage = body['message'] ?? 'Data layanan tidak ditemukan.';
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

  Future<void> _updateLayanan(Map<String, dynamic> payload) async {
    if (_layanan == null) return;

    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/layanan/${_layanan!.id}');
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
        String msg = 'Gagal mengupdate layanan (kode ${res.statusCode})';

        if (res.statusCode == 422) {
          msg = _extractValidationMessage(res.body, msg);
        } else {
          try {
            final body = json.decode(res.body);
            if (body is Map && body['message'] != null) {
              msg = body['message'];
            }
          } catch (_) {}
        }

        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Layanan berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );

      // refresh detail, tetap di halaman ini
      await _fetchDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupdate layanan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteLayanan() async {
    if (_layanan == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Layanan'),
        content: Text(
          'Yakin ingin menghapus layanan "${_layanan!.namaLayanan}"?',
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

      final url = Uri.parse('$baseUrl/layanan/${_layanan!.id}');
      final res = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        String msg = 'Gagal menghapus layanan (kode ${res.statusCode})';
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
          content: Text('Layanan berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      // kembali ke halaman sebelumnya, kirim flag true supaya list bisa refresh
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus layanan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openEditForm() async {
    if (_layanan == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LayananFormDialogDetail(layanan: _layanan!),
    );

    if (result == null) return;

    await _updateLayanan(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        title: const Text(
          'Detail Layanan',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDetail),
        ],
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
              : _layanan == null
                  ? const Center(child: Text('Data layanan tidak ditemukan'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // (optional) kalau mau render gambar besar dulu
                                  if (_layanan!.gambarUrl != null &&
                                      _layanan!.gambarUrl!.isNotEmpty) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _layanan!.gambarUrl!,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // ROW HEADER (AVATAR + INFO)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: HCColor.primary
                                            .withOpacity(.1),
                                        backgroundImage: (_layanan!.gambarUrl !=
                                                    null &&
                                                _layanan!.gambarUrl!
                                                    .isNotEmpty)
                                            ? NetworkImage(
                                                _layanan!.gambarUrl!)
                                            : null,
                                        child: (_layanan!.gambarUrl == null ||
                                                _layanan!.gambarUrl!.isEmpty)
                                            ? Icon(
                                                Icons
                                                    .medical_services_outlined,
                                                size: 26,
                                                color: HCColor.primaryDark,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _layanan!.namaLayanan ?? '-',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (_layanan!.kodeLayanan != null)
                                              Text(
                                                'Kode: ${_layanan!.kodeLayanan}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Aktif',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          Switch(
                                            value: _layanan!.aktif ?? true,
                                            onChanged: (val) {
                                              _updateLayanan({'aktif': val});
                                            },
                                            activeColor: HCColor.primary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  _infoRow('Kategori', _layanan!.kategori),
                                  _infoRow('Tipe Layanan',
                                      _layanan!.tipeLayananLabel),
                                  _infoRow('Syarat Perawat',
                                      _layanan!.syaratPerawatLabel),
                                  _infoRow('Lokasi Tersedia',
                                      _layanan!.lokasiLabel),
                                  if (_layanan!.hargaDasar != null)
                                    _infoRow(
                                      'Harga Dasar',
                                      'Rp ${_layanan!.hargaDasar!.toStringAsFixed(0)}',
                                    ),
                                  if (_layanan!.durasiMenit != null)
                                    _infoRow(
                                      'Durasi',
                                      '${_layanan!.durasiMenit} menit',
                                    ),
                                  if (_layanan!.jumlahVisit != null)
                                    _infoRow(
                                      'Jumlah Visit (paket)',
                                      '${_layanan!.jumlahVisit}',
                                    ),
                                  if (_layanan!.deskripsi != null &&
                                      _layanan!.deskripsi!.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Deskripsi',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _layanan!.deskripsi!,
                                          style:
                                              const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _deleteLayanan,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side:
                                        const BorderSide(color: Colors.red),
                                  ),
                                  icon:
                                      const Icon(Icons.delete_outline),
                                  label: const Text('Hapus'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _openEditForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: HCColor.primary,
                                  ),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed:
                                _isUploadingImage ? null : _pickAndUploadImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HCColor.primaryDark,
                            ),
                            icon: _isUploadingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.image),
                            label: Text(
                              _isUploadingImage
                                  ? 'Mengupload...'
                                  : 'Ubah Gambar Layanan',
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// ====== MODEL DETAIL LAYANAN ======

class LayananDetail {
  final int? id;
  final String? kodeLayanan;
  final String? namaLayanan;
  final String? deskripsi;
  final String? kategori;
  final String? tipeLayanan;
  final int? jumlahVisit;
  final double? hargaDasar;
  final int? durasiMenit;
  final String? syaratPerawat;
  final String? lokasiTersedia;
  final bool? aktif;
  final String? gambarUrl;

  LayananDetail({
    this.id,
    this.kodeLayanan,
    this.namaLayanan,
    this.deskripsi,
    this.kategori,
    this.tipeLayanan,
    this.jumlahVisit,
    this.hargaDasar,
    this.durasiMenit,
    this.syaratPerawat,
    this.lokasiTersedia,
    this.aktif,
    this.gambarUrl,
  });

  factory LayananDetail.fromJson(Map<String, dynamic> json) {
    num? harga;
    if (json['harga_dasar'] != null) {
      if (json['harga_dasar'] is num) {
        harga = json['harga_dasar'] as num;
      } else {
        harga = num.tryParse(json['harga_dasar'].toString());
      }
    }

    return LayananDetail(
      id: json['id'] as int?,
      kodeLayanan: json['kode_layanan']?.toString(),
      namaLayanan: json['nama_layanan']?.toString(),
      deskripsi: json['deskripsi']?.toString(),
      kategori: json['kategori']?.toString(),
      tipeLayanan: json['tipe_layanan']?.toString(),
      jumlahVisit: json['jumlah_visit'] != null
          ? int.tryParse(json['jumlah_visit'].toString())
          : null,
      hargaDasar: harga?.toDouble(),
      durasiMenit: json['durasi_menit'] != null
          ? int.tryParse(json['durasi_menit'].toString())
          : null,
      syaratPerawat: json['syarat_perawat']?.toString(),
      lokasiTersedia: json['lokasi_tersedia']?.toString(),
      aktif: json['aktif'] == null
          ? null
          : (json['aktif'] is bool
              ? json['aktif']
              : json['aktif'].toString() == '1'),
      gambarUrl: json['gambar_url']?.toString(),
    );
  }

  String get tipeLayananLabel {
    switch (tipeLayanan) {
      case 'paket':
        return 'Paket';
      case 'single':
      default:
        return 'Single';
    }
  }

  String get syaratPerawatLabel {
    switch (syaratPerawat) {
      case 'icu':
        return 'ICU';
      case 'luka':
        return 'Perawat Luka';
      case 'fisio':
        return 'Fisioterapi';
      case 'anak':
        return 'Perawat Anak';
      case 'lainnya':
        return 'Lainnya';
      case 'umum':
      default:
        return 'Umum';
    }
  }

  String get lokasiLabel {
    switch (lokasiTersedia) {
      case 'rumah':
        return 'Rumah';
      case 'rumah_sakit':
        return 'Rumah Sakit';
      case 'keduanya':
      default:
        return 'Rumah & RS';
    }
  }
}

// =======================
// FORM EDIT DETAIL LAYANAN
// =======================

class _LayananFormDialogDetail extends StatefulWidget {
  final LayananDetail layanan;

  const _LayananFormDialogDetail({required this.layanan});

  @override
  State<_LayananFormDialogDetail> createState() =>
      _LayananFormDialogDetailState();
}

class _LayananFormDialogDetailState
    extends State<_LayananFormDialogDetail> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaC;
  late TextEditingController _deskripsiC;
  late TextEditingController _kategoriC;
  late TextEditingController _jumlahVisitC;
  late TextEditingController _hargaC;
  late TextEditingController _durasiC;

  String _tipeLayanan = 'single';
  String _syaratPerawat = 'umum';
  String _lokasi = 'rumah';
  bool _aktif = true;

  @override
  void initState() {
    super.initState();
    final l = widget.layanan;

    _namaC = TextEditingController(text: l.namaLayanan ?? '');
    _deskripsiC = TextEditingController(text: l.deskripsi ?? '');
    _kategoriC = TextEditingController(text: l.kategori ?? '');
    _jumlahVisitC = TextEditingController(
      text: l.jumlahVisit != null ? l.jumlahVisit.toString() : '',
    );
    _hargaC = TextEditingController(
      text: l.hargaDasar != null ? l.hargaDasar!.toStringAsFixed(0) : '',
    );
    _durasiC = TextEditingController(
      text: l.durasiMenit != null ? l.durasiMenit.toString() : '',
    );

    _tipeLayanan = l.tipeLayanan ?? 'single';

    const allowedSyarat = ['umum', 'icu', 'luka', 'fisio', 'anak', 'lainnya'];
    final rawSyarat = l.syaratPerawat ?? 'umum';
    _syaratPerawat = allowedSyarat.contains(rawSyarat) ? rawSyarat : 'umum';

    _lokasi = l.lokasiTersedia ?? 'rumah';
    _aktif = l.aktif ?? true;
  }

  @override
  void dispose() {
    _namaC.dispose();
    _deskripsiC.dispose();
    _kategoriC.dispose();
    _jumlahVisitC.dispose();
    _hargaC.dispose();
    _durasiC.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final harga = double.tryParse(_hargaC.text.replaceAll('.', ''));
    final durasi =
        _durasiC.text.isEmpty ? null : int.tryParse(_durasiC.text.trim());
    final jVisit =
        _jumlahVisitC.text.isEmpty ? null : int.tryParse(_jumlahVisitC.text);

    final payload = {
      'nama_layanan': _namaC.text.trim(),
      'deskripsi': _deskripsiC.text.trim().isEmpty
          ? null
          : _deskripsiC.text.trim(),
      'kategori': _kategoriC.text.trim().isEmpty
          ? null
          : _kategoriC.text.trim(),
      'tipe_layanan': _tipeLayanan,
      'jumlah_visit': _tipeLayanan == 'paket' ? jVisit : null,
      'harga_dasar': harga ?? 0,
      // ✅ durasi_menit tetap dalam menit, opsional
      'durasi_menit': durasi,
      'syarat_perawat': _syaratPerawat,
      'lokasi_tersedia': _lokasi,
      'aktif': _aktif,
    };

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.layanan != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Layanan' : 'Tambah Layanan'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Layanan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama layanan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _kategoriC,
                  decoration: const InputDecoration(
                    labelText: 'Kategori (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _tipeLayanan,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Layanan',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'single',
                      child: Text('Single (per visit)'),
                    ),
                    DropdownMenuItem(
                      value: 'paket',
                      child: Text('Paket (beberapa visit)'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _tipeLayanan = val ?? 'single';
                    });
                  },
                ),
                const SizedBox(height: 10),
                if (_tipeLayanan == 'paket')
                  TextFormField(
                    controller: _jumlahVisitC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Visit (paket)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (_tipeLayanan == 'paket') {
                        if (v == null || v.trim().isEmpty) {
                          return 'Jumlah visit wajib untuk paket';
                        }
                        if (int.tryParse(v) == null) {
                          return 'Harus angka';
                        }
                      }
                      return null;
                    },
                  ),
                if (_tipeLayanan == 'paket') const SizedBox(height: 10),
                TextFormField(
                  controller: _hargaC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Dasar (Rp)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Harga wajib diisi';
                    }
                    if (double.tryParse(v.replaceAll('.', '')) == null) {
                      return 'Format harga tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                // ✅ Validasi durasi seperti di form lain
                TextFormField(
                  controller: _durasiC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durasi standar (menit, opsional)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return null; // opsional
                    }
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null) {
                      return 'Durasi harus angka menit';
                    }
                    if (parsed < 1) {
                      return 'Minimal 1 menit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _syaratPerawat,
                  decoration: const InputDecoration(
                    labelText: 'Syarat Perawat',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'umum', child: Text('Umum')),
                    DropdownMenuItem(value: 'icu', child: Text('ICU')),
                    DropdownMenuItem(
                      value: 'luka',
                      child: Text('Perawat Luka'),
                    ),
                    DropdownMenuItem(
                      value: 'fisio',
                      child: Text('Fisioterapi'),
                    ),
                    DropdownMenuItem(
                      value: 'anak',
                      child: Text('Perawat Anak'),
                    ),
                    DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _syaratPerawat = val ?? 'umum';
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _lokasi,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Tersedia',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rumah', child: Text('Rumah')),
                    DropdownMenuItem(
                      value: 'rumah_sakit',
                      child: Text('Rumah Sakit'),
                    ),
                    DropdownMenuItem(
                      value: 'keduanya',
                      child: Text('Rumah & Rumah Sakit'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _lokasi = val ?? 'rumah';
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _deskripsiC,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _aktif,
                  title: const Text('Aktif'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() => _aktif = val);
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

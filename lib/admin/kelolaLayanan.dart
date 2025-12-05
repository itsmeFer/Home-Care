import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/admin/detailLayanan.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// supaya bisa pakai HCColor (sesuaikan path kalau beda)
import 'package:home_care/users/HomePage.dart';

class KelolaLayananPage extends StatefulWidget {
  const KelolaLayananPage({super.key});

  @override
  State<KelolaLayananPage> createState() => _KelolaLayananPageState();
}

class _KelolaLayananPageState extends State<KelolaLayananPage> {
  static const String baseUrl = 'http://192.168.1.6:8000/api';

  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  List<Layanan> _layananList = [];

  @override
  void initState() {
    super.initState();
    _fetchLayanan();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchLayanan() async {
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

      final url = Uri.parse('$baseUrl/layanan');
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
              'Gagal mengambil data layanan (kode ${res.statusCode})';
        });
        return;
      }

      final body = json.decode(res.body);
      final success = body['success'] == true;
      if (!success) {
        setState(() {
          _isError = true;
          _errorMessage =
              body['message'] ?? 'Gagal mengambil data layanan dari server.';
        });
        return;
      }

      final List<dynamic> data = body['data'] ?? [];
      final list = data.map((e) => Layanan.fromJson(e)).toList();

      setState(() {
        _layananList = list;
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

  /// Helper untuk ngegabung error validasi dari backend (422)
  String _extractValidationMessage(String rawBody, String defaultMsg) {
    try {
      final body = json.decode(rawBody);
      if (body is Map) {
        // kalau ada message pakai dulu
        final msg = body['message'];
        if (msg is String && msg.isNotEmpty) {
          return msg;
        }
        // kalau ada errors, gabung
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
          if (all.isNotEmpty) {
            return all.join('\n');
          }
        }
      }
    } catch (_) {}
    return defaultMsg;
  }

  Future<void> _createLayanan(Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/layanan');
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
        String msg = 'Gagal membuat layanan (kode ${res.statusCode})';

        if (res.statusCode == 422) {
          // tampilkan error validasi detail
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
          content: Text('Layanan berhasil dibuat'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchLayanan();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat layanan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateLayanan(int id, Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/layanan/$id');
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
          // error validasi
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

      await _fetchLayanan();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupdate layanan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteLayanan(Layanan layanan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Layanan'),
        content: Text(
          'Yakin ingin menghapus layanan "${layanan.namaLayanan}"?',
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

      final url = Uri.parse('$baseUrl/layanan/${layanan.id}');
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

      setState(() {
        _layananList.removeWhere((e) => e.id == layanan.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus layanan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openForm({Layanan? layanan}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LayananFormDialog(layanan: layanan),
    );

    if (result == null) return;

    if (layanan == null) {
      await _createLayanan(result);
    } else {
      await _updateLayanan(layanan.id!, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        title: const Text(
          'Kelola Layanan Home Care',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: _fetchLayanan, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Layanan'),
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
              : _layananList.isEmpty
                  ? const Center(
                      child: Text('Belum ada layanan, tambahkan dulu.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _layananList.length,
                      itemBuilder: (_, i) {
                        final l = _layananList[i];

                        return InkWell(
                          onTap: () async {
                            if (l.id == null) return;

                            final changed = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailLayananPage(layananId: l.id!),
                              ),
                            );

                            // kalau dari detail ada edit/hapus → refresh list
                            if (changed == true) {
                              _fetchLayanan();
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // LEADING
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        HCColor.primary.withOpacity(.1),
                                    backgroundImage: (l.gambarUrl != null &&
                                            l.gambarUrl!.isNotEmpty)
                                        ? NetworkImage(l.gambarUrl!)
                                        : null,
                                    child: (l.gambarUrl == null ||
                                            l.gambarUrl!.isEmpty)
                                        ? Icon(
                                            Icons.medical_services_outlined,
                                            color: HCColor.primaryDark,
                                          )
                                        : null,
                                  ),

                                  const SizedBox(width: 12),

                                  // TITLE + SUBTITLE (INFO LAYANAN)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          l.namaLayanan ?? '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (l.kategori != null &&
                                            l.kategori!.isNotEmpty)
                                          Text(
                                            'Kategori: ${l.kategori}',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        Text(
                                          'Tipe: ${l.tipeLayananLabel} • Syarat: ${l.syaratPerawatLabel}',
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'Lokasi: ${l.lokasiLabel}',
                                          style:
                                              const TextStyle(fontSize: 12),
                                        ),
                                        if (l.hargaDasar != null)
                                          Text(
                                            'Harga: Rp ${l.hargaDasar!.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                fontSize: 12),
                                          ),
                                        if (l.durasiMenit != null)
                                          Text(
                                            'Durasi: ${l.durasiMenit} menit',
                                            style: const TextStyle(
                                                fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // TRAILING (SWITCH + TOMBOL AKSI)
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Transform.scale(
                                        scale: 0.9,
                                        child: Switch(
                                          value: l.aktif ?? true,
                                          onChanged: (val) {
                                            _updateLayanan(
                                                l.id!, {'aktif': val});
                                          },
                                          activeColor: HCColor.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 20),
                                            onPressed: () =>
                                                _openForm(layanan: l),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _deleteLayanan(l),
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

class Layanan {
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

  Layanan({
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

  factory Layanan.fromJson(Map<String, dynamic> json) {
    num? harga;
    if (json['harga_dasar'] != null) {
      if (json['harga_dasar'] is num) {
        harga = json['harga_dasar'] as num;
      } else {
        harga = num.tryParse(json['harga_dasar'].toString());
      }
    }

    return Layanan(
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

class _LayananFormDialog extends StatefulWidget {
  final Layanan? layanan;

  const _LayananFormDialog({this.layanan});

  @override
  State<_LayananFormDialog> createState() => _LayananFormDialogState();
}

class _LayananFormDialogState extends State<_LayananFormDialog> {
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
    _namaC = TextEditingController(text: l?.namaLayanan ?? '');
    _deskripsiC = TextEditingController(text: l?.deskripsi ?? '');
    _kategoriC = TextEditingController(text: l?.kategori ?? '');
    _jumlahVisitC = TextEditingController(
      text: l?.jumlahVisit != null ? l!.jumlahVisit.toString() : '',
    );
    _hargaC = TextEditingController(
      text: l?.hargaDasar != null ? l!.hargaDasar!.toStringAsFixed(0) : '',
    );
    _durasiC = TextEditingController(
      text: l?.durasiMenit != null ? l!.durasiMenit.toString() : '',
    );

    _tipeLayanan = l?.tipeLayanan ?? 'single';
    _syaratPerawat = l?.syaratPerawat ?? 'umum';
    _lokasi = l?.lokasiTersedia ?? 'rumah';
    _aktif = l?.aktif ?? true;
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

    final payload = <String, dynamic>{
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
      // ✅ kirim durasi_menit dalam satuan menit (boleh null)
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

                // ✅ Validasi durasi menit (opsional, tapi kalau diisi minimal 1)
                TextFormField(
                  controller: _durasiC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durasi standar (menit, opsional)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      // opsional → boleh kosong
                      return null;
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

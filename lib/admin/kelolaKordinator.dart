import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Biar bisa pakai HCColor dari HomePage
import 'package:home_care/users/HomePage.dart';

class CrudKordinatorPage extends StatefulWidget {
  const CrudKordinatorPage({super.key});

  @override
  State<CrudKordinatorPage> createState() => _CrudKordinatorPageState();
}

class _CrudKordinatorPageState extends State<CrudKordinatorPage> {
  static const String baseUrl = 'http://192.168.1.6:8000/api';

  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  List<Koordinator> _list = [];

  @override
  void initState() {
    super.initState();
    _fetchKoordinator();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // =========================
  // GET LIST KOORDINATOR
  // =========================
  Future<void> _fetchKoordinator() async {
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

      final url = Uri.parse('$baseUrl/admin/koordinator');
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
              'Gagal mengambil data koordinator (kode ${res.statusCode})';
        });
        return;
      }

      final body = json.decode(res.body);
      if (body is Map && body['success'] == true && body['data'] != null) {
        final List<dynamic> data = body['data'];
        final list = data.map((e) => Koordinator.fromJson(e)).toList();
        setState(() {
          _list = list;
        });
      } else {
        setState(() {
          _isError = true;
          _errorMessage =
              body['message'] ??
              'Gagal mengambil data koordinator dari server.';
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

  // =========================
  // CREATE KOORDINATOR
  // =========================
  Future<void> _createKoordinator(Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/admin/koordinator');
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
        String msg = 'Gagal menambah koordinator (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map) {
            if (body['errors'] != null) {
              // gabung semua pesan error jadi satu string
              final errors = body['errors'] as Map<String, dynamic>;
              final buffer = StringBuffer();
              errors.forEach((key, value) {
                if (value is List && value.isNotEmpty) {
                  buffer.writeln('$key: ${value.first}');
                }
              });
              if (buffer.isNotEmpty) {
                msg = buffer.toString();
              }
            } else if (body['message'] != null) {
              msg = body['message'];
            }
          }
        } catch (_) {}
        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koordinator berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchKoordinator();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambah koordinator: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // UPDATE KOORDINATOR
  // =========================
  Future<void> _updateKoordinator(int id, Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/admin/koordinator/$id');
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
        String msg = 'Gagal mengupdate koordinator (kode ${res.statusCode})';
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
          content: Text('Koordinator berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchKoordinator();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupdate koordinator: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // DELETE KOORDINATOR
  // =========================
  Future<void> _deleteKoordinator(Koordinator k) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Koordinator'),
        content: Text(
          'Yakin ingin menghapus koordinator "${k.namaLengkap ?? '-'}"?',
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

      final url = Uri.parse('$baseUrl/admin/koordinator/${k.id}');
      final res = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        String msg = 'Gagal menghapus koordinator (kode ${res.statusCode})';
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
          content: Text('Koordinator berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _list.removeWhere((e) => e.id == k.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus koordinator: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openForm({Koordinator? koordinator}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _KoordinatorFormDialog(koordinator: koordinator),
    );

    if (result == null) return;

    if (koordinator == null) {
      await _createKoordinator(result);
    } else {
      await _updateKoordinator(koordinator.id!, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        title: const Text(
          'Kelola Koordinator',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _fetchKoordinator,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Koordinator'),
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
          ? const Center(child: Text('Belum ada koordinator, tambahkan dulu.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _list.length,
              itemBuilder: (_, i) {
                final k = _list[i];

                return Card(
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
                              (k.foto != null && k.foto!.isNotEmpty)
                              ? NetworkImage(k.foto!) as ImageProvider
                              : null,
                          child: (k.foto == null || k.foto!.isEmpty)
                              ? Text(
                                  (k.inisial ?? '?'),
                                  style: TextStyle(
                                    color: HCColor.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                k.namaLengkap ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (k.email != null && k.email!.isNotEmpty)
                                Text(
                                  k.email!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (k.noHp != null && k.noHp!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'No HP: ${k.noHp}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                              if (k.wilayah != null &&
                                  k.wilayah!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Wilayah: ${k.wilayah}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
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
                                value: k.isActive ?? true,
                                onChanged: (val) {
                                  if (k.id != null) {
                                    _updateKoordinator(k.id!, {
                                      'is_active': val,
                                    });
                                  }
                                },
                                activeColor: HCColor.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _openForm(koordinator: k),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteKoordinator(k),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// =======================
// MODEL KOORDINATOR
// =======================

class Koordinator {
  final int? id; // id di tabel users
  final String? namaLengkap;
  final String? email;
  final bool? isActive;
  final String? noHp;
  final String? wilayah;
  final String? alamat;
  final String? foto; // URL atau path foto

  Koordinator({
    this.id,
    this.namaLengkap,
    this.email,
    this.isActive,
    this.noHp,
    this.wilayah,
    this.alamat,
    this.foto,
  });

  factory Koordinator.fromJson(Map<String, dynamic> json) {
    final profil = json['koordinator'] as Map<String, dynamic>?;

    final dynamic fotoRaw =
        profil?['foto_url'] ??
        profil?['foto']; // contoh: "/storage/koordinator/koor_xxx.jpg"

    String? fullFoto;
    if (fotoRaw != null) {
      final path = fotoRaw.toString();
      if (path.startsWith('http')) {
        fullFoto = path;
      } else {
        const base = 'http://192.168.1.6:8000'; // host Laravel

        // path dari DB: "/storage/koordinator/koor_xxx.jpg"
        // kita ubah jadi: "/api/media/koordinator/koor_xxx.jpg"
        const storagePrefix = '/storage/';
        String relative = path;

        if (relative.startsWith(storagePrefix)) {
          relative = relative.substring(
            storagePrefix.length,
          ); // "koordinator/koor_xxx.jpg"
        }

        fullFoto = '$base/api/media/$relative';
      }
    }

    return Koordinator(
      id: json['id'] as int?,
      namaLengkap: (profil?['nama_lengkap'] ?? json['name'])?.toString(),
      email: json['email']?.toString(),
      isActive: profil == null || !profil.containsKey('is_active')
          ? null
          : (profil['is_active'] is bool
                ? profil['is_active'] as bool
                : profil['is_active'].toString() == '1'),
      noHp: profil?['no_hp']?.toString(),
      wilayah: profil?['wilayah']?.toString(),
      alamat: profil?['alamat']?.toString(),
      foto: fullFoto,
    );
  }

  /// Dipakai untuk huruf di CircleAvatar, contoh: "Tes Kordinator" -> "TK"
  String? get inisial {
    if (namaLengkap == null || namaLengkap!.isEmpty) return null;
    final parts = namaLengkap!.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// =======================
// FORM DIALOG
// =======================

class _KoordinatorFormDialog extends StatefulWidget {
  final Koordinator? koordinator;

  const _KoordinatorFormDialog({this.koordinator});

  @override
  State<_KoordinatorFormDialog> createState() => _KoordinatorFormDialogState();
}

class _KoordinatorFormDialogState extends State<_KoordinatorFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaC;
  late TextEditingController _emailC;
  late TextEditingController _passwordC;
  late TextEditingController _noHpC;
  late TextEditingController _wilayahC;
  late TextEditingController _alamatC;
  late TextEditingController _nikC;

  bool _isActive = true;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedBytes; // untuk preview di web/mobile
  String? _fotoBase64; // dikirim ke backend

  @override
  void initState() {
    super.initState();
    final k = widget.koordinator;

    _namaC = TextEditingController(text: k?.namaLengkap ?? '');
    _emailC = TextEditingController(text: k?.email ?? '');
    _passwordC = TextEditingController();
    _noHpC = TextEditingController(text: k?.noHp ?? '');
    _wilayahC = TextEditingController(text: k?.wilayah ?? '');
    _alamatC = TextEditingController(text: k?.alamat ?? '');
    _nikC = TextEditingController(); // kalau mau, isi dari data lama saat edit

    _isActive = k?.isActive ?? true;
  }

  @override
  void dispose() {
    _namaC.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    _noHpC.dispose();
    _wilayahC.dispose();
    _alamatC.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _pickedBytes = bytes;
      _fotoBase64 = base64Encode(bytes);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.koordinator != null;

    final payload = <String, dynamic>{
      'name': _namaC.text.trim(),
      'email': _emailC.text.trim(),
      'nik': _nikC.text.trim(), // <-- tambah ini
      'no_hp': _noHpC.text.trim(),
      'wilayah': _wilayahC.text.trim(),
      'alamat': _alamatC.text.trim(),
      'is_active': _isActive,
    };

    if (!isEdit) {
      payload['password'] = _passwordC.text.trim();
    } else {
      if (_passwordC.text.trim().isNotEmpty) {
        payload['password'] = _passwordC.text.trim();
      }
    }

    // kalau ada foto baru dipilih, kirim base64-nya
    if (_fotoBase64 != null) {
      payload['foto_base64'] = _fotoBase64;
    }

    Navigator.pop(context, payload);
  }

  Widget _buildFotoPreview() {
    // kalau baru pilih foto -> pakai bytes (aman di web)
    if (_pickedBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.memory(
          _pickedBytes!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    }

    // kalau sudah ada foto dari server
    final existingFotoUrl = widget.koordinator?.foto;
    if (existingFotoUrl != null && existingFotoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.network(
          existingFotoUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    }

    // default avatar
    return CircleAvatar(
      radius: 40,
      child: Icon(Icons.person, size: 40, color: Colors.grey.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.koordinator != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Koordinator' : 'Tambah Koordinator'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Foto profil
                Center(
                  child: Column(
                    children: [
                      _buildFotoPreview(),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Pilih Foto Profil'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // NIK
                TextFormField(
                  controller: _nikC,
                  decoration: const InputDecoration(
                    labelText: 'NIK',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'NIK wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

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

                // Email
                TextFormField(
                  controller: _emailC,
                  decoration: const InputDecoration(
                    labelText: 'Email (akun login)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!v.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
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

                // Wilayah
                TextFormField(
                  controller: _wilayahC,
                  decoration: const InputDecoration(
                    labelText: 'Wilayah Kerja (contoh: Medan Kota)',
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

                // Password
                TextFormField(
                  controller: _passwordC,
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? 'Password baru (opsional)'
                        : 'Password (akun login)',
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (!isEdit) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Password wajib diisi';
                      }
                      if (v.trim().length < 6) {
                        return 'Minimal 6 karakter';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

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

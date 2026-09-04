import 'package:home_care/core/services/storage_service.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/utils/app_cached_image.dart';

class CrudKategoriPage extends StatefulWidget {
  const CrudKategoriPage({super.key});

  @override
  State<CrudKategoriPage> createState() => _CrudKategoriPageState();
}

class _CrudKategoriPageState extends State<CrudKategoriPage> {
  static String get baseUrl => ApiConstants.apiBase;

  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  final TextEditingController _searchC = TextEditingController();

  List<KategoriLayanan> _kategoriList = [];
  bool? _filterAktif;

  @override
  void initState() {
    super.initState();
    _fetchKategori();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _uploadImageDirect({
    required int kategoriId,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse(
        '$baseUrl/admin/kategori-layanan/$kategoriId/gambar',
      );
      final request = http.MultipartRequest('POST', url);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (kIsWeb) {
        if (imageBytes == null) {
          throw 'File gambar web tidak ditemukan.';
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'gambar',
            imageBytes,
            filename: fileName ?? 'kategori.jpg',
          ),
        );
      } else {
        if (imageFile == null) {
          throw 'File gambar tidak ditemukan.';
        }

        request.files.add(
          await http.MultipartFile.fromPath('gambar', imageFile.path),
        );
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        String msg = 'Gagal upload gambar (kode ${res.statusCode})';
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
          content: Text('Gambar kategori berhasil diupload'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchKategori();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload gambar kategori: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _getToken() => StorageService.getToken();

  String _extractValidationMessage(String rawBody, String defaultMsg) {
    try {
      final body = json.decode(rawBody);
      if (body is Map) {
        final msg = body['message'];
        if (msg is String && msg.isNotEmpty) return msg;

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

  Future<void> _fetchKategori() async {
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

      final queryParams = <String, String>{};
      if (_searchC.text.trim().isNotEmpty) {
        queryParams['search'] = _searchC.text.trim();
      }
      if (_filterAktif != null) {
        queryParams['aktif'] = _filterAktif.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/admin/kategori-layanan',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

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
              'Gagal mengambil data kategori (kode ${res.statusCode})';
        });
        return;
      }

      final body = json.decode(res.body);
      final success = body['success'] == true;
      if (!success) {
        setState(() {
          _isError = true;
          _errorMessage = body['message'] ?? 'Gagal mengambil data kategori.';
        });
        return;
      }

      final List<dynamic> data = body['data'] ?? [];
      setState(() {
        _kategoriList = data.map((e) => KategoriLayanan.fromJson(e)).toList();
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

  Future<void> _createKategori(Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final uri = Uri.parse('$baseUrl/admin/kategori-layanan');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (res.statusCode != 201 && res.statusCode != 200) {
        String msg = 'Gagal membuat kategori (kode ${res.statusCode})';
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
          content: Text('Kategori berhasil dibuat'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchKategori();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat kategori: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateKategori(int id, Map<String, dynamic> payload) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final uri = Uri.parse('$baseUrl/admin/kategori-layanan/$id');
      final res = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (res.statusCode != 200) {
        String msg = 'Gagal mengupdate kategori (kode ${res.statusCode})';
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
          content: Text('Kategori berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchKategori();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupdate kategori: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleKategori(KategoriLayanan item) async {
    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final uri = Uri.parse(
        '$baseUrl/admin/kategori-layanan/${item.id}/toggle',
      );
      final res = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        String msg = 'Gagal mengubah status kategori (${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        throw msg;
      }

      await _fetchKategori();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status kategori: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteKategori(KategoriLayanan item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hapus Kategori'),
            content: Text(
              'Yakin ingin menghapus kategori "${item.namaKategori}"?',
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

      final uri = Uri.parse('$baseUrl/admin/kategori-layanan/${item.id}');
      final res = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        String msg = 'Gagal menghapus kategori (kode ${res.statusCode})';
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
          content: Text('Kategori berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchKategori();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus kategori: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _hapusGambarKategori(KategoriLayanan item) async {
    if (item.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hapus Gambar'),
            content: Text(
              'Yakin ingin menghapus gambar kategori "${item.namaKategori}"?',
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

      final uri = Uri.parse(
        '$baseUrl/admin/kategori-layanan/${item.id}/gambar',
      );
      final res = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        String msg = 'Gagal menghapus gambar (kode ${res.statusCode})';
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
          content: Text('Gambar kategori berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchKategori();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus gambar kategori: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage(KategoriLayanan item) async {
    if (item.id == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (picked == null) return;

      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse(
        '$baseUrl/admin/kategori-layanan/${item.id}/gambar',
      );
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('gambar', bytes, filename: picked.name),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('gambar', picked.path),
        );
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 200) {
        String msg = 'Gagal upload gambar (kode ${res.statusCode})';
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
          content: Text('Gambar kategori berhasil diupload'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchKategori();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload gambar kategori: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openForm({KategoriLayanan? item}) async {
    final result = await showDialog<_KategoriFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _KategoriFormDialog(item: item),
    );

    if (result == null) return;

    if (item == null) {
      await _createKategori(result.payload);

      if (result.imageFile != null || result.imageBytes != null) {
        await _fetchKategori();

        final slug = (result.payload['slug'] ?? '').toString();
        KategoriLayanan? created;
        for (final k in _kategoriList) {
          if ((k.slug ?? '') == slug) {
            created = k;
            break;
          }
        }

        if (created?.id != null) {
          await _uploadImageDirect(
            kategoriId: created!.id!,
            imageFile: result.imageFile,
            imageBytes: result.imageBytes,
            fileName: result.imageName,
          );
        }
      }
    } else {
      await _updateKategori(item.id!, result.payload);

      if (result.imageFile != null || result.imageBytes != null) {
        await _uploadImageDirect(
          kategoriId: item.id!,
          imageFile: result.imageFile,
          imageBytes: result.imageBytes,
          fileName: result.imageName,
        );
      } else {
        await _fetchKategori();
      }
    }
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return HCColor.primary;
    final value = hex.replaceAll('#', '');
    if (value.length != 6) return HCColor.primary;
    return Color(int.parse('FF$value', radix: 16));
  }

  IconData _mapIcon(String? iconName) {
    switch (iconName) {
      case 'medical_services':
        return Icons.medical_services;
      case 'healing':
        return Icons.healing;
      case 'vaccines':
        return Icons.vaccines;
      case 'monitor_heart':
        return Icons.monitor_heart;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'favorite':
        return Icons.favorite;
      case 'elderly':
        return Icons.elderly;
      case 'child_care':
        return Icons.child_care;
      case 'accessible':
        return Icons.accessible;
      default:
        return Icons.category;
    }
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchC,
            decoration: InputDecoration(
              hintText: 'Cari nama kategori atau slug...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchC.text.isEmpty
                      ? null
                      : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchC.clear();
                          _fetchKategori();
                        },
                      ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _fetchKategori(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value:
                      _filterAktif == null
                          ? 'semua'
                          : (_filterAktif == true ? 'aktif' : 'nonaktif'),
                  decoration: InputDecoration(
                    labelText: 'Filter Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'semua', child: Text('Semua')),
                    DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'nonaktif',
                      child: Text('Nonaktif'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      if (val == 'aktif') {
                        _filterAktif = true;
                      } else if (val == 'nonaktif') {
                        _filterAktif = false;
                      } else {
                        _filterAktif = null;
                      }
                    });
                    _fetchKategori();
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _fetchKategori,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Muat'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriCard(KategoriLayanan item) {
    final color = _parseHexColor(item.warna);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
              AppCachedImage(
                imageUrl: item.gambarUrl,
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(12),
                fit: BoxFit.cover,
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_mapIcon(item.icon), color: color, size: 32),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaKategori ?? '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Slug: ${item.slug ?? '-'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if ((item.deskripsi ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.deskripsi!,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(
                        label: item.aktif == true ? 'Aktif' : 'Nonaktif',
                        color:
                            item.aktif == true
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                        textColor:
                            item.aktif == true
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                      ),
                      _chip(
                        label: 'Urutan: ${item.urutan ?? 0}',
                        color: Colors.blue.shade50,
                        textColor: Colors.blue.shade800,
                      ),
                      if (item.warna != null && item.warna!.isNotEmpty)
                        _chip(
                          label: item.warna!,
                          color: color.withOpacity(.12),
                          textColor: color,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (item.gambarUrl != null && item.gambarUrl!.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _hapusGambarKategori(item),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Hapus Gambar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Switch(
                  value: item.aktif ?? false,
                  activeColor: HCColor.primary,
                  onChanged: (_) => _toggleKategori(item),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        _openForm(item: item);
                        break;
                      case 'upload':
                        _pickAndUploadImage(item);
                        break;
                      case 'delete':
                        _deleteKategori(item);
                        break;
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'upload',
                          child: Text('Upload Gambar'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        title: const Text(
          'CRUD Kategori Layanan',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchKategori,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori'),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isError
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage ?? 'Terjadi kesalahan',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                    : _kategoriList.isEmpty
                    ? const Center(child: Text('Belum ada kategori layanan'))
                    : ListView.builder(
                      itemCount: _kategoriList.length,
                      itemBuilder:
                          (_, i) => _buildKategoriCard(_kategoriList[i]),
                    ),
          ),
        ],
      ),
    );
  }
}

class KategoriLayanan {
  final int? id;
  final String? namaKategori;
  final String? slug;
  final String? deskripsi;
  final String? gambar;
  final String? gambarUrl;
  final String? icon;
  final String? warna;
  final int? urutan;
  final bool? aktif;
  final int? createdBy;
  final int? updatedBy;

  KategoriLayanan({
    this.id,
    this.namaKategori,
    this.slug,
    this.deskripsi,
    this.gambar,
    this.gambarUrl,
    this.icon,
    this.warna,
    this.urutan,
    this.aktif,
    this.createdBy,
    this.updatedBy,
  });

  factory KategoriLayanan.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());

    bool? toBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      return v.toString() == '1' || v.toString().toLowerCase() == 'true';
    }

    return KategoriLayanan(
      id: toInt(json['id']),
      namaKategori: json['nama_kategori']?.toString(),
      slug: json['slug']?.toString(),
      deskripsi: json['deskripsi']?.toString(),
      gambar: json['gambar']?.toString(),
      gambarUrl: json['gambar_url']?.toString(),
      icon: json['icon']?.toString(),
      warna: json['warna']?.toString(),
      urutan: toInt(json['urutan']),
      aktif: toBool(json['aktif']),
      createdBy: toInt(json['created_by']),
      updatedBy: toInt(json['updated_by']),
    );
  }
}

class _KategoriFormDialog extends StatefulWidget {
  final KategoriLayanan? item;

  const _KategoriFormDialog({this.item});

  @override
  State<_KategoriFormDialog> createState() => _KategoriFormDialogState();
}

class _KategoriFormDialogState extends State<_KategoriFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaC;
  late TextEditingController _slugC;
  late TextEditingController _deskripsiC;
  late TextEditingController _iconC;
  late TextEditingController _warnaC;
  late TextEditingController _urutanC;

  bool _aktif = true;

  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _namaC = TextEditingController(text: item?.namaKategori ?? '');
    _slugC = TextEditingController(text: item?.slug ?? '');
    _deskripsiC = TextEditingController(text: item?.deskripsi ?? '');
    _iconC = TextEditingController(text: item?.icon ?? '');
    _warnaC = TextEditingController(text: item?.warna ?? '#3B82F6');
    _urutanC = TextEditingController(
      text: item?.urutan != null ? item!.urutan.toString() : '0',
    );

    _aktif = item?.aktif ?? true;
  }

  @override
  void dispose() {
    _namaC.dispose();
    _slugC.dispose();
    _deskripsiC.dispose();
    _iconC.dispose();
    _warnaC.dispose();
    _urutanC.dispose();
    super.dispose();
  }

  String _slugify(String text) {
    final lower = text.toLowerCase().trim();
    final replaced = lower
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    return replaced;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageFile = null;
          _selectedImageName = picked.name;
        });
      } else {
        setState(() {
          _selectedImageFile = File(picked.path);
          _selectedImageBytes = null;
          _selectedImageName = picked.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  Widget _buildImagePreview() {
    final currentUrl = widget.item?.gambarUrl;

    if (_selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _selectedImageBytes!,
          height: 130,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_selectedImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selectedImageFile!,
          height: 130,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (currentUrl != null && currentUrl.isNotEmpty) {
      return AppCachedImage(
        imageUrl: currentUrl,
        height: 130,
        width: double.infinity,
        borderRadius: BorderRadius.circular(12),
        fit: BoxFit.cover,
      );
    }

    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 36, color: Colors.grey),
          SizedBox(height: 8),
          Text('Belum ada gambar', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'nama_kategori': _namaC.text.trim(),
      'slug': _slugC.text.trim().isEmpty ? null : _slugC.text.trim(),
      'deskripsi':
          _deskripsiC.text.trim().isEmpty ? null : _deskripsiC.text.trim(),
      'icon': _iconC.text.trim().isEmpty ? null : _iconC.text.trim(),
      'warna': _warnaC.text.trim().isEmpty ? null : _warnaC.text.trim(),
      'urutan': int.tryParse(_urutanC.text.trim()) ?? 0,
      'aktif': _aktif,
    };

    Navigator.pop(
      context,
      _KategoriFormResult(
        payload: payload,
        imageFile: _selectedImageFile,
        imageBytes: _selectedImageBytes,
        imageName: _selectedImageName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePreview(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: Text(
                          (_selectedImageFile != null ||
                                  _selectedImageBytes != null)
                              ? 'Ganti Gambar'
                              : 'Pilih Gambar',
                        ),
                      ),
                    ),
                    if (_selectedImageFile != null ||
                        _selectedImageBytes != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _removeSelectedImage,
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _namaC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kategori',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    if (_slugC.text.trim().isEmpty || !isEdit) {
                      _slugC.text = _slugify(val);
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama kategori wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _slugC,
                  decoration: const InputDecoration(
                    labelText: 'Slug',
                    hintText: 'contoh: perawatan-luka',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      final ok = RegExp(r'^[a-z0-9-]+$').hasMatch(v.trim());
                      if (!ok) {
                        return 'Slug hanya boleh huruf kecil, angka, dan -';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _iconC,
                  decoration: const InputDecoration(
                    labelText: 'Icon Opsional',
                    hintText: 'contoh: medical_services',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _warnaC,
                  decoration: const InputDecoration(
                    labelText: 'Warna Hex',
                    hintText: '#3B82F6',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final ok = RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v.trim());
                    if (!ok) return 'Format warna harus seperti #3B82F6';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _urutanC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Urutan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (int.tryParse(v.trim()) == null) {
                      return 'Urutan harus angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _deskripsiC,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: _aktif,
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

class _KategoriFormResult {
  final Map<String, dynamic> payload;
  final File? imageFile;
  final Uint8List? imageBytes;
  final String? imageName;

  _KategoriFormResult({
    required this.payload,
    this.imageFile,
    this.imageBytes,
    this.imageName,
  });
}

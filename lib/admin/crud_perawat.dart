import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Biar bisa pakai HCColor dari HomePage
import 'package:home_care/users/HomePage.dart';

class CrudPerawatPage extends StatefulWidget {
  const CrudPerawatPage({super.key});

  @override
  State<CrudPerawatPage> createState() => _CrudPerawatPageState();
}

class _CrudPerawatPageState extends State<CrudPerawatPage> {
  static const String baseUrl = 'http://192.168.1.6:8000/api';

  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  List<PerawatModel> _list = [];

  // filter/search
  final TextEditingController _searchC = TextEditingController();
  String? _filterStatus; // pending/verified/rejected
  int? _filterActive; // 1/0

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
    return prefs.getString('auth_token'); // ✅ samakan dengan dashboard kamu
  }

  // =========================
  // GET LIST PERAWAT
  // =========================
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

      final qp = <String, String>{};
      final s = _searchC.text.trim();
      if (s.isNotEmpty) qp['search'] = s;
      if (_filterStatus != null) qp['status_verifikasi'] = _filterStatus!;
      if (_filterActive != null) qp['is_active'] = _filterActive.toString();

      final url = Uri.parse(
        '$baseUrl/admin/perawat-crud',
      ).replace(queryParameters: qp);

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

      final decoded = json.decode(res.body);
      if (decoded is! Map) {
        setState(() {
          _isError = true;
          _errorMessage = 'Format response tidak sesuai.';
        });
        return;
      }

      // fleksibel: data bisa langsung list atau paginate
      final raw = decoded['data'];
      List<dynamic> dataList = [];
      if (raw is List) {
        dataList = raw;
      } else if (raw is Map && raw['data'] is List) {
        dataList = raw['data'];
      } else {
        dataList = [];
      }

      setState(() {
        _list = dataList
            .map((e) => PerawatModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================
  // CREATE / UPDATE
  // =========================
  Future<void> _savePerawat({PerawatModel? perawat}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PerawatFormDialog(perawat: perawat, apiBase: baseUrl),
    );

    if (payload == null) return;

    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final isEdit = perawat != null;
      final url = isEdit
          ? Uri.parse('$baseUrl/admin/perawat-crud/${perawat.id}')
          : Uri.parse('$baseUrl/admin/perawat-crud');

      final res = isEdit
          ? await http.put(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
              body: json.encode(payload),
            )
          : await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
              body: json.encode(payload),
            );

      if (res.statusCode != 200 && res.statusCode != 201) {
        String msg = 'Gagal menyimpan perawat (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map) {
            if (body['errors'] != null) {
              final errors = body['errors'] as Map<String, dynamic>;
              final buffer = StringBuffer();
              errors.forEach((k, v) {
                if (v is List && v.isNotEmpty) buffer.writeln('$k: ${v.first}');
              });
              if (buffer.isNotEmpty) msg = buffer.toString();
            } else if (body['message'] != null) {
              msg = body['message'];
            }
          }
        } catch (_) {}
        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Perawat berhasil diupdate'
                : 'Perawat berhasil ditambahkan',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchPerawat();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // DELETE
  // =========================
  Future<void> _deletePerawat(PerawatModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Perawat'),
        content: Text('Yakin ingin menghapus perawat "${p.namaLengkap}"?'),
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

      final url = Uri.parse('$baseUrl/admin/perawat-crud/${p.id}');
      final res = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        String msg = 'Gagal menghapus (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) msg = body['message'];
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
          content: Text('Gagal menghapus: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // SET PASSWORD
  // =========================
  Future<void> _setPassword(PerawatModel p) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PasswordDialog(),
    );

    if (password == null) return;

    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/admin/perawat-crud/${p.id}/password');
      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode({'password': password}),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        String msg = 'Gagal set password (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) msg = body['message'];
        } catch (_) {}
        throw msg;
      }

      String emailLogin = '-';
      try {
        final body = json.decode(res.body);
        if (body is Map && body['data'] is Map) {
          emailLogin = (body['data']['login_email'] ?? '-').toString();
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password berhasil di-set. Email login: $emailLogin'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchPerawat();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal set password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // VERIFIKASI
  // =========================
  Future<void> _verifikasi(PerawatModel p) async {
    final result = await showDialog<_VerifyResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VerifikasiDialog(
        initial: p.statusVerifikasi,
        initialNote: p.catatanVerifikasi,
      ),
    );

    if (result == null) return;

    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan.';

      final url = Uri.parse('$baseUrl/admin/perawat-crud/${p.id}/verifikasi');
      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode({
          'status_verifikasi': result.status,
          'catatan_verifikasi': result.note?.trim().isEmpty == true
              ? null
              : result.note,
        }),
      );

      if (res.statusCode != 200) {
        String msg = 'Gagal update status (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) msg = body['message'];
        } catch (_) {}
        throw msg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status verifikasi berhasil diupdate'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchPerawat();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal verifikasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // UI HELPERS
  // =========================
  Color _statusColor(String s) {
    switch (s) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final total = _list.length;
    final verified = _list
        .where((x) => x.statusVerifikasi == 'verified')
        .length;
    final pending = _list.where((x) => x.statusVerifikasi == 'pending').length;
    final rejected = _list
        .where((x) => x.statusVerifikasi == 'rejected')
        .length;
    final active = _list.where((x) => x.isActive == true).length;

    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        title: const Text(
          'CRUD Perawat',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: _fetchPerawat, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HCColor.primary,
        onPressed: () => _savePerawat(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Perawat'),
      ),
      body: Column(
        children: [
          // KPI mini bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Card(
              elevation: 1.5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _miniKpi('Total', '$total'),
                    _miniKpi('Active', '$active'),
                    _miniKpi('Pending', '$pending'),
                    _miniKpi('Verified', '$verified'),
                    _miniKpi('Rejected', '$rejected'),
                  ],
                ),
              ),
            ),
          ),

          // Filter area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 1.5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchC,
                      decoration: InputDecoration(
                        labelText:
                            'Cari perawat (nama / email / hp / NIK / kode)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchC.text.trim().isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _searchC.clear());
                                  _fetchPerawat();
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _fetchPerawat(),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _filterStatus,
                            items: const [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Semua'),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'verified',
                                child: Text('Verified'),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'rejected',
                                child: Text('Rejected'),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _filterStatus = v);
                              _fetchPerawat();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _filterActive,
                            items: const [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Semua'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 1,
                                child: Text('Aktif'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 0,
                                child: Text('Nonaktif'),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _filterActive = v);
                              _fetchPerawat();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _fetchPerawat,
                        icon: const Icon(Icons.search),
                        label: const Text('Terapkan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HCColor.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // list
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
                ? const Center(child: Text('Belum ada perawat.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final p = _list[i];
                      final statusColor = _statusColor(p.statusVerifikasi);

                      final koorText =
                          (p.koordinatorNama != null &&
                              p.koordinatorNama!.trim().isNotEmpty)
                          ? '${p.koordinatorNama} • ID ${p.koordinatorId}'
                          : (p.koordinatorId != null
                                ? 'ID ${p.koordinatorId}'
                                : '-');

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: HCColor.primary.withOpacity(
                                  .1,
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  color: HCColor.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.namaLengkap,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(.10),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            _statusLabel(p.statusVerifikasi),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (p.isActive
                                                        ? Colors.green
                                                        : Colors.grey)
                                                    .withOpacity(.12),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            p.isActive ? 'Aktif' : 'Nonaktif',
                                            style: TextStyle(
                                              color: p.isActive
                                                  ? Colors.green
                                                  : Colors.grey.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Kode: ${p.kodePerawat ?? "-"}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Email: ${p.email ?? "-"}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'HP: ${p.noHp ?? "-"}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'NIK: ${p.nik ?? "-"}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Koordinator: $koorText',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if ((p.catatanVerifikasi ?? '')
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Catatan: ${p.catatanVerifikasi}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _savePerawat(perawat: p),
                                  ),
                                  IconButton(
                                    tooltip: 'Set Password',
                                    icon: const Icon(
                                      Icons.key_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => _setPassword(p),
                                  ),
                                  IconButton(
                                    tooltip: 'Verifikasi',
                                    icon: const Icon(
                                      Icons.verified_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => _verifikasi(p),
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus',
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _miniKpi(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: HCColor.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HCColor.primary.withOpacity(.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: HCColor.primaryDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// MODEL PERAWAT
// =======================
class PerawatModel {
  final int id;
  final String? kodePerawat;
  final String namaLengkap;
  final String? email;
  final String? noHp;
  final String? nik;

  final int? koordinatorId;
  final String? koordinatorNama;

  final String statusVerifikasi; // pending/verified/rejected
  final String? catatanVerifikasi;
  final bool isActive;

  PerawatModel({
    required this.id,
    this.kodePerawat,
    required this.namaLengkap,
    this.email,
    this.noHp,
    this.nik,
    this.koordinatorId,
    this.koordinatorNama,
    required this.statusVerifikasi,
    this.catatanVerifikasi,
    required this.isActive,
  });

  factory PerawatModel.fromJson(Map<String, dynamic> json) {
    final koor = json['koordinator'];
    String? koorNama;
    if (koor is Map) {
      koorNama =
          (koor['nama_lengkap'] ??
                  koor['nama'] ??
                  koor['name'] ??
                  koor['user']?['name'])
              ?.toString();
    }

    return PerawatModel(
      id: (json['id'] ?? 0) is int
          ? (json['id'] ?? 0) as int
          : int.tryParse('${json['id']}') ?? 0,
      kodePerawat: json['kode_perawat']?.toString(),
      namaLengkap: (json['nama_lengkap'] ?? '').toString(),
      email: json['email']?.toString(),
      noHp: json['no_hp']?.toString(),
      nik: json['nik']?.toString(),
      koordinatorId: (json['koordinator_id'] is int)
          ? json['koordinator_id'] as int?
          : int.tryParse('${json['koordinator_id']}'),
      koordinatorNama: koorNama,
      statusVerifikasi: (json['status_verifikasi'] ?? 'pending').toString(),
      catatanVerifikasi: json['catatan_verifikasi']?.toString(),
      isActive: (json['is_active'] ?? 0) == 1 || (json['is_active'] == true),
    );
  }
}

// =======================
// MODEL KOORDINATOR (UNTUK DROPDOWN)
// =======================
class KoordinatorItem {
  final int id;
  final String nama;

  KoordinatorItem({required this.id, required this.nama});

  factory KoordinatorItem.fromJson(Map<String, dynamic> j) {
    final nama =
        (j['nama_lengkap'] ??
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
    );
  }
}

// =======================
// DIALOG FORM PERAWAT
// =======================
class _PerawatFormDialog extends StatefulWidget {
  final PerawatModel? perawat;
  final String apiBase;
  const _PerawatFormDialog({this.perawat, required this.apiBase});

  @override
  State<_PerawatFormDialog> createState() => _PerawatFormDialogState();
}

class _PerawatFormDialogState extends State<_PerawatFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // ⚠️ Sesuaikan endpoint list koordinator admin kamu
  // contoh: /admin/koordinator atau /admin/koordinator-list
  static const String kKoordinatorPath = '/admin/koordinator-list';

  // IDENTITAS
  late TextEditingController _namaC;
  late TextEditingController _nikC;
  String? _jk; // 'L' / 'P'
  DateTime? _tglLahir;
  late TextEditingController _tmpLahirC;

  // KONTAK
  late TextEditingController _emailC;
  late TextEditingController _hpC;

  // KOORDINATOR DROPDOWN
  List<KoordinatorItem> _koors = [];
  bool _loadingKoors = false;
  String? _koorErr;
  int? _selectedKoorId;

  // PROFESIONAL
  late TextEditingController _profesiC;
  late TextEditingController _keahlianC;
  late TextEditingController _noStrC;
  late TextEditingController _noSipC;

  // PENGALAMAN
  late TextEditingController _tahunExpC;
  late TextEditingController _tempatKerjaC;

  // AREA
  late TextEditingController _wilayahC;
  late TextEditingController _alamatC;

  // KONTAK DARURAT
  late TextEditingController _kdNamaC;
  late TextEditingController _kdHpC;
  late TextEditingController _kdHubunganC;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final p = widget.perawat;

    _namaC = TextEditingController(text: p?.namaLengkap ?? '');
    _nikC = TextEditingController(text: p?.nik ?? '');
    _jk = null;
    _tglLahir = null;
    _tmpLahirC = TextEditingController(text: '');

    _emailC = TextEditingController(text: p?.email ?? '');
    _hpC = TextEditingController(text: p?.noHp ?? '');

    _selectedKoorId = p?.koordinatorId;

    _profesiC = TextEditingController(text: '');
    _keahlianC = TextEditingController(text: '');
    _noStrC = TextEditingController(text: '');
    _noSipC = TextEditingController(text: '');

    _tahunExpC = TextEditingController(text: '0');
    _tempatKerjaC = TextEditingController(text: '');

    _wilayahC = TextEditingController(text: '');
    _alamatC = TextEditingController(text: '');

    _kdNamaC = TextEditingController(text: '');
    _kdHpC = TextEditingController(text: '');
    _kdHubunganC = TextEditingController(text: '');

    _isActive = p?.isActive ?? true;

    _fetchKoordinator();
  }

  @override
  void dispose() {
    _namaC.dispose();
    _nikC.dispose();
    _tmpLahirC.dispose();

    _emailC.dispose();
    _hpC.dispose();

    _profesiC.dispose();
    _keahlianC.dispose();
    _noStrC.dispose();
    _noSipC.dispose();

    _tahunExpC.dispose();
    _tempatKerjaC.dispose();

    _wilayahC.dispose();
    _alamatC.dispose();

    _kdNamaC.dispose();
    _kdHpC.dispose();
    _kdHubunganC.dispose();

    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchKoordinator() async {
    setState(() {
      _loadingKoors = true;
      _koorErr = null;
    });

    try {
      final token = await _getToken();
      if (token == null) throw 'Token tidak ditemukan';

      final url = Uri.parse('${widget.apiBase}$kKoordinatorPath');

      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        throw 'Gagal ambil koordinator (kode ${res.statusCode})';
      }

      final decoded = json.decode(res.body);
      final raw = (decoded is Map) ? decoded['data'] : decoded;

      List<dynamic> dataList = [];
      if (raw is List) dataList = raw;
      if (raw is Map && raw['data'] is List) dataList = raw['data'];

      final items = dataList
          .map((e) => KoordinatorItem.fromJson(Map<String, dynamic>.from(e)))
          .where((x) => x.id != 0)
          .toList();

      setState(() => _koors = items);
    } catch (e) {
      setState(() => _koorErr = e.toString());
    } finally {
      if (mounted) setState(() => _loadingKoors = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _tglLahir ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950, 1, 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _tglLahir = picked);
  }

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      // relasi
      'koordinator_id': _selectedKoorId,

      // identitas
      'nama_lengkap': _namaC.text.trim(),
      'nik': _nikC.text.trim().isEmpty ? null : _nikC.text.trim(),
      'jenis_kelamin': _jk, // 'L' / 'P'
      'tanggal_lahir': _tglLahir == null ? null : _fmtDate(_tglLahir!),
      'tempat_lahir': _tmpLahirC.text.trim().isEmpty
          ? null
          : _tmpLahirC.text.trim(),

      // kontak
      'email': _emailC.text.trim().isEmpty ? null : _emailC.text.trim(),
      'no_hp': _hpC.text.trim().isEmpty ? null : _hpC.text.trim(),

      // profesional
      'profesi': _profesiC.text.trim().isEmpty ? null : _profesiC.text.trim(),
      'keahlian': _keahlianC.text.trim().isEmpty
          ? null
          : _keahlianC.text.trim(),
      'no_str': _noStrC.text.trim().isEmpty ? null : _noStrC.text.trim(),
      'no_sip': _noSipC.text.trim().isEmpty ? null : _noSipC.text.trim(),

      // pengalaman
      'tahun_pengalaman': int.tryParse(_tahunExpC.text.trim()) ?? 0,
      'tempat_kerja_terakhir': _tempatKerjaC.text.trim().isEmpty
          ? null
          : _tempatKerjaC.text.trim(),

      // area
      'wilayah': _wilayahC.text.trim().isEmpty ? null : _wilayahC.text.trim(),
      'alamat': _alamatC.text.trim().isEmpty ? null : _alamatC.text.trim(),

      // kontak darurat
      'kontak_darurat_nama': _kdNamaC.text.trim().isEmpty
          ? null
          : _kdNamaC.text.trim(),
      'kontak_darurat_no_hp': _kdHpC.text.trim().isEmpty
          ? null
          : _kdHpC.text.trim(),
      'kontak_darurat_hubungan': _kdHubunganC.text.trim().isEmpty
          ? null
          : _kdHubunganC.text.trim(),

      // status
      'is_active': _isActive,
    };

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.perawat != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Perawat' : 'Tambah Perawat'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _section('Identitas'),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _namaC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nikC,
                        decoration: const InputDecoration(
                          labelText: 'NIK (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _jk,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Kelamin (opsional)',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Pilih')),
                          DropdownMenuItem(
                            value: 'L',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'P',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _jk = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Lahir (opsional)',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _tglLahir == null
                                      ? '-'
                                      : _fmtDate(_tglLahir!),
                                ),
                              ),
                              const Icon(Icons.date_range_outlined),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _tmpLahirC,
                        decoration: const InputDecoration(
                          labelText: 'Tempat Lahir (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                _section('Relasi'),
                const SizedBox(height: 8),

                _loadingKoors
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : (_koorErr != null)
                    ? Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Gagal load koordinator: $_koorErr\n'
                                'Cek endpoint: ${widget.apiBase}$kKoordinatorPath',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: _fetchKoordinator,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<int>(
                        value: _selectedKoorId,
                        decoration: const InputDecoration(
                          labelText: 'Koordinator (opsional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Tanpa Koordinator'),
                          ),
                          ..._koors.map(
                            (k) => DropdownMenuItem<int>(
                              value: k.id,
                              child: Text('${k.nama} • ID ${k.id}'),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedKoorId = v),
                      ),

                const SizedBox(height: 14),
                _section('Kontak'),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailC,
                        decoration: const InputDecoration(
                          labelText: 'Email (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _hpC,
                        decoration: const InputDecoration(
                          labelText: 'No HP (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                _section('Profesional'),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _profesiC,
                  decoration: const InputDecoration(
                    labelText: 'Profesi (opsional) — contoh: Perawat Umum',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _keahlianC,
                  decoration: const InputDecoration(
                    labelText: 'Keahlian (opsional) — contoh: ICU, Luka, Fisio',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _noStrC,
                        decoration: const InputDecoration(
                          labelText: 'No STR (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _noSipC,
                        decoration: const InputDecoration(
                          labelText: 'No SIP (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                _section('Pengalaman'),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tahunExpC,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tahun Pengalaman',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _tempatKerjaC,
                        decoration: const InputDecoration(
                          labelText: 'Tempat Kerja Terakhir (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                _section('Area Kerja'),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _wilayahC,
                  decoration: const InputDecoration(
                    labelText: 'Wilayah (opsional) — contoh: Medan Kota',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _alamatC,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Alamat (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),
                _section('Kontak Darurat'),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _kdNamaC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kontak Darurat (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _kdHpC,
                        decoration: const InputDecoration(
                          labelText: 'No HP Darurat (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _kdHubunganC,
                        decoration: const InputDecoration(
                          labelText: 'Hubungan (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isActive,
                  title: const Text('Aktif'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _isActive = v),
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

  Widget _section(String t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        t,
        style: TextStyle(
          color: HCColor.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 13.5,
        ),
      ),
    );
  }
}

// =======================
// DIALOG PASSWORD
// =======================
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passC = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passC.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _passC.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Password Perawat'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _passC,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password baru',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.trim().length < 6)
                ? 'Minimal 6 karakter'
                : null,
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
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

// =======================
// DIALOG VERIFIKASI
// =======================
class _VerifyResult {
  final String status;
  final String? note;
  _VerifyResult(this.status, this.note);
}

class _VerifikasiDialog extends StatefulWidget {
  final String initial;
  final String? initialNote;

  const _VerifikasiDialog({required this.initial, this.initialNote});

  @override
  State<_VerifikasiDialog> createState() => _VerifikasiDialogState();
}

class _VerifikasiDialogState extends State<_VerifikasiDialog> {
  late String _status;
  late TextEditingController _noteC;

  @override
  void initState() {
    super.initState();
    _status = widget.initial;
    _noteC = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteC.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _VerifyResult(_status, _noteC.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Status Verifikasi'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'verified', child: Text('Verified')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'pending'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteC,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

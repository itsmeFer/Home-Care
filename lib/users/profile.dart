import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:home_care/screen/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String? _error;

  // FOTO PROFIL
  String? _fotoProfilUrl; // URL/path dari API
  File? _localFotoFile; // file lokal yang baru dipilih (mobile)
  bool _isUploadingFoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _pasien;

  static const String baseUrl = 'http://192.168.1.6:8000/api';

  // ---- EDIT MODE ----
  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaC;
  late TextEditingController _nikC;
  late TextEditingController _noHpC;
  late TextEditingController _emailC;
  late TextEditingController _alamatC;
  late TextEditingController _kotaC;
  late TextEditingController _provinsiC;
  late TextEditingController _golonganDarahC;
  late TextEditingController _alergiC;
  late TextEditingController _penyakitMenahunC;

  String? _jenisKelamin; // Laki-laki / Perempuan
  DateTime? _tanggalLahir;

  bool _controllersReady = false;

  @override
  void initState() {
    super.initState();
    _initEmptyControllers();
    _checkAuthAndFetchProfile();
  }

  void _initEmptyControllers() {
    _namaC = TextEditingController();
    _nikC = TextEditingController();
    _noHpC = TextEditingController();
    _emailC = TextEditingController();
    _alamatC = TextEditingController();
    _kotaC = TextEditingController();
    _provinsiC = TextEditingController();
    _golonganDarahC = TextEditingController();
    _alergiC = TextEditingController();
    _penyakitMenahunC = TextEditingController();
  }

  void _initControllersFromPasien() {
    final p = _pasien ?? {};
    _namaC.text = (p['nama_lengkap'] ?? '') as String;
    _nikC.text = (p['nik'] ?? '')?.toString() ?? '';
    _noHpC.text = (p['no_hp'] ?? '')?.toString() ?? '';
    _emailC.text = (p['email'] ?? _user?['email'] ?? '')?.toString() ?? '';
    _alamatC.text = (p['alamat'] ?? '')?.toString() ?? '';
    _kotaC.text = (p['kota'] ?? '')?.toString() ?? '';
    _provinsiC.text = (p['provinsi'] ?? '')?.toString() ?? '';
    _golonganDarahC.text = (p['golongan_darah'] ?? '')?.toString() ?? '';
    _alergiC.text = (p['alergi'] ?? '')?.toString() ?? '';
    _penyakitMenahunC.text = (p['penyakit_menahun'] ?? '')?.toString() ?? '';

    _jenisKelamin = p['jenis_kelamin'] as String?;
    _tanggalLahir = _parseDate(p['tanggal_lahir']);

    _controllersReady = true;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _namaC.dispose();
    _nikC.dispose();
    _noHpC.dispose();
    _emailC.dispose();
    _alamatC.dispose();
    _kotaC.dispose();
    _provinsiC.dispose();
    _golonganDarahC.dispose();
    _alergiC.dispose();
    _penyakitMenahunC.dispose();
    super.dispose();
  }

  /// Ubah path dari API (mis: "/storage/pasien/xxx.jpg")
  /// jadi URL yang lewat proxy CORS: /api/media/...
  String? _resolveMediaUrl(String? raw) {
    if (raw == null) return null;
    String v = raw.trim();
    if (v.isEmpty) return null;

    // Kalau backend sudah kirim full URL: http://192.168.1.6:8000/storage/...
    if (v.startsWith('http://') || v.startsWith('https://')) {
      final uri = Uri.parse(v);

      // ambil path-nya saja: "/storage/pasien/xxx.png"
      String path = uri.path;
      if (path.startsWith('/'))
        path = path.substring(1); // "storage/pasien/xxx.png"

      // arahkan ke route proxy: /api/media/{path}
      // di backend nanti "storage/" dibuang sendiri
      return '${uri.scheme}://${uri.host}:${uri.port}/api/media/$path';
    }

    // Kalau cuma path relatif: "storage/pasien/xxx.png" atau "pasien/xxx.png"
    String path = v;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    const String baseApi = 'http://192.168.1.6:8000/api';
    return '$baseApi/media/$path';
  }

  Future<void> _checkAuthAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    await _fetchProfile();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked == null) return;

    // Untuk preview lokal di Android/iOS
    if (!kIsWeb) {
      final file = File(picked.path);
      setState(() {
        _localFotoFile = file;
      });
    }

    await _uploadFotoProfil(picked);
  }

  Future<void> _uploadFotoProfil(XFile picked) async {
    final pasienId = _pasien?['id'];
    if (pasienId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID pasien tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    setState(() => _isUploadingFoto = true);

    try {
      final uri = Uri.parse('$baseUrl/pasien/$pasienId/foto-profil');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        // WEB: pakai bytes
        final bytes = await picked.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_profil',
            bytes,
            filename: picked.name,
          ),
        );
      } else {
        // MOBILE: pakai path
        request.files.add(
          await http.MultipartFile.fromPath('foto_profil', picked.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengupload foto (kode ${response.statusCode})',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final body = json.decode(response.body);
      if (body is Map && body['success'] == true && body['data'] != null) {
        setState(() {
          _pasien = (body['data'] as Map).cast<String, dynamic>();
          final rawFoto =
              _pasien?['foto_profil_url'] ?? _pasien?['foto_profil'];
          if (rawFoto is String && rawFoto.isNotEmpty) {
            _fotoProfilUrl = _resolveMediaUrl(rawFoto);
            debugPrint('RAW FOTO PROFIL DARI API (upload): $rawFoto');
          } else {
            _fotoProfilUrl = null;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengupload foto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingFoto = false);
    }
  }

  /// Widget avatar profil dengan fallback:
  /// - File lokal (baru di-upload)
  /// - Network image dari `_fotoProfilUrl`
  /// - Inisial nama kalau foto gagal / kosong
  Widget _buildProfileAvatar(String nama) {
    final String initial = (nama.isNotEmpty ? nama[0] : '?').toUpperCase();

    // Kalau ada file lokal (baru pilih dari galeri) di mobile
    if (!kIsWeb && _localFotoFile != null) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFF0BA5A7),
        backgroundImage: FileImage(_localFotoFile!),
      );
    }

    // Kalau ada URL foto dari server
    if (_fotoProfilUrl != null && _fotoProfilUrl!.isNotEmpty) {
      debugPrint('FOTO PROFIL URL: $_fotoProfilUrl');

      return CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFF0BA5A7),
        child: ClipOval(
          child: Image.network(
            _fotoProfilUrl!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Gagal load foto profil ($_fotoProfilUrl): $error');
              return Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Kalau tidak ada foto sama sekali → pakai inisial
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFF0BA5A7),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      final url = Uri.parse('$baseUrl/me'); // GET /api/me
      final res = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (res.statusCode != 200) {
        if (res.statusCode == 401) {
          await prefs.clear();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
          return;
        }

        String msg = 'Gagal memuat profil (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}

        setState(() {
          _error = msg;
          _isLoading = false;
        });
        return;
      }

      final body = json.decode(res.body);
      if (body is! Map || body['success'] != true) {
        setState(() {
          _error = body['message']?.toString() ?? 'Gagal memuat profil';
          _isLoading = false;
        });
        return;
      }

      final data = body['data'] ?? {};
      setState(() {
        _user = (data['user'] ?? {}) as Map<String, dynamic>;
        _pasien = (data['pasien'] ?? {}) as Map<String, dynamic>;

        final rawFoto = _pasien?['foto_profil_url'] ?? _pasien?['foto_profil'];
        if (rawFoto is String && rawFoto.isNotEmpty) {
          _fotoProfilUrl = _resolveMediaUrl(rawFoto);
        } else {
          _fotoProfilUrl = null;
        }

        debugPrint('DEBUG FOTO URL (fetch): $_fotoProfilUrl');

        _isLoading = false;
      });

      _initControllersFromPasien();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        final url = Uri.parse('$baseUrl/logout'); // POST /api/logout
        await http.post(
          url,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }

      await prefs.clear();
    } catch (_) {}

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _startEdit() {
    if (_pasien == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pasien belum tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_controllersReady) {
      _initControllersFromPasien();
    }
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    _initControllersFromPasien();
    setState(() => _isEditing = false);
  }

  Future<void> _pickTanggalLahir() async {
    final now = DateTime.now();
    final initial =
        _tanggalLahir ?? DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() => _tanggalLahir = picked);
    }
  }

  String _formatDisplayDate(dynamic v) {
    if (v == null) return '-';
    try {
      final d = DateTime.parse(v.toString());
      return '${d.day.toString().padLeft(2, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.year}';
    } catch (_) {
      return v.toString();
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Pilih tanggal lahir';
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.year}';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_jenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih jenis kelamin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih tanggal lahir'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pasienId = _pasien?['id'];
    if (pasienId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID pasien tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      final url = Uri.parse('$baseUrl/pasien/$pasienId');
      final res = await http.put(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nama_lengkap': _namaC.text.trim(),
          'nik': _nikC.text.trim().isEmpty ? null : _nikC.text.trim(),
          'no_hp': _noHpC.text.trim(),
          'email': _emailC.text.trim().isEmpty ? null : _emailC.text.trim(),
          'alamat': _alamatC.text.trim(),
          'kota': _kotaC.text.trim(),
          'provinsi': _provinsiC.text.trim(),
          'jenis_kelamin': _jenisKelamin,
          'tanggal_lahir':
              '${_tanggalLahir!.year}-${_tanggalLahir!.month.toString().padLeft(2, '0')}-${_tanggalLahir!.day.toString().padLeft(2, '0')}',
          'golongan_darah': _golonganDarahC.text.trim().isEmpty
              ? null
              : _golonganDarahC.text.trim(),
          'alergi': _alergiC.text.trim().isEmpty ? null : _alergiC.text.trim(),
          'penyakit_menahun': _penyakitMenahunC.text.trim().isEmpty
              ? null
              : _penyakitMenahunC.text.trim(),
        }),
      );

      if (!mounted) return;

      if (res.statusCode != 200) {
        String msg = 'Gagal menyimpan (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          } else if (body is Map && body['errors'] != null) {
            final errors = body['errors'] as Map<String, dynamic>;
            final firstKey = errors.keys.first;
            final firstErrorList = errors[firstKey];
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              msg = firstErrorList.first.toString();
            }
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      final body = json.decode(res.body);
      if (body is Map && body['success'] == true && body['data'] != null) {
        setState(() {
          _pasien = (body['data'] as Map).cast<String, dynamic>();
          _isEditing = false;
        });
      } else {
        _fetchProfile();
        _isEditing = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final nama = _pasien?['nama_lengkap'] ?? _user?['name'] ?? 'Pasien';
    final noRm = _pasien?['no_rekam_medis'] ?? '-';
    final noHp = _pasien?['no_hp'] ?? '-';
    final email = _user?['email'] ?? _pasien?['email'] ?? '-';
    final jk = _pasien?['jenis_kelamin'] ?? '-';
    final tglLahirRaw = _pasien?['tanggal_lahir'];
    final tglLahir = _formatDisplayDate(tglLahirRaw);

    final nik = _pasien?['nik'] ?? '-';
    final alamat = _pasien?['alamat'] ?? '-';
    final kota = _pasien?['kota'] ?? '-';
    final provinsi = _pasien?['provinsi'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: const Color(0xFF0BA5A7),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _pasien != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              tooltip: _isEditing ? 'Batal' : 'Edit Profil',
              onPressed: _isEditing ? _cancelEdit : _startEdit,
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _fetchProfile,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : (_isEditing
                ? _buildEditMode(theme, nama, noRm)
                : _buildViewMode(
                    theme,
                    nama,
                    noRm,
                    noHp,
                    email,
                    jk,
                    tglLahir,
                    nik,
                    alamat,
                    kota,
                    provinsi,
                  )),
    );
  }

  Widget _buildViewMode(
    ThemeData theme,
    String nama,
    String noRm,
    String noHp,
    String email,
    String jk,
    String tglLahir,
    String nik,
    String alamat,
    String kota,
    String provinsi,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // HEADER PROFIL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(children: [_buildProfileAvatar(nama)]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No. Rekam Medis: $noRm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Data Pribadi',
            children: [
              _InfoRow(label: 'NIK', value: nik),
              _InfoRow(label: 'Jenis Kelamin', value: jk),
              _InfoRow(label: 'Tanggal Lahir', value: tglLahir),
            ],
          ),

          const SizedBox(height: 12),

          _SectionCard(
            title: 'Kontak & Alamat',
            children: [
              _InfoRow(label: 'No. HP', value: noHp),
              _InfoRow(label: 'Email', value: email),
              _InfoRow(label: 'Alamat', value: alamat),
              _InfoRow(label: 'Kota', value: kota),
              _InfoRow(label: 'Provinsi', value: provinsi),
            ],
          ),

          const SizedBox(height: 12),

          _SectionCard(
            title: 'Info Medis Dasar',
            children: [
              _InfoRow(
                label: 'Golongan Darah',
                value: (_pasien?['golongan_darah'] ?? '-') as String,
              ),
              _InfoRow(
                label: 'Alergi',
                value: (_pasien?['alergi'] ?? '-') as String,
              ),
              _InfoRow(
                label: 'Penyakit Menahun',
                value: (_pasien?['penyakit_menahun'] ?? '-') as String,
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _logout,
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(ThemeData theme, String nama, String noRm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          // HEADER (tetap tampil)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    _buildProfileAvatar(nama),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _isUploadingFoto ? null : _pickAndUploadPhoto,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white,
                          child: _isUploadingFoto
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Color(0xFF0BA5A7),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No. Rekam Medis: $noRm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // FORM EDIT
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _namaC,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nikC,
                    decoration: const InputDecoration(
                      labelText: 'NIK (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Jenis Kelamin',
                            border: OutlineInputBorder(),
                          ),
                          value: _jenisKelamin,
                          items: const [
                            DropdownMenuItem(
                              value: 'Laki-laki',
                              child: Text('Laki-laki'),
                            ),
                            DropdownMenuItem(
                              value: 'Perempuan',
                              child: Text('Perempuan'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _jenisKelamin = v),
                          validator: (v) {
                            if (v == null) {
                              return 'Pilih jenis kelamin';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: _pickTanggalLahir,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Lahir',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _formatDate(_tanggalLahir),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _tanggalLahir == null
                                          ? Colors.black45
                                          : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _noHpC,
                    decoration: const InputDecoration(
                      labelText: 'No. HP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'No. HP wajib diisi';
                      }
                      if (v.length < 8) {
                        return 'No. HP terlalu pendek';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailC,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _alamatC,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alamat',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _kotaC,
                          decoration: const InputDecoration(
                            labelText: 'Kota/Kabupaten',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _provinsiC,
                          decoration: const InputDecoration(
                            labelText: 'Provinsi',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _golonganDarahC,
                    decoration: const InputDecoration(
                      labelText: 'Golongan Darah (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _alergiC,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alergi (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _penyakitMenahunC,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Penyakit Menahun (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _cancelEdit,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0BA5A7),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final muted = Colors.black54;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

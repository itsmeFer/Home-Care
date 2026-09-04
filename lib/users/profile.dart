import 'package:home_care/features/profile/presentation/widgets/profile_ui_components.dart';
import 'package:home_care/core/services/wilayah_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/screen/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String? _error;
  static const int _maxPhotoBytes = 2 * 1024 * 1024;
  String? _fotoProfilUrl;
  File? _localFotoFile;
  bool _isUploadingFoto = false;
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _pasien;

  static String get baseUrl => ApiConstants.apiBase;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isPreparingEditForm = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaC;
  late TextEditingController _nikC;
  late TextEditingController _noHpC;
  late TextEditingController _emailC;
  late TextEditingController _alamatC;
  late TextEditingController _kodePosC;
  late TextEditingController _golonganDarahC;
  late TextEditingController _alergiC;
  late TextEditingController _penyakitMenahunC;

  String? _jenisKelamin;
  DateTime? _tanggalLahir;

  String? _selectedProvinsiId;
  String? _selectedKotaId;
  String? _selectedKecamatanId;
  String? _selectedKelurahanId;

  String? _selectedProvinsiNama;
  String? _selectedKotaNama;
  String? _selectedKecamatanNama;
  String? _selectedKelurahanNama;

  List<Map<String, String>> _provinsiList = [];
  List<Map<String, String>> _kotaList = [];
  List<Map<String, String>> _kecamatanList = [];
  List<Map<String, String>> _kelurahanList = [];

  bool _isLoadingProvinsi = false;
  bool _isLoadingKota = false;
  bool _isLoadingKecamatan = false;
  bool _isLoadingKelurahan = false;

  bool _controllersReady = false;

  static const Color _primary = Color(0xFF0BA5A7);
  static const Color _primaryDark = Color(0xFF087F81);
  static const Color _bg = Color(0xFFF4F7FB);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF1F2937);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  bool get _isAnyWilayahLoading =>
      _isLoadingProvinsi ||
      _isLoadingKota ||
      _isLoadingKecamatan ||
      _isLoadingKelurahan;

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
    _kodePosC = TextEditingController();
    _golonganDarahC = TextEditingController();
    _alergiC = TextEditingController();
    _penyakitMenahunC = TextEditingController();
  }

  void _initControllersFromPasien() {
    final p = _pasien ?? {};
    _namaC.text = (p['nama_lengkap'] ?? '').toString();
    _nikC.text = (p['nik'] ?? '').toString();
    _noHpC.text = (p['no_hp'] ?? '').toString();
    _emailC.text = (p['email'] ?? _user?['email'] ?? '').toString();
    _alamatC.text = (p['alamat'] ?? '').toString();
    _kodePosC.text = (p['kode_pos'] ?? '').toString();
    _golonganDarahC.text = (p['golongan_darah'] ?? '').toString();
    _alergiC.text = (p['alergi'] ?? '').toString();
    _penyakitMenahunC.text = (p['penyakit_menahun'] ?? '').toString();

    _jenisKelamin = p['jenis_kelamin']?.toString();
    _tanggalLahir = _parseDate(p['tanggal_lahir']);

    _selectedProvinsiId = p['provinsi_id']?.toString().trim();
    _selectedKotaId = p['kota_id']?.toString().trim();
    _selectedKecamatanId = p['kecamatan_id']?.toString().trim();
    _selectedKelurahanId = p['kelurahan_id']?.toString().trim();

    _selectedProvinsiNama = p['provinsi']?.toString();
    _selectedKotaNama = p['kota']?.toString();
    _selectedKecamatanNama = p['kecamatan']?.toString();
    _selectedKelurahanNama = p['kelurahan']?.toString();

    _seedWilayahDropdownFromPasien();

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
    _kodePosC.dispose();
    _golonganDarahC.dispose();
    _alergiC.dispose();
    _penyakitMenahunC.dispose();
    super.dispose();
  }

  double _maxContentWidth(double width) {
    if (width >= 1200) return 900;
    if (width >= 900) return 760;
    if (width >= 600) return 620;
    return width;
  }

  EdgeInsets _pagePadding(double width) {
    if (width >= 900) {
      return const EdgeInsets.symmetric(horizontal: 28, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  Future<Uint8List> _compressImageUntilFit(Uint8List originalBytes) async {
    if (originalBytes.lengthInBytes <= _maxPhotoBytes) {
      return originalBytes;
    }

    Uint8List currentBytes = originalBytes;

    const qualities = [80, 70, 60, 50, 40, 30, 20];

    for (final quality in qualities) {
      final compressed = await FlutterImageCompress.compressWithList(
        currentBytes,
        quality: quality,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (compressed.isNotEmpty) {
        currentBytes = Uint8List.fromList(compressed);
      }

      if (currentBytes.lengthInBytes <= _maxPhotoBytes) {
        return currentBytes;
      }
    }

    return currentBytes;
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        color: _textSoft,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(color: Colors.black38),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  Widget _buildFieldLoading() {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  String? _resolveMediaUrl(String? raw) => ApiConstants.resolveMediaUrl(raw);

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

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await StorageService.getToken();

      if (token == null) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      final body = await ApiClient.get('/me');

      if (!mounted) return;

      if (body is! Map || body['success'] != true) {
        setState(() {
          _error = body is Map
              ? (body['message']?.toString() ?? 'Gagal memuat profil')
              : 'Gagal memuat profil';
          _isLoading = false;
        });
        return;
      }

      final data = (body['data'] ?? {}) as Map<String, dynamic>;
      setState(() {
        _user = (data['user'] ?? {}) as Map<String, dynamic>;
        _pasien = (data['pasien'] ?? {}) as Map<String, dynamic>;

        final rawFoto = _pasien?['foto_profil_url'] ?? _pasien?['foto_profil'];
        if (rawFoto is String && rawFoto.isNotEmpty) {
          _fotoProfilUrl = _resolveMediaUrl(rawFoto);
        } else {
          _fotoProfilUrl = null;
        }

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

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (picked == null) return;
      if (!mounted) return;

      setState(() {
        _isUploadingFoto = true;
      });

      Uint8List uploadBytes;

      if (kIsWeb) {
        uploadBytes = await picked.readAsBytes();
      } else {
        uploadBytes = await File(picked.path).readAsBytes();
      }

      uploadBytes = await _compressImageUntilFit(uploadBytes);

      if (uploadBytes.lengthInBytes > _maxPhotoBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ukuran foto masih terlalu besar. Coba pilih foto lain yang lebih kecil.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isUploadingFoto = false);
        return;
      }

      if (!kIsWeb) {
        final file = File(picked.path);
        setState(() {
          _localFotoFile = file;
        });
      }

      await _uploadFotoProfilBytes(bytes: uploadBytes, fileName: picked.name);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _friendlyUploadMessage(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('must not be greater than 2048 kilobytes')) {
      return 'Ukuran foto terlalu besar. Maksimal 2 MB ya.';
    }

    if (msg.contains('validation failed')) {
      return 'Foto belum bisa diupload. Coba periksa ukuran atau format file.';
    }

    return message;
  }

  Future<void> _uploadFotoProfilBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final pasienId = _pasien?['id'];
    if (pasienId == null) {
      if (!mounted) return;
      setState(() => _isUploadingFoto = false);
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
      setState(() => _isUploadingFoto = false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/pasien/$pasienId/foto-profil');

      final request =
          http.MultipartRequest('POST', uri)
            ..headers['Accept'] = 'application/json'
            ..headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'foto_profil',
          bytes,
          filename: fileName.isEmpty ? 'foto_profil.jpg' : fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      dynamic body;
      try {
        body = json.decode(response.body);
      } catch (_) {
        body = null;
      }

      if (response.statusCode != 200) {
        String msg = 'Gagal upload foto (kode ${response.statusCode})';

        if (body is Map) {
          if (body['message'] != null) {
            msg = body['message'].toString();
          }

          if (body['errors'] is Map) {
            final errors = body['errors'] as Map<String, dynamic>;
            if (errors['foto_profil'] is List &&
                (errors['foto_profil'] as List).isNotEmpty) {
              msg = (errors['foto_profil'] as List).first.toString();
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyUploadMessage(msg)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (body is Map && body['success'] == true && body['data'] != null) {
        setState(() {
          _pasien = (body['data'] as Map).cast<String, dynamic>();
          final rawFoto =
              _pasien?['foto_profil_url'] ?? _pasien?['foto_profil'];

          if (rawFoto is String && rawFoto.isNotEmpty) {
            _fotoProfilUrl = _resolveMediaUrl(rawFoto);
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
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingFoto = false);
    }
  }

  Future<void> _logout() async {
    try {
      await ApiClient.post('/logout');
    } catch (_) {}

    await StorageService.clearAuth();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _startEdit() async {
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
    } else {
      _seedWilayahDropdownFromPasien();
    }

    setState(() {
      _isPreparingEditForm = true;
      _isEditing = true;
    });

    try {
      await _loadProvinsi();

      if ((_selectedProvinsiId ?? '').isNotEmpty) {
        await _loadKota(_selectedProvinsiId!);
      }

      if ((_selectedKotaId ?? '').isNotEmpty) {
        await _loadKecamatan(_selectedKotaId!);
      }

      if ((_selectedKecamatanId ?? '').isNotEmpty) {
        await _loadKelurahan(_selectedKecamatanId!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPreparingEditForm = false;
        });
      }
    }
  }

  void _cancelEdit() {
    _initControllersFromPasien();
    setState(() {
      _isEditing = false;
      _isPreparingEditForm = false;
    });
  }

  void _seedWilayahDropdownFromPasien() {
    _provinsiList = [];
    _kotaList = [];
    _kecamatanList = [];
    _kelurahanList = [];

    if ((_selectedProvinsiId ?? '').isNotEmpty &&
        (_selectedProvinsiNama ?? '').isNotEmpty) {
      _provinsiList.add({
        'id': _selectedProvinsiId!,
        'name': _selectedProvinsiNama!,
      });
    }

    if ((_selectedKotaId ?? '').isNotEmpty &&
        (_selectedKotaNama ?? '').isNotEmpty) {
      _kotaList.add({'id': _selectedKotaId!, 'name': _selectedKotaNama!});
    }

    if ((_selectedKecamatanId ?? '').isNotEmpty &&
        (_selectedKecamatanNama ?? '').isNotEmpty) {
      _kecamatanList.add({
        'id': _selectedKecamatanId!,
        'name': _selectedKecamatanNama!,
      });
    }

    if ((_selectedKelurahanId ?? '').isNotEmpty &&
        (_selectedKelurahanNama ?? '').isNotEmpty) {
      _kelurahanList.add({
        'id': _selectedKelurahanId!,
        'name': _selectedKelurahanNama!,
      });
    }
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

  Future<void> _loadProvinsi() async {
    setState(() => _isLoadingProvinsi = true);
    try {
      final list = await WilayahService.fetchProvinsi();
      if (!mounted) return;
      setState(() => _provinsiList = list);
    } catch (e) {
      debugPrint('Error loading provinsi: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProvinsi = false);
    }
  }

  Future<void> _loadKota(String provinsiId) async {
    final existingKotaId = _selectedKotaId;

    setState(() {
      _isLoadingKota = true;
      _kotaList = [];
      _kecamatanList = [];
      _kelurahanList = [];
      if (existingKotaId == null || existingKotaId.isEmpty) {
        _selectedKotaId = null;
        _selectedKecamatanId = null;
        _selectedKelurahanId = null;
        _selectedKotaNama = null;
        _selectedKecamatanNama = null;
        _selectedKelurahanNama = null;
      }
    });

    try {
      final list = await WilayahService.fetchKota(provinsiId);
      if (!mounted) return;
      setState(() {
        _kotaList = list;
        if (existingKotaId != null && existingKotaId.isNotEmpty) {
          final exists = _kotaList.any((e) => e['id'] == existingKotaId);
          if (!exists) {
            _selectedKotaId = null;
            _selectedKotaNama = null;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading kota: $e');
    } finally {
      if (mounted) setState(() => _isLoadingKota = false);
    }
  }

  Future<void> _loadKecamatan(String kotaId) async {
    final existingKecamatanId = _selectedKecamatanId;

    setState(() {
      _isLoadingKecamatan = true;
      _kecamatanList = [];
      _kelurahanList = [];
      if (existingKecamatanId == null || existingKecamatanId.isEmpty) {
        _selectedKecamatanId = null;
        _selectedKelurahanId = null;
        _selectedKecamatanNama = null;
        _selectedKelurahanNama = null;
      }
    });

    try {
      final list = await WilayahService.fetchKecamatan(kotaId);
      if (!mounted) return;
      setState(() {
        _kecamatanList = list;
        if (existingKecamatanId != null && existingKecamatanId.isNotEmpty) {
          final exists = _kecamatanList.any(
            (e) => e['id'] == existingKecamatanId,
          );
          if (!exists) {
            _selectedKecamatanId = null;
            _selectedKecamatanNama = null;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading kecamatan: $e');
    } finally {
      if (mounted) setState(() => _isLoadingKecamatan = false);
    }
  }

  Future<void> _loadKelurahan(String kecamatanId) async {
    final existingKelurahanId = _selectedKelurahanId;

    setState(() {
      _isLoadingKelurahan = true;
      _kelurahanList = [];
      if (existingKelurahanId == null || existingKelurahanId.isEmpty) {
        _selectedKelurahanId = null;
        _selectedKelurahanNama = null;
      }
    });

    try {
      final list = await WilayahService.fetchKelurahan(kecamatanId);
      if (!mounted) return;
      setState(() {
        _kelurahanList = list;
        if (existingKelurahanId != null && existingKelurahanId.isNotEmpty) {
          final exists = _kelurahanList.any(
            (e) => e['id'] == existingKelurahanId,
          );
          if (!exists) {
            _selectedKelurahanId = null;
            _selectedKelurahanNama = null;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading kelurahan: $e');
    } finally {
      if (mounted) setState(() => _isLoadingKelurahan = false);
    }
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

    if (_selectedProvinsiId == null || _selectedProvinsiNama == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih provinsi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedKotaId == null || _selectedKotaNama == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih kota/kabupaten'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedKecamatanId == null || _selectedKecamatanNama == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih kecamatan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_kodePosC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi kode pos'),
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

      final payload = {
        'nama_lengkap': _namaC.text.trim(),
        'nik': _nikC.text.trim().isEmpty ? null : _nikC.text.trim(),
        'no_hp': _noHpC.text.trim(),
        'email': _emailC.text.trim().isEmpty ? null : _emailC.text.trim(),
        'alamat': _alamatC.text.trim(),
        'provinsi_id': _selectedProvinsiId,
        'kota_id': _selectedKotaId,
        'kecamatan_id': _selectedKecamatanId,
        'kelurahan_id': _selectedKelurahanId,
        'provinsi': _selectedProvinsiNama,
        'kota': _selectedKotaNama,
        'kecamatan': _selectedKecamatanNama,
        'kelurahan': _selectedKelurahanNama,
        'kode_pos': _kodePosC.text.trim(),
        'jenis_kelamin': _jenisKelamin,
        'tanggal_lahir':
            '${_tanggalLahir!.year}-${_tanggalLahir!.month.toString().padLeft(2, '0')}-${_tanggalLahir!.day.toString().padLeft(2, '0')}',
        'golongan_darah':
            _golonganDarahC.text.trim().isEmpty
                ? null
                : _golonganDarahC.text.trim(),
        'alergi': _alergiC.text.trim().isEmpty ? null : _alergiC.text.trim(),
        'penyakit_menahun':
            _penyakitMenahunC.text.trim().isEmpty
                ? null
                : _penyakitMenahunC.text.trim(),
      };

      final res = await http.put(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (!mounted) return;

      if (res.statusCode != 200) {
        String msg = 'Gagal menyimpan (kode ${res.statusCode})';
        try {
          final body = json.decode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'].toString();
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
        await _fetchProfile();
        setState(() => _isEditing = false);
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

  Widget _buildProfileAvatar(String nama) {
    final String initial = (nama.isNotEmpty ? nama[0] : '?').toUpperCase();

    if (!kIsWeb && _localFotoFile != null) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: _primary,
        backgroundImage: FileImage(_localFotoFile!),
      );
    }

    if (_fotoProfilUrl != null && _fotoProfilUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: _primary,
        child: ClipOval(
          child: Image.network(
            _fotoProfilUrl!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
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

    return CircleAvatar(
      radius: 28,
      backgroundColor: _primary,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final nama =
        (_pasien?['nama_lengkap'] ?? _user?['name'] ?? 'Pasien').toString();
    final noRm = (_pasien?['no_rekam_medis'] ?? '-').toString();
    final noHp = (_pasien?['no_hp'] ?? '-').toString();
    final email = (_user?['email'] ?? _pasien?['email'] ?? '-').toString();
    final jk = (_pasien?['jenis_kelamin'] ?? '-').toString();
    final tglLahirRaw = _pasien?['tanggal_lahir'];
    final tglLahir = _formatDisplayDate(tglLahirRaw);

    final nik = (_pasien?['nik'] ?? '-').toString();
    final alamat = (_pasien?['alamat'] ?? '-').toString();
    final kodePos = (_pasien?['kode_pos'] ?? '-').toString();

    final provinsi = (_pasien?['provinsi'] ?? '-').toString();
    final kota = (_pasien?['kota'] ?? '-').toString();
    final kecamatan = (_pasien?['kecamatan'] ?? '-').toString();
    final kelurahan = (_pasien?['kelurahan'] ?? '-').toString();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _pasien != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded),
              tooltip: _isEditing ? 'Batal' : 'Edit Profil',
              onPressed: _isEditing ? _cancelEdit : _startEdit,
            ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const _ProfilePageSkeleton()
                : _error != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      constraints: const BoxConstraints(maxWidth: 420),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 44,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _fetchProfile,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = _maxContentWidth(constraints.maxWidth);
                    final padding = _pagePadding(constraints.maxWidth);

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Padding(
                          padding: padding,
                          child:
                              _isEditing
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
                                    kodePos,
                                    provinsi,
                                    kota,
                                    kecamatan,
                                    kelurahan,
                                  ),
                        ),
                      ),
                    );
                  },
                ),
      ),
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
    String kodePos,
    String provinsi,
    String kota,
    String kecamatan,
    String kelurahan,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  color: _primary.withOpacity(0.22),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildProfileAvatar(nama),
                const SizedBox(height: 14),
                Text(
                  nama,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No. Rekam Medis: $noRm',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Data Pribadi',
            icon: Icons.badge_outlined,
            children: [
              _InfoRow(label: 'NIK', value: nik),
              _InfoRow(label: 'Jenis Kelamin', value: jk),
              _InfoRow(label: 'Tanggal Lahir', value: tglLahir),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Kontak & Alamat',
            icon: Icons.location_on_outlined,
            children: [
              _InfoRow(label: 'No. HP', value: noHp),
              _InfoRow(label: 'Email', value: email),
              _InfoRow(label: 'Alamat', value: alamat),
              _InfoRow(label: 'Kelurahan', value: kelurahan),
              _InfoRow(label: 'Kecamatan', value: kecamatan),
              _InfoRow(label: 'Kota/Kab', value: kota),
              _InfoRow(label: 'Provinsi', value: provinsi),
              _InfoRow(label: 'Kode Pos', value: kodePos),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Info Medis Dasar',
            icon: Icons.medical_information_outlined,
            children: [
              _InfoRow(
                label: 'Golongan Darah',
                value: (_pasien?['golongan_darah'] ?? '-').toString(),
              ),
              _InfoRow(
                label: 'Alergi',
                value: (_pasien?['alergi'] ?? '-').toString(),
              ),
              _InfoRow(
                label: 'Penyakit Menahun',
                value: (_pasien?['penyakit_menahun'] ?? '-').toString(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Pengaturan & Keamanan',
            icon: Icons.settings_outlined,
            children: [
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF0BA5A7)),
                title: const Text('Kebijakan Privasi (Privacy Policy)', style: TextStyle(fontFamily: 'Poppins', fontSize: 13.8, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
                trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.black54),
                onTap: () async {
                  final url = Uri.parse('https://royal-klinik.cloud/privacy-homecare.html');
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak dapat membuka link Kebijakan Privasi')),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                title: const Text('Hapus Akun', style: TextStyle(fontFamily: 'Poppins', fontSize: 13.8, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.black54),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text(
                        'Apakah Anda yakin ingin menghapus akun secara permanen? Semua data medis, riwayat pemesanan, dan profil Anda akan dihapus dan tidak dapat dipulihkan kembali.',
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: Colors.black54)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final Uri url = Uri.parse('${ApiConstants.baseUrl}/delete-account');
                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tidak dapat membuka halaman penghapusan akun')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ya, Hapus'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFE53935)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEBEE),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _logout,
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w700, 
                  fontSize: 16, 
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(ThemeData theme, String nama, String noRm) {
    if (_isPreparingEditForm) {
      return const _EditProfileSkeleton();
    }

    final width = MediaQuery.of(context).size.width;
    final bool twoColumn = width >= 700;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primary, _primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  color: _primary.withOpacity(0.22),
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
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                                color: Colors.black.withOpacity(0.12),
                              ),
                            ],
                          ),
                          child:
                              _isUploadingFoto
                                  ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: _primary,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No. Rekam Medis: $noRm',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Lengkapi data profil Anda dengan informasi terbaru.',
                        style: TextStyle(color: Colors.white70, fontSize: 12.8),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Gunakan foto JPG/PNG dengan ukuran maksimal 2 MB.',
                        style: TextStyle(color: Colors.white70, fontSize: 11.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  color: Colors.black.withOpacity(0.05),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (twoColumn)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNamaField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildNikField()),
                      ],
                    )
                  else ...[
                    _buildNamaField(),
                    const SizedBox(height: 12),
                    _buildNikField(),
                  ],
                  const SizedBox(height: 12),
                  if (twoColumn)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildJenisKelaminField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTanggalLahirField()),
                      ],
                    )
                  else ...[
                    _buildJenisKelaminField(),
                    const SizedBox(height: 12),
                    _buildTanggalLahirField(),
                  ],
                  const SizedBox(height: 12),
                  if (twoColumn)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNoHpField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildEmailField()),
                      ],
                    )
                  else ...[
                    _buildNoHpField(),
                    const SizedBox(height: 12),
                    _buildEmailField(),
                  ],
                  const SizedBox(height: 12),
                  _buildAlamatField(),
                  const SizedBox(height: 12),
                  if (twoColumn)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildProvinsiField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKotaField()),
                      ],
                    )
                  else ...[
                    _buildProvinsiField(),
                    const SizedBox(height: 12),
                    _buildKotaField(),
                  ],
                  const SizedBox(height: 12),
                  if (twoColumn)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildKecamatanField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKelurahanField()),
                      ],
                    )
                  else ...[
                    _buildKecamatanField(),
                    const SizedBox(height: 12),
                    _buildKelurahanField(),
                  ],
                  const SizedBox(height: 12),
                  if (twoColumn)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildKodePosField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildGolonganDarahField()),
                      ],
                    )
                  else ...[
                    _buildKodePosField(),
                    const SizedBox(height: 12),
                    _buildGolonganDarahField(),
                  ],
                  const SizedBox(height: 12),
                  _buildAlergiField(),
                  const SizedBox(height: 12),
                  _buildPenyakitMenahunField(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _cancelEdit,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            side: const BorderSide(color: _border),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveProfile,
                          child:
                              _isSaving
                                  ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'Simpan Perubahan',
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

  Widget _buildNamaField() {
    return TextFormField(
      controller: _namaC,
      decoration: _inputDecoration(label: 'Nama Lengkap'),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
        return null;
      },
    );
  }

  Widget _buildNikField() {
    return TextFormField(
      controller: _nikC,
      decoration: _inputDecoration(label: 'NIK (opsional)'),
    );
  }

  Widget _buildJenisKelaminField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _jenisKelamin,
      decoration: _inputDecoration(label: 'Jenis Kelamin'),
      items: const [
        DropdownMenuItem(
          value: 'Laki-laki',
          child: Text('Laki-laki', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: 'Perempuan',
          child: Text('Perempuan', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (v) => setState(() => _jenisKelamin = v),
      validator: (v) => v == null ? 'Pilih jenis kelamin' : null,
    );
  }

  Widget _buildTanggalLahirField() {
    return InkWell(
      onTap: _pickTanggalLahir,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _inputDecoration(label: 'Tanggal Lahir'),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: _textSoft,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatDate(_tanggalLahir),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: _tanggalLahir == null ? Colors.black45 : _textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoHpField() {
    return TextFormField(
      controller: _noHpC,
      keyboardType: TextInputType.phone,
      decoration: _inputDecoration(label: 'No. HP'),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'No. HP wajib diisi';
        if (v.length < 8) return 'No. HP terlalu pendek';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailC,
      keyboardType: TextInputType.emailAddress,
      decoration: _inputDecoration(label: 'Email'),
    );
  }

  Widget _buildAlamatField() {
    return TextFormField(
      controller: _alamatC,
      maxLines: 3,
      decoration: _inputDecoration(label: 'Alamat'),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Alamat wajib diisi';
        return null;
      },
    );
  }

  Widget _buildProvinsiField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value:
          _provinsiList.any((e) => e['id'] == _selectedProvinsiId)
              ? _selectedProvinsiId
              : null,
      decoration: _inputDecoration(
        label: 'Provinsi',
        suffixIcon: _isLoadingProvinsi ? _buildFieldLoading() : null,
      ),
      items:
          _provinsiList
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e['id'],
                  child: Text(
                    e['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged: (val) {
        if (val == null) return;

        final prov = _provinsiList.firstWhere(
          (e) => e['id'] == val,
          orElse: () => {'id': '', 'name': ''},
        );

        setState(() {
          _selectedProvinsiId = val;
          _selectedProvinsiNama = prov['name'];
          _kotaList = [];
          _kecamatanList = [];
          _kelurahanList = [];
          _selectedKotaId = null;
          _selectedKecamatanId = null;
          _selectedKelurahanId = null;
          _selectedKotaNama = null;
          _selectedKecamatanNama = null;
          _selectedKelurahanNama = null;
        });

        _loadKota(val);
      },
      validator: (v) => v == null ? 'Pilih provinsi' : null,
    );
  }

  Widget _buildKotaField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value:
          _kotaList.any((e) => e['id'] == _selectedKotaId)
              ? _selectedKotaId
              : null,
      decoration: _inputDecoration(
        label: 'Kota/Kabupaten',
        suffixIcon: _isLoadingKota ? _buildFieldLoading() : null,
      ),
      items:
          _kotaList
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e['id'],
                  child: Text(
                    e['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged:
          _kotaList.isEmpty
              ? null
              : (val) {
                if (val == null) return;

                final kota = _kotaList.firstWhere(
                  (e) => e['id'] == val,
                  orElse: () => {'id': '', 'name': ''},
                );

                setState(() {
                  _selectedKotaId = val;
                  _selectedKotaNama = kota['name'];
                  _kecamatanList = [];
                  _kelurahanList = [];
                  _selectedKecamatanId = null;
                  _selectedKelurahanId = null;
                  _selectedKecamatanNama = null;
                  _selectedKelurahanNama = null;
                });

                _loadKecamatan(val);
              },
      validator: (v) => v == null ? 'Pilih kota' : null,
    );
  }

  Widget _buildKecamatanField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value:
          _kecamatanList.any((e) => e['id'] == _selectedKecamatanId)
              ? _selectedKecamatanId
              : null,
      decoration: _inputDecoration(
        label: 'Kecamatan',
        suffixIcon: _isLoadingKecamatan ? _buildFieldLoading() : null,
      ),
      items:
          _kecamatanList
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e['id'],
                  child: Text(
                    e['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged:
          _kecamatanList.isEmpty
              ? null
              : (val) {
                if (val == null) return;

                final kec = _kecamatanList.firstWhere(
                  (e) => e['id'] == val,
                  orElse: () => {'id': '', 'name': ''},
                );

                setState(() {
                  _selectedKecamatanId = val;
                  _selectedKecamatanNama = kec['name'];
                  _kelurahanList = [];
                  _selectedKelurahanId = null;
                  _selectedKelurahanNama = null;
                });

                _loadKelurahan(val);
              },
      validator: (v) => v == null ? 'Pilih kecamatan' : null,
    );
  }

  Widget _buildKelurahanField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value:
          _kelurahanList.any((e) => e['id'] == _selectedKelurahanId)
              ? _selectedKelurahanId
              : null,
      decoration: _inputDecoration(
        label: 'Kelurahan/Desa (opsional)',
        suffixIcon: _isLoadingKelurahan ? _buildFieldLoading() : null,
      ),
      items:
          _kelurahanList
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e['id'],
                  child: Text(
                    e['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged:
          _kelurahanList.isEmpty
              ? null
              : (val) {
                if (val == null) {
                  setState(() {
                    _selectedKelurahanId = null;
                    _selectedKelurahanNama = null;
                  });
                  return;
                }

                final kel = _kelurahanList.firstWhere(
                  (e) => e['id'] == val,
                  orElse: () => {'id': '', 'name': ''},
                );

                setState(() {
                  _selectedKelurahanId = val;
                  _selectedKelurahanNama = kel['name'];
                });
              },
    );
  }

  Widget _buildKodePosField() {
    return TextFormField(
      controller: _kodePosC,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(
        label: 'Kode Pos',
        hint: 'Masukkan kode pos',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Kode pos wajib diisi';
        if (v.trim().length < 5) return 'Kode pos minimal 5 digit';
        return null;
      },
    );
  }

  Widget _buildGolonganDarahField() {
    return TextFormField(
      controller: _golonganDarahC,
      decoration: _inputDecoration(label: 'Golongan Darah (opsional)'),
    );
  }

  Widget _buildAlergiField() {
    return TextFormField(
      controller: _alergiC,
      maxLines: 2,
      decoration: _inputDecoration(label: 'Alergi (opsional)'),
    );
  }

  Widget _buildPenyakitMenahunField() {
    return TextFormField(
      controller: _penyakitMenahunC,
      maxLines: 2,
      decoration: _inputDecoration(label: 'Penyakit Menahun (opsional)'),
    );
  }
}
typedef _SkeletonBox = SkeletonBox;
typedef _ProfilePageSkeleton = ProfilePageSkeleton;
typedef _EditProfileSkeleton = EditProfileSkeleton;
typedef _SkeletonSectionCard = SkeletonSectionCard;
typedef _SectionCard = ProfileSectionCard;
typedef _InfoRow = ProfileInfoRow;

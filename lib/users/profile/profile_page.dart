import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/core/services/wilayah_service.dart';
import 'package:home_care/core/widgets/patient_app_bar.dart';
import 'package:home_care/features/auth/presentation/screens/login.dart';
import 'widgets/profile_avatar_header.dart';
import 'widgets/profile_ui_components.dart';
import 'services/user_profile_service.dart';
import 'widgets/profile_edit_form.dart';
import 'widgets/profile_view_mode.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileService _service = const UserProfileService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  String? _error;
  static const int _maxPhotoBytes = 2 * 1024 * 1024;
  String? _fotoProfilUrl;
  File? _localFotoFile;
  bool _isUploadingFoto = false;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _pasien;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isPreparingEditForm = false;

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

  @override
  void initState() {
    super.initState();
    _initEmptyControllers();
    _checkAuthAndFetchProfile();
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
    _namaC.text = (_pasien?['nama_lengkap'] ?? _user?['name'] ?? '').toString();
    _nikC.text = (_pasien?['nik'] ?? '').toString();
    _noHpC.text = (_pasien?['no_hp'] ?? '').toString();
    _emailC.text = (_user?['email'] ?? _pasien?['email'] ?? '').toString();
    _alamatC.text = (_pasien?['alamat'] ?? '').toString();
    _kodePosC.text = (_pasien?['kode_pos'] ?? '').toString();
    _golonganDarahC.text = (_pasien?['golongan_darah'] ?? '').toString();
    _alergiC.text = (_pasien?['alergi'] ?? '').toString();
    _penyakitMenahunC.text = (_pasien?['penyakit_menahun'] ?? '').toString();

    _jenisKelamin = _pasien?['jenis_kelamin']?.toString();

    final tglRaw = _pasien?['tanggal_lahir'];
    if (tglRaw != null && tglRaw.toString().isNotEmpty) {
      try {
        _tanggalLahir = DateTime.parse(tglRaw.toString());
      } catch (_) {
        _tanggalLahir = null;
      }
    } else {
      _tanggalLahir = null;
    }

    _selectedProvinsiNama = _pasien?['provinsi']?.toString();
    _selectedKotaNama = _pasien?['kota']?.toString();
    _selectedKecamatanNama = _pasien?['kecamatan']?.toString();
    _selectedKelurahanNama = _pasien?['kelurahan']?.toString();

    _selectedProvinsiId = _pasien?['provinsi_id']?.toString();
    _selectedKotaId = _pasien?['kota_id']?.toString();
    _selectedKecamatanId = _pasien?['kecamatan_id']?.toString();
    _selectedKelurahanId = _pasien?['kelurahan_id']?.toString();
  }

  Future<void> _checkAuthAndFetchProfile() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchProfile();
      if (!mounted) return;

      if (data == null) {
        setState(() {
          _error = 'Gagal memuat profil';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _user = (data['user'] ?? {}) as Map<String, dynamic>;
        _pasien = (data['pasien'] ?? {}) as Map<String, dynamic>;

        final rawFoto = _pasien?['foto_profil_url'] ?? _pasien?['foto_profil'];
        if (rawFoto is String && rawFoto.isNotEmpty) {
          _fotoProfilUrl = ApiConstants.resolveMediaUrl(rawFoto);
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

  Future<void> _startEdit() async {
    setState(() {
      _isEditing = true;
      _isPreparingEditForm = true;
    });
    _initControllersFromPasien();
    await _loadProvinsi();
    if (mounted) {
      setState(() => _isPreparingEditForm = false);
    }
  }

  void _cancelEdit() {
    _initControllersFromPasien();
    setState(() => _isEditing = false);
  }

  Future<void> _loadProvinsi() async {
    setState(() => _isLoadingProvinsi = true);
    final list = await WilayahService.fetchProvinsi();
    if (!mounted) return;
    setState(() {
      _provinsiList = list;
      _isLoadingProvinsi = false;
    });
    if (_selectedProvinsiId != null && _selectedProvinsiId!.isNotEmpty) {
      await _loadKota(_selectedProvinsiId!);
    }
  }

  Future<void> _loadKota(String provId) async {
    setState(() => _isLoadingKota = true);
    final list = await WilayahService.fetchKota(provId);
    if (!mounted) return;
    setState(() {
      _kotaList = list;
      _isLoadingKota = false;
    });
    if (_selectedKotaId != null && _selectedKotaId!.isNotEmpty) {
      await _loadKecamatan(_selectedKotaId!);
    }
  }

  Future<void> _loadKecamatan(String kotaId) async {
    setState(() => _isLoadingKecamatan = true);
    final list = await WilayahService.fetchKecamatan(kotaId);
    if (!mounted) return;
    setState(() {
      _kecamatanList = list;
      _isLoadingKecamatan = false;
    });
    if (_selectedKecamatanId != null && _selectedKecamatanId!.isNotEmpty) {
      await _loadKelurahan(_selectedKecamatanId!);
    }
  }

  Future<void> _loadKelurahan(String kecId) async {
    setState(() => _isLoadingKelurahan = true);
    final list = await WilayahService.fetchKelurahan(kecId);
    if (!mounted) return;
    setState(() {
      _kelurahanList = list;
      _isLoadingKelurahan = false;
    });
  }

  Future<void> _pickTanggalLahir() async {
    final now = DateTime.now();
    final initDate = _tanggalLahir ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _tanggalLahir = picked);
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
      if (picked == null || !mounted) return;

      setState(() => _isUploadingFoto = true);
      Uint8List uploadBytes = await picked.readAsBytes();

      if (uploadBytes.lengthInBytes > _maxPhotoBytes) {
        uploadBytes = await FlutterImageCompress.compressWithList(
          uploadBytes,
          minHeight: 1080,
          minWidth: 1080,
          quality: 70,
        );
      }

      final pasienId = _pasien?['id'];
      if (pasienId == null) {
        if (!mounted) return;
        setState(() => _isUploadingFoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID pasien tidak ditemukan'), backgroundColor: Colors.red),
        );
        return;
      }

      final newUrl = await _service.uploadProfilePhotoBytes(
        pasienId: pasienId as int,
        bytes: uploadBytes,
        fileName: picked.name,
      );

      if (!mounted) return;
      setState(() {
        _isUploadingFoto = false;
        if (newUrl != null) {
          _fotoProfilUrl = ApiConstants.resolveMediaUrl(newUrl);
        }
        if (!kIsWeb) {
          _localFotoFile = File(picked.path);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diupload'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload foto: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_jenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih jenis kelamin'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih tanggal lahir'), backgroundColor: Colors.red),
      );
      return;
    }

    final pasienId = _pasien?['id'];
    if (pasienId == null) return;

    setState(() => _isSaving = true);

    try {
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
        'golongan_darah': _golonganDarahC.text.trim().isEmpty ? null : _golonganDarahC.text.trim(),
        'alergi': _alergiC.text.trim().isEmpty ? null : _alergiC.text.trim(),
        'penyakit_menahun': _penyakitMenahunC.text.trim().isEmpty ? null : _penyakitMenahunC.text.trim(),
      };

      final updated = await _service.updateProfile(pasienId as int, payload);
      if (!mounted) return;

      setState(() {
        _pasien = updated;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan profil: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    await StorageService.clearAuth();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PatientAppBar(
        title: 'Profil Saya',
        actions: [
          if (!_isLoading && _pasien != null)
            IconButton(
              icon: Icon(_isEditing ? IconlyLight.closeSquare : IconlyLight.edit, color: Colors.white),
              tooltip: _isEditing ? 'Batal' : 'Edit Profil',
              onPressed: _isEditing ? _cancelEdit : _startEdit,
            ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const ProfilePageSkeleton()
                : _error != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(IconlyLight.dangerCircle, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadProfile,
                          icon: const Icon(IconlyLight.swap),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                )
                : LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxWidth =
                        constraints.maxWidth >= 1200
                            ? 900
                            : constraints.maxWidth >= 900
                            ? 760
                            : constraints.maxWidth >= 600
                            ? 620
                            : constraints.maxWidth;

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child:
                              _isEditing
                                  ? _isPreparingEditForm
                                      ? const EditProfileSkeleton()
                                      : SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            ProfileAvatarHeader(
                                              nama: (_pasien?['nama_lengkap'] ?? _user?['name'] ?? 'Pasien').toString(),
                                              noRm: (_pasien?['no_rekam_medis'] ?? '-').toString(),
                                              fotoProfilUrl: _fotoProfilUrl,
                                              localFotoFile: _localFotoFile,
                                              isEditMode: true,
                                              isUploadingFoto: _isUploadingFoto,
                                              onPickPhoto: _isUploadingFoto ? null : _pickAndUploadPhoto,
                                            ),
                                            const SizedBox(height: 16),
                                            ProfileEditForm(
                                              formKey: _formKey,
                                              namaC: _namaC,
                                              nikC: _nikC,
                                              noHpC: _noHpC,
                                              emailC: _emailC,
                                              alamatC: _alamatC,
                                              kodePosC: _kodePosC,
                                              golonganDarahC: _golonganDarahC,
                                              alergiC: _alergiC,
                                              penyakitMenahunC: _penyakitMenahunC,
                                              jenisKelamin: _jenisKelamin,
                                              onJenisKelaminChanged: (v) => setState(() => _jenisKelamin = v),
                                              tanggalLahir: _tanggalLahir,
                                              onPickTanggalLahir: _pickTanggalLahir,
                                              provinsiList: _provinsiList,
                                              kotaList: _kotaList,
                                              kecamatanList: _kecamatanList,
                                              kelurahanList: _kelurahanList,
                                              selectedProvinsiId: _selectedProvinsiId,
                                              selectedKotaId: _selectedKotaId,
                                              selectedKecamatanId: _selectedKecamatanId,
                                              selectedKelurahanId: _selectedKelurahanId,
                                              isLoadingProvinsi: _isLoadingProvinsi,
                                              isLoadingKota: _isLoadingKota,
                                              isLoadingKecamatan: _isLoadingKecamatan,
                                              isLoadingKelurahan: _isLoadingKelurahan,
                                              onProvinsiChanged: (val) {
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
                                                });
                                                _loadKota(val);
                                              },
                                              onKotaChanged: (val) {
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
                                                });
                                                _loadKecamatan(val);
                                              },
                                              onKecamatanChanged: (val) {
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
                                                });
                                                _loadKelurahan(val);
                                              },
                                              onKelurahanChanged: (val) {
                                                if (val == null) return;
                                                final kel = _kelurahanList.firstWhere(
                                                  (e) => e['id'] == val,
                                                  orElse: () => {'id': '', 'name': '', 'kode_pos': ''},
                                                );
                                                setState(() {
                                                  _selectedKelurahanId = val;
                                                  _selectedKelurahanNama = kel['name'];
                                                  _kodePosC.text = kel['kode_pos'] ?? '';
                                                });
                                              },
                                              isSaving: _isSaving,
                                              onCancel: _cancelEdit,
                                              onSave: _saveProfile,
                                            ),
                                          ],
                                        ),
                                      )
                                  : ProfileViewMode(
                                    user: _user,
                                    pasien: _pasien,
                                    fotoProfilUrl: _fotoProfilUrl,
                                    localFotoFile: _localFotoFile,
                                    onLogout: _logout,
                                  ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

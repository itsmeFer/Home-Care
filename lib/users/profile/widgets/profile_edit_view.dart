import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_care/core/services/wilayah_service.dart';
import '../services/user_profile_service.dart';
import 'profile_avatar_header.dart';
import 'profile_edit_form.dart';
import 'profile_ui_components.dart';

/// Isolated Stateful Widget for editing user profile and cascading Wilayah selection.
class ProfileEditView extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? pasien;
  final String? fotoProfilUrl;
  final File? localFotoFile;
  final bool isUploadingFoto;
  final VoidCallback? onPickPhoto;
  final VoidCallback onCancel;
  final ValueChanged<Map<String, dynamic>> onSaveSuccess;

  const ProfileEditView({
    super.key,
    required this.user,
    required this.pasien,
    required this.fotoProfilUrl,
    required this.localFotoFile,
    required this.isUploadingFoto,
    required this.onPickPhoto,
    required this.onCancel,
    required this.onSaveSuccess,
  });

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  final UserProfileService _service = const UserProfileService();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _isPreparing = true;

  late final TextEditingController _namaC;
  late final TextEditingController _nikC;
  late final TextEditingController _noHpC;
  late final TextEditingController _emailC;
  late final TextEditingController _alamatC;
  late final TextEditingController _kodePosC;
  late final TextEditingController _golonganDarahC;
  late final TextEditingController _alergiC;
  late final TextEditingController _penyakitMenahunC;

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
    _initControllers();
    _loadInitialWilayah();
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

  void _initControllers() {
    final pasien = widget.pasien;
    final user = widget.user;

    _namaC = TextEditingController(text: (pasien?['nama_lengkap'] ?? user?['name'] ?? '').toString());
    _nikC = TextEditingController(text: (pasien?['nik'] ?? '').toString());
    _noHpC = TextEditingController(text: (pasien?['no_hp'] ?? '').toString());
    _emailC = TextEditingController(text: (user?['email'] ?? pasien?['email'] ?? '').toString());
    _alamatC = TextEditingController(text: (pasien?['alamat'] ?? '').toString());
    _kodePosC = TextEditingController(text: (pasien?['kode_pos'] ?? '').toString());
    _golonganDarahC = TextEditingController(text: (pasien?['golongan_darah'] ?? '').toString());
    _alergiC = TextEditingController(text: (pasien?['alergi'] ?? '').toString());
    _penyakitMenahunC = TextEditingController(text: (pasien?['penyakit_menahun'] ?? '').toString());

    _jenisKelamin = pasien?['jenis_kelamin']?.toString();

    final tglRaw = pasien?['tanggal_lahir'];
    if (tglRaw != null && tglRaw.toString().isNotEmpty) {
      try {
        _tanggalLahir = DateTime.parse(tglRaw.toString());
      } catch (_) {
        _tanggalLahir = null;
      }
    }

    _selectedProvinsiNama = pasien?['provinsi']?.toString();
    _selectedKotaNama = pasien?['kota']?.toString();
    _selectedKecamatanNama = pasien?['kecamatan']?.toString();
    _selectedKelurahanNama = pasien?['kelurahan']?.toString();

    _selectedProvinsiId = pasien?['provinsi_id']?.toString();
    _selectedKotaId = pasien?['kota_id']?.toString();
    _selectedKecamatanId = pasien?['kecamatan_id']?.toString();
    _selectedKelurahanId = pasien?['kelurahan_id']?.toString();
  }

  Future<void> _loadInitialWilayah() async {
    await _loadProvinsi();
    if (mounted) setState(() => _isPreparing = false);
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

  void _onProvinsiChanged(String? val) {
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
  }

  void _onKotaChanged(String? val) {
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
  }

  void _onKecamatanChanged(String? val) {
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
  }

  void _onKelurahanChanged(String? val) {
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

    final pasienId = widget.pasien?['id'];
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

      widget.onSaveSuccess(updated);
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

  @override
  Widget build(BuildContext context) {
    if (_isPreparing) {
      return const EditProfileSkeleton();
    }

    final nama = (widget.pasien?['nama_lengkap'] ?? widget.user?['name'] ?? 'Pasien').toString();
    final noRm = (widget.pasien?['no_rekam_medis'] ?? '-').toString();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          ProfileAvatarHeader(
            nama: nama,
            noRm: noRm,
            fotoProfilUrl: widget.fotoProfilUrl,
            localFotoFile: widget.localFotoFile,
            isEditMode: true,
            isUploadingFoto: widget.isUploadingFoto,
            onPickPhoto: widget.onPickPhoto,
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
            onProvinsiChanged: _onProvinsiChanged,
            onKotaChanged: _onKotaChanged,
            onKecamatanChanged: _onKecamatanChanged,
            onKelurahanChanged: _onKelurahanChanged,
            isSaving: _isSaving,
            onCancel: widget.onCancel,
            onSave: _saveProfile,
          ),
        ],
      ),
    );
  }
}

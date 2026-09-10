import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/core/utils/app_image_compressor.dart';
import 'package:home_care/core/widgets/patient_app_bar.dart';
import 'package:home_care/features/auth/presentation/screens/login.dart';
import 'services/user_profile_service.dart';
import 'widgets/widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileService _service = const UserProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  String? _error;
  String? _fotoProfilUrl;
  File? _localFotoFile;
  bool _isUploadingFoto = false;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _pasien;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchProfile();
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

  Future<void> _loadProfile({bool isRefresh = false}) async {
    if (!mounted) return;
    if (!isRefresh && _pasien == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

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
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (isRefresh && _pasien != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: $e')),
        );
      } else {
        setState(() {
          _error = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
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

      // Client-side image compression
      final uploadBytes = await AppImageCompressor.compressXFile(
        picked,
        maxDimension: 800,
        quality: 75,
      );

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
        const SnackBar(
          content: Text('Foto profil berhasil diupload'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
              icon: Icon(
                _isEditing ? IconlyLight.closeSquare : IconlyLight.edit,
                color: Colors.white,
              ),
              tooltip: _isEditing ? 'Batal' : 'Edit Profil',
              onPressed: () => setState(() => _isEditing = !_isEditing),
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
                        const Icon(
                          IconlyLight.dangerCircle,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _loadProfile(),
                          icon: const Icon(IconlyLight.swap),
                          label: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                )
                : RefreshIndicator(
                  onRefresh: () => _loadProfile(isRefresh: true),
                  child: LayoutBuilder(
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
                                    ? ProfileEditView(
                                      user: _user,
                                      pasien: _pasien,
                                      fotoProfilUrl: _fotoProfilUrl,
                                      localFotoFile: _localFotoFile,
                                      isUploadingFoto: _isUploadingFoto,
                                      onPickPhoto:
                                          _isUploadingFoto
                                              ? null
                                              : _pickAndUploadPhoto,
                                      onCancel:
                                          () => setState(
                                            () => _isEditing = false,
                                          ),
                                      onSaveSuccess: (updated) {
                                        setState(() {
                                          _pasien = updated;
                                          _isEditing = false;
                                        });
                                      },
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
      ),
    );
  }
}

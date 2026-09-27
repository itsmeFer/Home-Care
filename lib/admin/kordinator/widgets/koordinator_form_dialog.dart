import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:home_care/admin/kordinator/models/koordinator_admin_model.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_image_compressor.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';
import 'package:image_picker/image_picker.dart';

class KoordinatorFormDialog extends StatefulWidget {
  final Koordinator? koordinator;

  const KoordinatorFormDialog({super.key, this.koordinator});

  @override
  State<KoordinatorFormDialog> createState() => _KoordinatorFormDialogState();
}

class _KoordinatorFormDialogState extends State<KoordinatorFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaC;
  late final TextEditingController _emailC;
  late final TextEditingController _passwordC;
  late final TextEditingController _noHpC;
  late final TextEditingController _wilayahC;
  late final TextEditingController _alamatC;
  late final TextEditingController _nikC;
  late final TextEditingController _jabatanC;

  bool _isActive = true;
  bool _isCompressing = false;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedBytes;
  String? _fotoBase64;

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
    _nikC = TextEditingController(text: k?.nik ?? '');
    _jabatanC = TextEditingController(text: k?.jabatan ?? '');

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
    _nikC.dispose();
    _jabatanC.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      setState(() => _isCompressing = true);
      final compressedBytes = await AppImageCompressor.compressXFile(picked);

      if (mounted) {
        setState(() {
          _pickedBytes = compressedBytes;
          _fotoBase64 = base64Encode(compressedBytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.koordinator != null;

    final payload = <String, dynamic>{
      'name': _namaC.text.trim(),
      'email': _emailC.text.trim(),
      'nik': _nikC.text.trim(),
      'no_hp': _noHpC.text.trim(),
      'wilayah': _wilayahC.text.trim(),
      'alamat': _alamatC.text.trim(),
      'jabatan': _jabatanC.text.trim().isEmpty ? null : _jabatanC.text.trim(),
      'is_active': _isActive,
    };

    if (!isEdit) {
      payload['password'] = _passwordC.text.trim();
    } else {
      if (_passwordC.text.trim().isNotEmpty) {
        payload['password'] = _passwordC.text.trim();
      }
    }

    if (_fotoBase64 != null) {
      payload['foto_base64'] = _fotoBase64;
    }

    Navigator.pop(context, payload);
  }

  Widget _buildFotoPreview() {
    if (_isCompressing) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

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

    final existingFotoUrl = widget.koordinator?.foto;
    if (existingFotoUrl != null && existingFotoUrl.isNotEmpty) {
      return AppCircleAvatar(
        imageUrl: existingFotoUrl,
        radius: 40,
        fallbackIcon: Icons.person,
      );
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: HCColor.primary.withValues(alpha: 0.1),
      child: Icon(Icons.person, size: 40, color: Colors.grey.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.koordinator != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Edit Koordinator' : 'Tambah Koordinator',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    children: [
                      _buildFotoPreview(),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _isCompressing ? null : _pickImage,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Pilih Foto Profil'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nikC,
                  decoration: const InputDecoration(
                    labelText: 'NIK',
                    hintText: '16 digit nomor induk kependudukan',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'NIK wajib diisi';
                    }
                    if (v.trim().length < 8) {
                      return 'NIK minimal 8 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
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
                TextFormField(
                  controller: _noHpC,
                  decoration: const InputDecoration(
                    labelText: 'No HP / WhatsApp',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nomor HP wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _wilayahC,
                  decoration: const InputDecoration(
                    labelText: 'Wilayah Kerja (contoh: Medan Kota)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _jabatanC,
                  decoration: const InputDecoration(
                    labelText: 'Jabatan (contoh: Koordinator Lapangan)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _alamatC,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Domisili',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordC,
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? 'Password baru (kosongkan jika tidak diganti)'
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
                    } else if (v != null &&
                        v.trim().isNotEmpty &&
                        v.trim().length < 6) {
                      return 'Minimal 6 karakter jika ingin mengganti';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _isActive,
                  title: const Text('Status Aktif'),
                  subtitle: Text(
                    _isActive
                        ? 'Koordinator dapat ditugaskan layanan'
                        : 'Koordinator nonaktif sementara',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: HCColor.primary,
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
          style: ElevatedButton.styleFrom(
            backgroundColor: HCColor.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Koordinator'),
        ),
      ],
    );
  }
}

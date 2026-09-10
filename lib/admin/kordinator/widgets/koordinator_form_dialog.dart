import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:home_care/admin/kordinator/models/koordinator_admin_model.dart';
import 'package:home_care/core/theme/app_colors.dart';
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

  bool _isActive = true;

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
    _nikC = TextEditingController();

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
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (mounted) {
      setState(() {
        _pickedBytes = bytes;
        _fotoBase64 = base64Encode(bytes);
      });
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
      title: Text(isEdit ? 'Edit Koordinator' : 'Tambah Koordinator'),
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
                        onPressed: _pickImage,
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
                    labelText: 'No HP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
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
                  controller: _alamatC,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _passwordC,
                  decoration: InputDecoration(
                    labelText:
                        isEdit
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
          child: Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

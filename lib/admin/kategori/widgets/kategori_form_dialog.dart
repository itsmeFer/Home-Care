import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_care/admin/kategori/models/kategori_layanan_model.dart';
import 'package:home_care/admin/kategori/widgets/kategori_image_picker_field.dart';
import 'package:home_care/core/theme/app_colors.dart';

class KategoriFormDialog extends StatefulWidget {
  final KategoriLayanan? item;

  const KategoriFormDialog({super.key, this.item});

  @override
  State<KategoriFormDialog> createState() => _KategoriFormDialogState();
}

class _KategoriFormDialogState extends State<KategoriFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaC;
  late TextEditingController _slugC;
  late TextEditingController _deskripsiC;
  late TextEditingController _warnaC;
  late TextEditingController _urutanC;

  bool _aktif = true;

  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _namaC = TextEditingController(text: item?.namaKategori ?? '');
    _slugC = TextEditingController(text: item?.slug ?? '');
    _deskripsiC = TextEditingController(text: item?.deskripsi ?? '');
    _warnaC = TextEditingController(text: item?.warna ?? '#0BA5A7');
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
    _warnaC.dispose();
    _urutanC.dispose();
    super.dispose();
  }

  String _slugify(String text) {
    final lower = text.toLowerCase().trim();
    return lower
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  void _submit() {
    final hasImage = _selectedImageFile != null ||
        _selectedImageBytes != null ||
        (widget.item?.gambarUrl != null &&
            widget.item!.gambarUrl!.trim().isNotEmpty);

    if (!hasImage) {
      setState(() {
        _imageError = 'Gambar kategori wajib dipilih!';
      });
    }

    if (!_formKey.currentState!.validate() || !hasImage) {
      if (!hasImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar kategori wajib diisi/dipilih!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final payload = <String, dynamic>{
      'nama_kategori': _namaC.text.trim(),
      'slug': _slugC.text.trim().isEmpty ? null : _slugC.text.trim(),
      'deskripsi':
          _deskripsiC.text.trim().isEmpty ? null : _deskripsiC.text.trim(),
      'icon': widget.item?.icon,
      'warna': _warnaC.text.trim().isEmpty ? '#0BA5A7' : _warnaC.text.trim(),
      'urutan': int.tryParse(_urutanC.text.trim()) ?? 0,
      'aktif': _aktif,
    };

    Navigator.pop(
      context,
      KategoriFormResult(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Edit Kategori' : 'Tambah Kategori',
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
                KategoriImagePickerField(
                  initialImageUrl: widget.item?.gambarUrl,
                  imageError: _imageError,
                  selectedImageFile: _selectedImageFile,
                  selectedImageBytes: _selectedImageBytes,
                  onImageSelected: ({file, bytes, name}) {
                    setState(() {
                      _selectedImageFile = file;
                      _selectedImageBytes = bytes;
                      _selectedImageName = name;
                      _imageError = null;
                    });
                  },
                  onImageRemoved: () {
                    setState(() {
                      _selectedImageFile = null;
                      _selectedImageBytes = null;
                      _selectedImageName = null;
                      if (widget.item?.gambarUrl == null ||
                          widget.item!.gambarUrl!.isEmpty) {
                        _imageError = 'Gambar kategori wajib dipilih!';
                      }
                    });
                  },
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

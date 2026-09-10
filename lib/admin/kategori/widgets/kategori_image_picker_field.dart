import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_care/utils/app_cached_image.dart';
import 'package:image_picker/image_picker.dart';

class KategoriImagePickerField extends StatefulWidget {
  final String? initialImageUrl;
  final String? imageError;
  final File? selectedImageFile;
  final Uint8List? selectedImageBytes;
  final void Function({
    File? file,
    Uint8List? bytes,
    String? name,
  }) onImageSelected;
  final VoidCallback onImageRemoved;

  const KategoriImagePickerField({
    super.key,
    this.initialImageUrl,
    this.imageError,
    this.selectedImageFile,
    this.selectedImageBytes,
    required this.onImageSelected,
    required this.onImageRemoved,
  });

  @override
  State<KategoriImagePickerField> createState() =>
      _KategoriImagePickerFieldState();
}

class _KategoriImagePickerFieldState extends State<KategoriImagePickerField> {
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
        widget.onImageSelected(
          bytes: bytes,
          name: picked.name,
        );
      } else {
        widget.onImageSelected(
          file: File(picked.path),
          name: picked.name,
        );
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

  Widget _buildPreview() {
    if (widget.selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          widget.selectedImageBytes!,
          height: 130,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.selectedImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          widget.selectedImageFile!,
          height: 130,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.trim().isNotEmpty) {
      return AppCachedImage(
        imageUrl: widget.initialImageUrl!,
        height: 130,
        width: double.infinity,
        borderRadius: BorderRadius.circular(12),
        fit: BoxFit.cover,
      );
    }

    final hasError = widget.imageError != null;

    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFEF2F2) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? Colors.red.shade400 : Colors.grey.shade300,
          width: hasError ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 36,
            color: hasError ? Colors.red.shade400 : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            hasError ? 'Belum ada gambar (Wajib Diisi)' : 'Belum ada gambar',
            style: TextStyle(
              color: hasError ? Colors.red.shade600 : Colors.grey,
              fontWeight: hasError ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.selectedImageFile != null ||
        widget.selectedImageBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Gambar Kategori',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                'Wajib diisi',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildPreview(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(hasImage ? 'Ganti Gambar' : 'Pilih Gambar'),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onImageRemoved,
                icon: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ],
        ),
        if (widget.imageError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 14),
              const SizedBox(width: 4),
              Text(
                widget.imageError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

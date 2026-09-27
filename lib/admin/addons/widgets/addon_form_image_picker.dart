import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class AddonFormImagePicker extends StatelessWidget {
  final XFile? pickedImage;
  final Uint8List? compressedBytes;
  final String? existingImageUrl;
  final bool removeGambar;
  final bool isCompressing;
  final VoidCallback onPickSource;
  final VoidCallback onRemove;

  const AddonFormImagePicker({
    super.key,
    required this.pickedImage,
    required this.compressedBytes,
    required this.existingImageUrl,
    required this.removeGambar,
    required this.isCompressing,
    required this.onPickSource,
    required this.onRemove,
  });

  static void showSourceSheet({
    required BuildContext context,
    required Function(ImageSource) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Add-on (Opsional)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Center(
          child: Stack(
            children: [
              InkWell(
                onTap: isCompressing ? null : onPickSource,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildImageContent(),
                  ),
                ),
              ),
              if (_hasImage && !isCompressing)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _hasImage {
    if (pickedImage != null) return true;
    if (existingImageUrl != null && existingImageUrl!.isNotEmpty && !removeGambar) return true;
    return false;
  }

  Widget _buildImageContent() {
    if (isCompressing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(height: 6),
            Text('Kompresi...', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      );
    }

    if (pickedImage != null) {
      if (kIsWeb && compressedBytes != null) {
        return Image.memory(compressedBytes!, fit: BoxFit.cover);
      }
      return Image.file(File(pickedImage!.path), fit: BoxFit.cover);
    }

    if (existingImageUrl != null && existingImageUrl!.isNotEmpty && !removeGambar) {
      return AppCachedImage(
        imageUrl: existingImageUrl,
        fit: BoxFit.cover,
        memCacheWidth: 240,
        memCacheHeight: 240,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 32, color: Colors.grey.shade400),
        const SizedBox(height: 4),
        Text('Pilih Foto', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

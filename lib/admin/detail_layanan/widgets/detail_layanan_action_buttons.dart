import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class DetailLayananActionButtons extends StatelessWidget {
  final bool isUploadingImage;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onUploadImage;

  const DetailLayananActionButtons({
    super.key,
    required this.isUploadingImage,
    required this.onDelete,
    required this.onEdit,
    required this.onUploadImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: isUploadingImage ? null : onUploadImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: HCColor.primaryDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: isUploadingImage
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.image),
          label: Text(
            isUploadingImage ? 'Mengupload...' : 'Ubah Gambar Layanan',
          ),
        ),
      ],
    );
  }
}

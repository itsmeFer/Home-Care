import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class BannerFormContentSection extends StatelessWidget {
  final TextEditingController judulCtrl;
  final TextEditingController subCtrl;
  final VoidCallback onChanged;

  const BannerFormContentSection({
    super.key,
    required this.judulCtrl,
    required this.subCtrl,
    required this.onChanged,
  });

  InputDecoration _inputDecoration({required String label, String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.edit_note_outlined, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Teks & Informasi Banner',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: judulCtrl,
          decoration: _inputDecoration(
            label: 'Judul Banner *',
            hint: 'Misal: Promo Perawatan Luka Spesial',
            prefixIcon: const Icon(Icons.title, size: 20, color: AppColors.primary),
          ),
          onChanged: (_) => onChanged(),
          validator: (v) => v == null || v.trim().isEmpty ? 'Judul banner wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: subCtrl,
          maxLines: 2,
          decoration: _inputDecoration(
            label: 'Subjudul / Keterangan',
            hint: 'Deskripsi singkat promosi...',
            prefixIcon: const Icon(Icons.subtitles_outlined, size: 20, color: AppColors.primary),
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

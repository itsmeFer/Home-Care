import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class BannerFormStatusSection extends StatelessWidget {
  final TextEditingController urutanCtrl;
  final bool aktif;
  final ValueChanged<bool> onAktifChanged;

  const BannerFormStatusSection({
    super.key,
    required this.urutanCtrl,
    required this.aktif,
    required this.onAktifChanged,
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
            Icon(Icons.tune_outlined, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Urutan & Visibilitas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: urutanCtrl,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
            label: 'Urutan Posisi Tampil',
            hint: '0',
            prefixIcon: const Icon(Icons.sort, size: 20, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status Banner Aktif', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(
                    aktif ? 'Ditampilkan pada halaman beranda pasien' : 'Disembunyikan dari pasien',
                    style: TextStyle(fontSize: 11, color: aktif ? AppColors.success : Colors.grey.shade500),
                  ),
                ],
              ),
              Switch.adaptive(
                value: aktif,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                onChanged: onAktifChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';

class BookingLocationStep extends StatelessWidget {
  final TextEditingController alamatController;
  final TextEditingController kotaController;
  final TextEditingController kecamatanController;
  final bool isLoadingProfile;
  final VoidCallback onUseProfile;

  const BookingLocationStep({
    super.key,
    required this.alamatController,
    required this.kotaController,
    required this.kecamatanController,
    required this.isLoadingProfile,
    required this.onUseProfile,
  });

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    required IconData icon,
    bool isTextArea = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: isTextArea
          ? Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Icon(icon, color: HCColor.primary, size: 20),
            )
          : Icon(icon, color: HCColor.primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: HCColor.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lokasi Pelayanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              InkWell(
                onTap: isLoadingProfile ? null : onUseProfile,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: HCColor.lightTeal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconlyLight.location, size: 14, color: HCColor.primary),
                      const SizedBox(width: 4),
                      Text(
                        isLoadingProfile ? 'Memuat...' : 'Alamat Profil',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: HCColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pastikan alamat dapat dijangkau dan sertakan patokan lokasi',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: alamatController,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: _buildInputDecoration(
              labelText: 'Alamat Tujuan Kunjungan',
              hintText: 'Jalan, nomor rumah, RT/RW, patokan',
              icon: IconlyLight.home,
              isTextArea: true,
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Alamat wajib diisi' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: kotaController,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: _buildInputDecoration(
                    labelText: 'Kota / Kab.',
                    hintText: 'Nama kota',
                    icon: IconlyLight.location,
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Wajib diisi' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: kecamatanController,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: _buildInputDecoration(
                    labelText: 'Kecamatan',
                    hintText: 'Nama kecamatan',
                    icon: IconlyLight.discovery,
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Wajib diisi' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';

class BookingScheduleStep extends StatelessWidget {
  final TextEditingController tanggalController;
  final TextEditingController jamController;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const BookingScheduleStep({
    super.key,
    required this.tanggalController,
    required this.jamController,
    required this.onPickDate,
    required this.onPickTime,
  });

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: HCColor.primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          const Text(
            'Pilih Jadwal Kunjungan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tentukan tanggal dan jam kedatangan perawat ke lokasi Anda',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: tanggalController,
            readOnly: true,
            onTap: onPickDate,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _buildInputDecoration(
              labelText: 'Tanggal Kunjungan',
              hintText: 'Pilih tanggal kunjungan',
              icon: IconlyLight.calendar,
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Tanggal wajib dipilih' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: jamController,
            readOnly: true,
            onTap: onPickTime,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: _buildInputDecoration(
              labelText: 'Jam Kunjungan',
              hintText: 'Pilih jam kedatangan perawat',
              icon: IconlyLight.timeCircle,
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Jam wajib dipilih' : null,
          ),
        ],
      ),
    );
  }
}

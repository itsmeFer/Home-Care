import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Jadwal Kunjungan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: tanggalController,
            readOnly: true,
            onTap: onPickDate,
            decoration: const InputDecoration(
              labelText: 'Tanggal Kunjungan',
              hintText: 'Pilih tanggal',
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Tanggal wajib dipilih' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: jamController,
            readOnly: true,
            onTap: onPickTime,
            decoration: const InputDecoration(
              labelText: 'Jam Kunjungan',
              hintText: 'Pilih jam',
              prefixIcon: Icon(Icons.access_time),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Jam wajib dipilih' : null,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alamat Lengkap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: isLoadingProfile ? null : onUseProfile,
                icon: const Icon(Icons.person_pin_circle_outlined, size: 18),
                label: const Text('Gunakan Alamat Profil', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: alamatController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alamat Tujuan Kunjungan',
              hintText: 'Jalan, nomor rumah, RT/RW, patokan',
              prefixIcon: Icon(Icons.home_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Alamat wajib diisi' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: kotaController,
            decoration: const InputDecoration(
              labelText: 'Kota / Kabupaten',
              prefixIcon: Icon(Icons.location_city_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Kota wajib diisi' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: kecamatanController,
            decoration: const InputDecoration(
              labelText: 'Kecamatan',
              prefixIcon: Icon(Icons.map_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Kecamatan wajib diisi' : null,
          ),
        ],
      ),
    );
  }
}

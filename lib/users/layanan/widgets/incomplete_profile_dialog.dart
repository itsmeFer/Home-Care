import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/users/profile.dart';

class IncompleteProfileDialog {
  static bool isProfileComplete(Map<String, dynamic>? profileData) {
    if (profileData == null) return false;
    const requiredFields = [
      'nama_lengkap',
      'no_hp',
      'jenis_kelamin',
      'tanggal_lahir',
      'alamat',
      'kecamatan',
      'kota',
      'kode_pos',
    ];

    for (final field in requiredFields) {
      final value = profileData[field];
      if (value == null || value.toString().trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  static List<String> getMissingFields(Map<String, dynamic>? profileData) {
    if (profileData == null) return ['Semua data profil'];

    final missingFields = <String>[];
    final fieldLabels = {
      'nama_lengkap': 'Nama Lengkap',
      'no_hp': 'No. HP',
      'jenis_kelamin': 'Jenis Kelamin',
      'tanggal_lahir': 'Tanggal Lahir',
      'alamat': 'Alamat',
      'kecamatan': 'Kecamatan',
      'kota': 'Kota',
      'kode_pos': 'Kode Pos',
    };

    fieldLabels.forEach((key, label) {
      final value = profileData[key];
      if (value == null || value.toString().trim().isEmpty) {
        missingFields.add(label);
      }
    });

    return missingFields;
  }

  static void show(BuildContext context, {Map<String, dynamic>? profileData, VoidCallback? onComplete}) {
    final missingFields = getMissingFields(profileData);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconlyLight.dangerCircle,
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Profil Belum Lengkap',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Untuk memesan layanan, Anda harus melengkapi profil terlebih dahulu.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HCColor.lightTeal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: HCColor.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            IconlyLight.infoSquare,
                            size: 16,
                            color: HCColor.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Data yang belum diisi:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: HCColor.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...missingFields.map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: HCColor.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                field,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Nanti',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ).then((_) {
                    onComplete?.call();
                  });
                },
                icon: const Icon(IconlyLight.edit, size: 18),
                label: const Text('Lengkapi Profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

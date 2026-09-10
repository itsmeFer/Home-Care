import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';

class BookingSopSection extends StatelessWidget {
  const BookingSopSection({super.key});

  @override
  Widget build(BuildContext context) {
    const sops = [
      {
        'title': 'Konfirmasi Jadwal',
        'desc':
            'Perawat akan menghubungi keluarga pasien 1 jam sebelum kedatangan.',
        'icon': IconlyLight.timeCircle,
      },
      {
        'title': 'Protokol Kebersihan & APD',
        'desc':
            'Tenaga medis menggunakan masker medis, hand-sanitizer, dan seragam resmi.',
        'icon': IconlyLight.shieldDone,
      },
      {
        'title': 'Pemeriksaan Awal (TTV)',
        'desc':
            'Pengecekan tensi darah, detak jantung, suhu, dan saturasi oksigen.',
        'icon': IconlyLight.activity,
      },
      {
        'title': 'Tindakan Keperawatan',
        'desc':
            'Pelaksanaan prosedur medis sesuai paket yang dipilih dan catatan pasien.',
        'icon': IconlyLight.document,
      },
      {
        'title': 'Edukasi & Laporan Visit',
        'desc':
            'Keluarga menerima ringkasan catatan perkembangan pasien pasca visit.',
        'icon': IconlyLight.tickSquare,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF2F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prosedur Layanan Medis (SOP)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Standar pelayanan klinis menjamin kenyamanan dan keamanan pasien',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          ...sops.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: HCColor.lightTeal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$idx',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: HCColor.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

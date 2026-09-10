import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

/// Title, duration badge, and expandable description for Booking screen.
class BookingHeaderTitleSection extends StatelessWidget {
  final Layanan layanan;
  final double screenWidth;
  final bool isDescriptionExpanded;
  final VoidCallback onToggleDescription;

  const BookingHeaderTitleSection({
    super.key,
    required this.layanan,
    required this.screenWidth,
    required this.isDescriptionExpanded,
    required this.onToggleDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  layanan.namaLayanan,
                  style: TextStyle(
                    fontSize: screenWidth < 360 ? 20 : 23,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    IconlyLight.timeCircle,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    layanan.durasiMenit != null
                        ? '${layanan.durasiMenit} Min'
                        : '${layanan.jumlahVisit ?? 1}x Visit',
                    style: TextStyle(
                      fontSize: screenWidth < 360 ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: (layanan.deskripsi != null &&
                          layanan.deskripsi!.trim().isNotEmpty)
                      ? (isDescriptionExpanded
                          ? '${layanan.deskripsi!} '
                          : (layanan.deskripsi!.length > 95
                              ? '${layanan.deskripsi!.substring(0, 95)}... '
                              : '${layanan.deskripsi!} '))
                      : 'Layanan perawatan medis dan pendampingan kesehatan berkualitas langsung di rumah Anda. ',
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: onToggleDescription,
                    child: Text(
                      isDescriptionExpanded ? 'Tutup' : 'Lihat Selengkapnya',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

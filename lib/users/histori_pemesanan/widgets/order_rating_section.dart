import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

/// Komponen ulasan dan rating pesanan layanan.
class OrderRatingSection extends StatelessWidget {
  final bool hasRating;
  final bool isLoadingRating;
  final Map<String, dynamic>? ratingData;
  final int ratingLayanan;
  final int ratingPerawat;
  final TextEditingController komentarController;
  final bool isSubmittingRating;
  final ValueChanged<int> onRatingLayananChanged;
  final ValueChanged<int> onRatingPerawatChanged;
  final VoidCallback onSubmit;

  const OrderRatingSection({
    super.key,
    required this.hasRating,
    required this.isLoadingRating,
    this.ratingData,
    required this.ratingLayanan,
    required this.ratingPerawat,
    required this.komentarController,
    required this.isSubmittingRating,
    required this.onRatingLayananChanged,
    required this.onRatingPerawatChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingRating) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: HCColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: HCColors.primary),
        ),
      );
    }

    final avgData = ratingData?['avg'] as Map? ?? {};
    final avgLayanan = avgData['layanan'];
    final avgPerawat = avgData['perawat'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRating ? IconlyBold.shieldDone : IconlyBold.star,
                color: hasRating ? HCColors.success : HCColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                hasRating ? 'Rating Anda' : 'Beri Rating & Ulasan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasRating) ...[
            _buildSubmittedDisplay(),
            if (avgLayanan != null || avgPerawat != null) ...[
              const Divider(height: 24),
              const Text(
                'Rating Rata-rata',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: HCColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              if (avgLayanan != null)
                _buildAverageRatingRow(
                  icon: IconlyLight.activity,
                  label: 'Layanan',
                  average: avgLayanan,
                ),
              if (avgLayanan != null && avgPerawat != null)
                const SizedBox(height: 8),
              if (avgPerawat != null)
                _buildAverageRatingRow(
                  icon: IconlyLight.profile,
                  label: 'Perawat',
                  average: avgPerawat,
                ),
            ],
          ] else ...[
            const Text(
              'Bagaimana pengalaman Anda dengan layanan kami?',
              style: TextStyle(fontSize: 14, color: HCColors.textMuted),
            ),
            const SizedBox(height: 20),
            _buildRatingInputRow(
              icon: IconlyLight.activity,
              label: 'Rating Layanan',
              required: true,
              rating: ratingLayanan,
              onChanged: onRatingLayananChanged,
            ),
            const SizedBox(height: 16),
            _buildRatingInputRow(
              icon: IconlyLight.profile,
              label: 'Rating Perawat',
              required: false,
              rating: ratingPerawat,
              onChanged: onRatingPerawatChanged,
            ),
            const SizedBox(height: 20),
            const Text(
              'Komentar (Opsional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: HCColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: komentarController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: HCColors.textDark),
              decoration: InputDecoration(
                hintText: 'Tulis ulasan Anda di sini...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: HCColors.textMuted.withAlpha(180),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: HCColors.textMuted.withAlpha(50),
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isSubmittingRating ? null : onSubmit,
                child: isSubmittingRating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kirim Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmittedDisplay() {
    final mine = ratingData?['mine'] as Map? ?? {};
    final rLayanan = mine['rating_layanan'] ?? mine['rating'];
    final rPerawat = mine['rating_perawat'];
    final komentar = mine['komentar']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rLayanan != null)
          _buildRatingBadgeRow(
            label: 'Layanan',
            rating: int.tryParse('$rLayanan') ?? 5,
          ),
        if (rPerawat != null) ...[
          const SizedBox(height: 8),
          _buildRatingBadgeRow(
            label: 'Perawat',
            rating: int.tryParse('$rPerawat') ?? 5,
          ),
        ],
        if (komentar != null && komentar.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HCColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"$komentar"',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: HCColors.textDark,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingBadgeRow({required String label, required int rating}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: HCColors.textDark,
          ),
        ),
        Row(
          children: List.generate(5, (i) {
            return Icon(
              i < rating ? IconlyBold.star : IconlyLight.star,
              color: AppColors.warning,
              size: 20,
            );
          }),
        ),
        const SizedBox(width: 6),
        Text(
          '($rating/5)',
          style: const TextStyle(fontSize: 13, color: HCColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildRatingInputRow({
    required IconData icon,
    required String label,
    required bool required,
    required int rating,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: HCColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: HCColors.textDark,
              ),
            ),
            if (required)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final starVal = i + 1;
            return IconButton(
              icon: Icon(
                starVal <= rating
                    ? IconlyBold.star
                    : IconlyLight.star,
                color: AppColors.warning,
                size: 32,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              onPressed: () => onChanged(starVal),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAverageRatingRow({
    required IconData icon,
    required String label,
    required dynamic average,
  }) {
    final val = double.tryParse('$average') ?? 0.0;
    return Row(
      children: [
        Icon(icon, size: 16, color: HCColors.textMuted),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: HCColors.textMuted),
        ),
        const Icon(IconlyBold.star, size: 16, color: AppColors.warning),
        const SizedBox(width: 2),
        Text(
          val.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: HCColors.textDark,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';

class BookingBottomBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double totalPrice;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onNextOrSubmit;

  const BookingBottomBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
    required this.totalPrice,
    required this.isSubmitting,
    required this.onBack,
    required this.onNextOrSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (currentStep > 0) ...[
              OutlinedButton(
                onPressed: isSubmitting ? null : onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Kembali'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Estimasi', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    AppFormatters.formatRupiah(totalPrice),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: HCColor.primary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : onNextOrSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: HCColor.primary,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLastStep ? 'Pesan Sekarang' : 'Lanjut',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  if (currentStep > 0) ...[
                    InkWell(
                      onTap: isSubmitting ? null : onBack,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Icon(
                            IconlyLight.arrowLeft2,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Estimasi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatRupiah(totalPrice),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: HCColor.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : onNextOrSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HCColor.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: HCColor.primary.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child:
                        isSubmitting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLastStep ? 'Pesan Sekarang' : 'Lanjut',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (!isLastStep) ...[
                                  const SizedBox(width: 6),
                                  const Icon(IconlyLight.arrowRight2, size: 16),
                                ],
                              ],
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

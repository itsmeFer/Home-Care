import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';

class BookingStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  final double horizontalPadding;

  const BookingStepIndicator({
    super.key,
    required this.currentStep,
    this.steps = const ['Jadwal', 'Lokasi', 'Pasien', 'Add-ons', 'Review'],
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF2F6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isActive = index == currentStep;
          final isDone = index < currentStep;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isActive ? 34 : 28,
                    height: isActive ? 34 : 28,
                    decoration: BoxDecoration(
                      color: isDone
                          ? HCColor.primary
                          : (isActive ? HCColor.primary : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone || isActive
                            ? HCColor.primary
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: HCColor.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(
                              IconlyBold.tickSquare,
                              color: Colors.white,
                              size: 14,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: isActive ? 13 : 11,
                                fontWeight: FontWeight.w800,
                                color: isActive ? Colors.white : Colors.grey.shade500,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? HCColor.primary
                          : (isDone ? Colors.black87 : Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
              if (index < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    width: 14,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: index < currentStep
                        ? HCColor.primary
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

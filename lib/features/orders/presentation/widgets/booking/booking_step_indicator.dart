import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class BookingStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  final double horizontalPadding;

  const BookingStepIndicator({
    super.key,
    required this.currentStep,
    this.steps = const ['Jadwal', 'Lokasi', 'Detail', 'Add-ons', 'Ringkasan'],
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: List.generate(steps.length, (index) {
            final isActive = index == currentStep;
            final isDone = index < currentStep;

            return Padding(
              padding: EdgeInsets.only(
                right: index == steps.length - 1 ? 0 : 14,
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDone
                          ? HCColor.primary
                          : (isActive ? HCColor.lightTeal : Colors.grey[200]),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? HCColor.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isActive ? HCColor.primary : Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? HCColor.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

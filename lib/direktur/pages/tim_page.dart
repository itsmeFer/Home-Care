import 'package:flutter/material.dart';
import 'package:home_care/features/reports/presentation/dashboard_tim_screen.dart';

export 'package:home_care/features/reports/presentation/dashboard_tim_screen.dart';

class TimPage extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const TimPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardTimScreen(
      role: 'direktur',
      isDesktop: isDesktop,
      isTablet: isTablet,
      range: range,
      showManagerialActions: true,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/features/reports/presentation/dashboard_overview_screen.dart';

class OverviewPage extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const OverviewPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardOverviewScreen(
      isDesktop: isDesktop,
      isTablet: isTablet,
      range: range,
      role: 'direktur',
    );
  }
}

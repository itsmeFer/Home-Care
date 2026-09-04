import 'package:flutter/material.dart';
import 'package:home_care/features/reports/presentation/dashboard_overview_screen.dart';

class ManagerOverviewPage extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const ManagerOverviewPage({
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
      role: 'manager',
    );
  }
}

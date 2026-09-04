import 'package:flutter/material.dart';
import 'package:home_care/features/reports/presentation/dashboard_pasien_screen.dart';

export 'package:home_care/features/reports/presentation/dashboard_pasien_screen.dart';

class PasienPage extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const PasienPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardPasienScreen(
      role: 'direktur',
      isDesktop: isDesktop,
      isTablet: isTablet,
      range: range,
    );
  }
}

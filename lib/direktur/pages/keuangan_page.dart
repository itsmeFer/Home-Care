import 'package:flutter/material.dart';
import 'package:home_care/features/reports/presentation/dashboard_keuangan_screen.dart';

export 'package:home_care/features/reports/presentation/dashboard_keuangan_screen.dart';

class KeuanganPage extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const KeuanganPage({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardKeuanganScreen(
      role: 'direktur',
      isDesktop: isDesktop,
      isTablet: isTablet,
      range: range,
    );
  }
}

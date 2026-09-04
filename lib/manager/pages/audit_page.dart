import 'package:flutter/material.dart';
import 'package:home_care/features/reports/presentation/dashboard_audit_screen.dart';

class AuditPageManager extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const AuditPageManager({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardAuditScreen(
      isDesktop: isDesktop,
      isTablet: isTablet,
      range: range,
      role: 'manager',
    );
  }
}

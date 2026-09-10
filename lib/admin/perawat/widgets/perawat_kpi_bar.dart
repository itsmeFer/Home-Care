import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class PerawatKpiBar extends StatelessWidget {
  final int total;
  final int active;
  final int pending;
  final int verified;
  final int rejected;

  const PerawatKpiBar({
    super.key,
    required this.total,
    required this.active,
    required this.pending,
    required this.verified,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Card(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _miniKpi('Total', '$total'),
              _miniKpi('Active', '$active'),
              _miniKpi('Pending', '$pending'),
              _miniKpi('Verified', '$verified'),
              _miniKpi('Rejected', '$rejected'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniKpi(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: HCColor.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HCColor.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: HCColor.primaryDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String hint;
  final IconData icon;
  final Color accent;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
    required this.accent,
  });

  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: .06),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: .12),
              border: Border.all(color: accent.withValues(alpha: .22)),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 12.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 16.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

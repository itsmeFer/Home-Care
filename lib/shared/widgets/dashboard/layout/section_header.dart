import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .2,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 12.6,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

import 'package:flutter/material.dart';

class XCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const XCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kText,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.8,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: kMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const DotMenu(),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class DotMenu extends StatelessWidget {
  const DotMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF8FAFC),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

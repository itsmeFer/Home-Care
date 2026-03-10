import 'dart:ui';
import 'package:flutter/material.dart';

/* ============================================================
  REUSABLE: SECTION HEADER
============================================================ */
class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, required this.subtitle, this.trailing});

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
              const SizedBox(height: 3),
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

/* ============================================================
  REUSABLE: CARDS
============================================================ */
class XCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const XCard({super.key, required this.title, required this.subtitle, required this.child});

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
            color: Colors.black.withOpacity(.06),
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
                    Text(title, style: const TextStyle(color: kText, fontWeight: FontWeight.w900, fontSize: 13.8)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600, fontSize: 12.2),
                    ),
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
        child: const Icon(Icons.more_horiz_rounded, size: 18, color: Color(0xFF64748B)),
      ),
    );
  }
}

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
            color: Colors.black.withOpacity(.06),
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
              color: accent.withOpacity(.12),
              border: Border.all(color: accent.withOpacity(.22)),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: kMuted, fontSize: 12.3, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: kText, fontSize: 16.8, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(hint, style: const TextStyle(color: kMuted, fontSize: 12.0, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
  REUSABLE: LAYOUT HELPERS
============================================================ */
class ResponsiveGrid extends StatelessWidget {
  final int columns;
  final double gap;
  final List<Widget> children;

  const ResponsiveGrid({super.key, required this.columns, required this.gap, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final itemW = (w - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((e) => SizedBox(
                    width: itemW.isFinite ? itemW : w,
                    child: e,
                  ))
              .toList(),
        );
      },
    );
  }
}

class ResponsiveSplit extends StatelessWidget {
  final Widget left;
  final Widget right;
  final bool isDesktop;

  const ResponsiveSplit({super.key, required this.left, required this.right, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) {
      return Column(
        children: [
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

/* ============================================================
  PLACEHOLDERS (CHARTS)
============================================================ */
class ChartPlaceholder extends StatelessWidget {
  final double height;
  const ChartPlaceholder({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
        ),
      ),
      child: CustomPaint(
        painter: _WavesPainter(),
        child: const Center(
          child: Text(
            'Chart Placeholder',
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class PiePlaceholder extends StatelessWidget {
  final double height;
  const PiePlaceholder({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: const Color(0xFFF8FAFC),
      ),
      child: CustomPaint(
        painter: _PiePainter(),
        child: const Center(
          child: Text(
            'Pie Placeholder',
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF0EA5E9).withOpacity(.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final paint2 = Paint()
      ..color = const Color(0xFF22C55E).withOpacity(.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final p1 = Path();
    final p2 = Path();

    for (double x = 0; x <= size.width; x += 10) {
      final y1 = size.height * 0.58 + (12 * (x / size.width) * (1 - (x / size.width))) * (x % 30 < 15 ? 1 : -1);
      final y2 = size.height * 0.42 + (10 * (x / size.width) * (1 - (x / size.width))) * (x % 40 < 20 ? -1 : 1);
      if (x == 0) {
        p1.moveTo(x, y1);
        p2.moveTo(x, y2);
      } else {
        p1.lineTo(x, y1);
        p2.lineTo(x, y2);
      }
    }

    canvas.drawPath(p1, paint1);
    canvas.drawPath(p2, paint2);

    final grid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PiePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 18;

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;

    p.color = const Color(0xFF0EA5E9).withOpacity(.35);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.2, 2.0, false, p);

    p.color = const Color(0xFF22C55E).withOpacity(.30);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0.9, 1.4, false, p);

    p.color = const Color(0xFFF59E0B).withOpacity(.28);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 2.4, 1.1, false, p);

    final inner = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 18, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LegendRow extends StatelessWidget {
  const LegendRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: const [
        LegendDot(label: 'Income', color: Color(0xFF0EA5E9)),
        LegendDot(label: 'Fee', color: Color(0xFFF59E0B)),
        LegendDot(label: 'Profit', color: Color(0xFF22C55E)),
      ],
    );
  }
}

class LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const LegendDot({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12.2),
        ),
      ],
    );
  }
}

/* ============================================================
  SIMPLE BAR LIST
============================================================ */
class BarItem {
  final String name;
  final String value;
  final double pct;
  const BarItem(this.name, this.value, this.pct);
}

class SimpleBarList extends StatelessWidget {
  final List<BarItem> items;
  const SimpleBarList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.name,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                      Text(
                        e.value,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: e.pct,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF0EA5E9)),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/* ============================================================
  TABLE CARD
============================================================ */
class TableCard extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;

  const TableCard({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: columns
                    .map(
                      (c) => Expanded(
                        child: Text(
                          c,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w900,
                            fontSize: 12.2,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ...rows.map(
              (r) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: r
                          .asMap()
                          .entries
                          .map(
                            (entry) => Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  color: entry.key == 0 ? const Color(0xFF0F172A) : const Color(0xFF334155),
                                  fontWeight: entry.key == 0 ? FontWeight.w900 : FontWeight.w700,
                                  fontSize: 12.8,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
  BULLETS + QUICK ACTIONS
============================================================ */
class BulletList extends StatelessWidget {
  final List<String> items;
  const BulletList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 8, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.8,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class ActionChipX extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionChipX({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          color: const Color(0xFFFFFFFF),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 12.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OutlineButtonX extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const OutlineButtonX({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 12.6),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
  PILL BADGE
============================================================ */
class PillBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  const PillBadge({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0EA5E9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 12.2,
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
  SMALL HELPERS
============================================================ */
class LoadingCard extends StatelessWidget {
  final String title;
  const LoadingCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return XCard(
      title: title,
      subtitle: 'Mengambil data...',
      child: Row(
        children: const [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Loading...',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  const ErrorCard({super.key, required this.title, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return XCard(
      title: title,
      subtitle: 'Gagal memuat',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                color: const Color(0xFFF8FAFC),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

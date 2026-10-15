import 'package:flutter/material.dart';

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
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
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
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 =
        Paint()
          ..color = const Color(0xFF0EA5E9).withValues(alpha: .12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final paint2 =
        Paint()
          ..color = const Color(0xFF22C55E).withValues(alpha: .10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final p1 = Path();
    final p2 = Path();

    for (double x = 0; x <= size.width; x += 10) {
      final y1 =
          size.height * 0.58 +
          (12 * (x / size.width) * (1 - (x / size.width))) *
              (x % 30 < 15 ? 1 : -1);
      final y2 =
          size.height * 0.42 +
          (10 * (x / size.width) * (1 - (x / size.width))) *
              (x % 40 < 20 ? -1 : 1);
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

    final grid =
        Paint()
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

    final p =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18;

    p.color = const Color(0xFF0EA5E9).withValues(alpha: .35);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.2,
      2.0,
      false,
      p,
    );

    p.color = const Color(0xFF22C55E).withValues(alpha: .30);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.9,
      1.4,
      false,
      p,
    );

    p.color = const Color(0xFFF59E0B).withValues(alpha: .28);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.4,
      1.1,
      false,
      p,
    );

    final inner =
        Paint()
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 12.2,
          ),
        ),
      ],
    );
  }
}

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
      children:
          items
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
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF0EA5E9),
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

import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final int columns;
  final double gap;
  final List<Widget> children;

  const ResponsiveGrid({
    super.key,
    required this.columns,
    required this.gap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final itemW = (w - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
              children
                  .map(
                    (e) =>
                        SizedBox(width: itemW.isFinite ? itemW : w, child: e),
                  )
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

  const ResponsiveSplit({
    super.key,
    required this.left,
    required this.right,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDesktop) {
      return Column(children: [left, const SizedBox(height: 12), right]);
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

import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final double radius;

  const SkeletonBox({
    required this.height,
    required this.width,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ProfilePageSkeleton extends StatelessWidget {
  const ProfilePageSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth =
            constraints.maxWidth >= 1200
                ? 900
                : constraints.maxWidth >= 900
                ? 760
                : constraints.maxWidth >= 600
                ? 620
                : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: const [
                        SkeletonBox(height: 72, width: 72, radius: 36),
                        SizedBox(height: 14),
                        SkeletonBox(height: 20, width: 180),
                        SizedBox(height: 8),
                        SkeletonBox(height: 14, width: 140),
                        SizedBox(height: 8),
                        SkeletonBox(height: 14, width: 200),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SkeletonSectionCard(lines: 3),
                  const SizedBox(height: 14),
                  const SkeletonSectionCard(lines: 6),
                  const SizedBox(height: 14),
                  const SkeletonSectionCard(lines: 3),
                  const SizedBox(height: 24),
                  const SkeletonBox(
                    height: 52,
                    width: double.infinity,
                    radius: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class EditProfileSkeleton extends StatelessWidget {
  const EditProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool twoColumn = width >= 700;

    Widget field() =>
        const SkeletonBox(height: 58, width: double.infinity, radius: 16);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: const [
                SkeletonBox(height: 56, width: 56, radius: 28),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 18, width: 160),
                      SizedBox(height: 8),
                      SkeletonBox(height: 14, width: 120),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, width: 220),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  color: Color(0x14000000),
                ),
              ],
            ),
            child: Column(
              children: [
                if (twoColumn)
                  Row(
                    children: [
                      Expanded(child: field()),
                      const SizedBox(width: 12),
                      Expanded(child: field()),
                    ],
                  )
                else ...[
                  field(),
                  const SizedBox(height: 12),
                  field(),
                ],
                const SizedBox(height: 12),
                if (twoColumn)
                  Row(
                    children: [
                      Expanded(child: field()),
                      const SizedBox(width: 12),
                      Expanded(child: field()),
                    ],
                  )
                else ...[
                  field(),
                  const SizedBox(height: 12),
                  field(),
                ],
                const SizedBox(height: 12),
                if (twoColumn)
                  Row(
                    children: [
                      Expanded(child: field()),
                      const SizedBox(width: 12),
                      Expanded(child: field()),
                    ],
                  )
                else ...[
                  field(),
                  const SizedBox(height: 12),
                  field(),
                ],
                const SizedBox(height: 12),
                const SkeletonBox(
                  height: 88,
                  width: double.infinity,
                  radius: 16,
                ),
                const SizedBox(height: 12),
                if (twoColumn)
                  Row(
                    children: [
                      Expanded(child: field()),
                      const SizedBox(width: 12),
                      Expanded(child: field()),
                    ],
                  )
                else ...[
                  field(),
                  const SizedBox(height: 12),
                  field(),
                ],
                const SizedBox(height: 12),
                if (twoColumn)
                  Row(
                    children: [
                      Expanded(child: field()),
                      const SizedBox(width: 12),
                      Expanded(child: field()),
                    ],
                  )
                else ...[
                  field(),
                  const SizedBox(height: 12),
                  field(),
                ],
                const SizedBox(height: 12),
                if (twoColumn)
                  Row(
                    children: [
                      Expanded(child: field()),
                      const SizedBox(width: 12),
                      Expanded(child: field()),
                    ],
                  )
                else ...[
                  field(),
                  const SizedBox(height: 12),
                  field(),
                ],
                const SizedBox(height: 12),
                const SkeletonBox(
                  height: 76,
                  width: double.infinity,
                  radius: 16,
                ),
                const SizedBox(height: 12),
                const SkeletonBox(
                  height: 76,
                  width: double.infinity,
                  radius: 16,
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(
                      child: SkeletonBox(
                        height: 52,
                        width: double.infinity,
                        radius: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: SkeletonBox(
                        height: 52,
                        width: double.infinity,
                        radius: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonSectionCard extends StatelessWidget {
  final int lines;

  const SkeletonSectionCard({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 18, width: 160),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...List.generate(
            lines,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonBox(
                height: 16,
                width: double.infinity,
                radius: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const ProfileSectionCard({required this.title, required this.children, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: const Color(0xFF0BA5A7)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final muted = Colors.black54;
    final bool compact = width < 420;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

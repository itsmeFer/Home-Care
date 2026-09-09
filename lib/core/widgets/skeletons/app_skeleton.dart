import 'package:flutter/material.dart';

/// Fondasi utama Skeleton loader dengan animasi denyut (pulsing shimmer).
/// Sangat ringan dan tidak bergantung pada package eksternal apapun.
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  const AppSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 10,
    this.margin,
    this.padding,
    this.child,
  }) : shape = BoxShape.rectangle;

  /// Bentuk lingkaran (Cocok untuk avatar pengguna atau icon bundar)
  const AppSkeleton.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        shape = BoxShape.circle,
        padding = null,
        child = null;

  /// Bentuk garis teks (Cocok untuk placeholder judul, subjudul, paragraf)
  const AppSkeleton.text({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = 6,
    this.margin,
  })  : shape = BoxShape.rectangle,
        padding = null,
        child = null;

  /// Bentuk kontainer kartu besar (Cocok untuk kartu pesanan atau profil)
  const AppSkeleton.card({
    super.key,
    this.height = 120,
    this.width = double.infinity,
    this.borderRadius = 16,
    this.margin,
    this.padding,
    this.child,
  }) : shape = BoxShape.rectangle;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double v = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-2.2 + (v * 4.4), -0.2),
              end: Alignment(-0.2 + (v * 4.4), 0.2),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

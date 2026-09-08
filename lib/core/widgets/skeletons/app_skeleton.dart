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
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    // Palet warna shimmer: dari abu-abu slate muda ke abu-abu lembut
    _colorAnimation = ColorTween(
      begin: const Color(0xFFE2E8F0),
      end: const Color(0xFFF1F5F9),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        );
      },
    );
  }
}

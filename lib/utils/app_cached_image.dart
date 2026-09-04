import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Reusable optimized image widget that combines disk caching,
/// memory decoding constraints, and clean loading/error states.
class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl?.trim();

    if (cleanUrl == null || cleanUrl.isEmpty) {
      return _buildErrorWidget();
    }

    Widget content;

    if (kIsWeb) {
      content = Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildErrorWidget();
        },
      );
    } else {
      // Calculate responsive memory cache constraints if not explicitly provided
      final mq = MediaQuery.maybeOf(context);
      final dpr = mq?.devicePixelRatio ?? 2.0;

      int? computedCacheWidth = memCacheWidth;
      int? computedCacheHeight = memCacheHeight;

      if (computedCacheWidth == null && width != null && width! > 0) {
        computedCacheWidth = (width! * dpr).round().clamp(100, 1920);
      } else if (computedCacheWidth == null && mq != null) {
        computedCacheWidth = (mq.size.width * dpr).round().clamp(300, 1920);
      }

      if (computedCacheHeight == null && height != null && height! > 0) {
        computedCacheHeight = (height! * dpr).round().clamp(100, 1920);
      }

      content = CachedNetworkImage(
        imageUrl: cleanUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: computedCacheWidth,
        memCacheHeight: computedCacheHeight,
        placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
        errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 150),
      );
    }

    if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? const Color(0xFFF2F4F7),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0BA5A7)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? const Color(0xFFF2F4F7),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.black26,
        size: 28,
      ),
    );
  }
}

/// Circular avatar with automatic disk caching and low-RAM decoding.
class AppCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;

  const AppCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 24.0,
    this.fallbackIcon = Icons.person,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final cleanUrl = imageUrl?.trim();
    final effectiveBg = backgroundColor ?? const Color(0xFFE0F7F7);
    final effectiveFg = foregroundColor ?? const Color(0xFF0BA5A7);

    // Compute memory cache width: radius * 2 * DPR (around 100-250px)
    final cachePx = (size * 2.5).round().clamp(64, 300);

    Widget avatarContent;

    if (cleanUrl != null && cleanUrl.isNotEmpty) {
      if (kIsWeb) {
        avatarContent = Image.network(
          cleanUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: effectiveBg,
              child: Center(
                child: SizedBox(
                  width: radius * 0.7,
                  height: radius * 0.7,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: effectiveBg,
            child: Icon(fallbackIcon, size: radius * 1.1, color: effectiveFg),
          ),
        );
      } else {
        avatarContent = CachedNetworkImage(
          imageUrl: cleanUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: cachePx,
          memCacheHeight: cachePx,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: effectiveBg,
            child: Center(
              child: SizedBox(
                width: radius * 0.7,
                height: radius * 0.7,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            color: effectiveBg,
            child: Icon(fallbackIcon, size: radius * 1.1, color: effectiveFg),
          ),
        );
      }
    } else {
      avatarContent = Container(
        width: size,
        height: size,
        color: effectiveBg,
        child: Icon(fallbackIcon, size: radius * 1.1, color: effectiveFg),
      );
    }

    final circularWidget = ClipOval(
      child: avatarContent,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: circularWidget,
      );
    }

    return circularWidget;
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';

const Color kPrimary = Color(0xFF2563EB);
const Color kText = AppColors.textPrimary;
const Color kTextSub = AppColors.textSecondary;
const Color kDanger = AppColors.danger;
const Color kSuccess = AppColors.success;
const Color kAddon = Color(0xFF7C3AED);
const Color kBorder = AppColors.border;
const Color kCard = AppColors.card;

String get kBaseUrl => ApiConstants.baseUrl;
String get kApiBase => ApiConstants.apiBase;
String get kFeeLayananUrl => ApiConstants.adminFeeLayanan;
String get kFeeRulesUrl => ApiConstants.adminFeeRules;
String get kFeeAddonsUrl => ApiConstants.adminFeeAddons;
String get kFeeAddonRulesUrl => ApiConstants.adminFeeAddonRules;
String get kFeeUsersUrl => ApiConstants.adminFeeUsers;
String get kFeeCreateUserUrl => ApiConstants.adminFeeCreateUser;
String get kRolesUrl => ApiConstants.adminRoles;

class FeeApiBridge {
  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, String>? query,
  }) async {
    final res = await ApiClient.get(url, queryParams: query);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> postJson(
    String url,
    Map<String, dynamic> payload,
  ) async {
    final res = await ApiClient.post(url, body: payload);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> putJson(
    String url,
    Map<String, dynamic> payload,
  ) async {
    final res = await ApiClient.put(url, body: payload);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> deleteJson(String url) async {
    final res = await ApiClient.delete(url);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return <String, dynamic>{};
  }
}

Widget avatarCircle({
  required String? url,
  required IconData fallback,
  double radius = 22,
}) {
  if (url == null || url.trim().isEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: kPrimary.withOpacity(0.10),
      child: Icon(fallback, color: kPrimary),
    );
  }

  return CircleAvatar(
    radius: radius,
    backgroundColor: kPrimary.withOpacity(0.10),
    backgroundImage: NetworkImage(url),
    onBackgroundImageError: (_, __) {},
    child: null,
  );
}

class R {
  static double w(BuildContext c) => MediaQuery.of(c).size.width;

  static bool isPhone(BuildContext c) => w(c) < 600;
  static bool isTablet(BuildContext c) => w(c) >= 600 && w(c) < 1024;
  static bool isDesktop(BuildContext c) => w(c) >= 1024;

  static double contentMaxWidth(BuildContext c) {
    final width = w(c);
    if (width >= 1400) return 1120;
    if (width >= 1200) return 1040;
    if (width >= 1024) return 960;
    return width;
  }

  static EdgeInsets pagePadding(BuildContext c) {
    if (isPhone(c)) return const EdgeInsets.all(14);
    if (isTablet(c)) return const EdgeInsets.all(18);
    return const EdgeInsets.all(22);
  }

  static double dialogWidth(BuildContext c, {double max = 720}) {
    final width = w(c);
    final v = (width * 0.92).clamp(320, max);
    return v.toDouble();
  }

  static double dialogHeight(BuildContext c, {double max = 620}) {
    final h = MediaQuery.of(c).size.height;
    final v = (h * 0.86).clamp(420, max);
    return v.toDouble();
  }
}

String? resolveMediaUrl(dynamic raw) => ApiConstants.resolveMediaUrl(raw);

InputDecoration fieldDeco({String? hint, Widget? prefixIcon}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextSub),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDanger, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

String formatRupiah(num value) => AppFormatters.formatRupiah(value);

List<Map<String, dynamic>> extractList(dynamic res) {
  if (res is List) return res.cast<Map<String, dynamic>>();

  if (res is Map) {
    final d = res['data'];
    if (d is List) return d.cast<Map<String, dynamic>>();
    if (d is Map && d['data'] is List) {
      return (d['data'] as List).cast<Map<String, dynamic>>();
    }
  }
  return [];
}

class RBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool filled;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double radius;

  const RBtn({
    super.key,
    required this.child,
    required this.onPressed,
    required this.filled,
    this.color,
    this.textColor,
    this.icon,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (filled ? kPrimary : Colors.white);
    final fg = textColor ?? (filled ? Colors.white : kPrimary);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: filled ? bg : Colors.white,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              border: filled ? null : Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: fg, fontWeight: FontWeight.w800),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MiniChip extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;
  const MiniChip({super.key, required this.text, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kPrimary;
    final bg = c.withOpacity(0.10);
    final bd = c.withOpacity(0.28);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: bd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              color: kText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class FeeLabel extends StatelessWidget {
  final String text;
  const FeeLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: kTextSub, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String message;
  const ErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDanger.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDanger.withOpacity(0.28)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: kText, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class HintBox extends StatelessWidget {
  final String text;
  const HintBox({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(color: kTextSub, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class MiniCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const MiniCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class RoundedDialog extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;

  const RoundedDialog({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? R.dialogWidth(context);
    final h = height ?? R.dialogHeight(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: w,
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Material(
            color: Colors.white,
            child: child,
          ),
        ),
      ),
    );
  }
}

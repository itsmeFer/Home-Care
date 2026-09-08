import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/core/theme/app_colors.dart';

/// Komponen AppBar & TabBar konsisten untuk seluruh halaman Pasien (User)
class PatientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;
  final Color backgroundColor;
  final double elevation;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const PatientAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.centerTitle = true,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
    this.backgroundColor = AppColors.primary,
    this.elevation = 0,
    this.systemOverlayStyle,
  });

  /// Factory constructor praktis untuk halaman yang memiliki TabBar (seperti Pesanan Saya)
  factory PatientAppBar.withTabs({
    Key? key,
    required String title,
    required List<Widget> tabs,
    TabController? tabController,
    List<Widget>? actions,
    Widget? leading,
    bool showBackButton = true,
    VoidCallback? onBackPressed,
    bool isScrollable = false,
    ValueChanged<int>? onTabTap,
    Color backgroundColor = AppColors.primary,
  }) {
    return PatientAppBar(
      key: key,
      title: title,
      actions: actions,
      leading: leading,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
      backgroundColor: backgroundColor,
      bottom: PatientTabBar(
        controller: tabController,
        tabs: tabs,
        isScrollable: isScrollable,
        onTap: onTabTap,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  Widget _buildLeading(BuildContext context) {
    if (leading != null) return leading!;

    final canPop = Navigator.canPop(context);
    if (!canPop && !showBackButton) return const SizedBox.shrink();

    return Center(
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onBackPressed ?? () => Navigator.maybePop(context),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final hasLeading = leading != null || (showBackButton && canPop);

    return AppBar(
      elevation: elevation,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor,
      systemOverlayStyle: systemOverlayStyle ?? SystemUiOverlayStyle.light,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: hasLeading ? _buildLeading(context) : null,
      leadingWidth: hasLeading ? 54 : 16,
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                )
              : null),
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: 8),
            ]
          : null,
      bottom: bottom,
    );
  }
}

/// TabBar standar konsisten dengan tema Primary & indikator putih
class PatientTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<Widget> tabs;
  final ValueChanged<int>? onTap;
  final bool isScrollable;

  const PatientTabBar({
    super.key,
    this.controller,
    required this.tabs,
    this.onTap,
    this.isScrollable = false,
  });

  /// Helper untuk membuat Tab dengan badge hitungan (seperti di Pesanan Saya: Belum Bayar [3])
  static Widget buildTab({
    required String label,
    int? count,
    Color? countColor,
  }) {
    if (count == null || count <= 0) {
      return Tab(text: label);
    }

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: countColor ?? AppColors.danger,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      onTap: onTap,
      isScrollable: isScrollable,
      tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.center,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      tabs: tabs,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/users/chat/pasien_chat_list_page.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/lihat_histori_pemesanan.dart';
import 'package:home_care/users/profile.dart';
import 'views/home_feed_view.dart';
import 'widgets/home_bottom_nav.dart';

export 'models/home_models.dart';
export 'services/home_service.dart';
export 'views/home_feed_view.dart';
export 'widgets/home_bottom_nav.dart';

String formatRupiah(dynamic value) => AppFormatters.formatRupiah(value);

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  /// Static helper untuk berpindah tab dari mana saja di dalam aplikasi
  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_HomePageState>();
    if (state != null) {
      state.setTab(index);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomePage(initialIndex: index)),
        (route) => false,
      );
    }
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;
  final Set<int> _activatedTabs = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _activatedTabs.add(_currentIndex);
  }

  void setTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        _activatedTabs.add(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: HCColor.bg,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const HomeFeedView(),
            _activatedTabs.contains(1)
                ? const PilihLayananPage()
                : const SizedBox.shrink(),
            _activatedTabs.contains(2)
                ? const PasienChatListPage()
                : const SizedBox.shrink(),
            _activatedTabs.contains(3)
                ? const LihatHistoriPemesananPage()
                : const SizedBox.shrink(),
            _activatedTabs.contains(4)
                ? const ProfilePage()
                : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: HCBottomNav(
          currentIndex: _currentIndex,
          onTap: setTab,
        ),
      ),
    );
  }
}


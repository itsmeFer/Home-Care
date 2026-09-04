import 'package:flutter/material.dart';
import 'package:home_care/features/support_it/presentation/lapor_it_screen.dart';

export 'package:home_care/features/support_it/presentation/lapor_it_screen.dart';

class LaporITPageManager extends StatelessWidget {
  const LaporITPageManager({super.key});

  @override
  Widget build(BuildContext context) {
    return const LaporITScreen(
      source: 'manager.lapor_it',
      title: 'Lapor IT Support',
    );
  }
}

class RiwayatLaporanITPageManager extends StatelessWidget {
  const RiwayatLaporanITPageManager({super.key});

  @override
  Widget build(BuildContext context) {
    return const RiwayatLaporanITScreen(
      source: 'manager.lapor_it',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/features/support_it/presentation/lapor_it_screen.dart';

export 'package:home_care/features/support_it/presentation/lapor_it_screen.dart';

class LaporITPageAdmin extends StatelessWidget {
  const LaporITPageAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return const LaporITScreen(
      source: 'admin.lapor_it',
      title: 'Lapor IT Support',
    );
  }
}

class RiwayatLaporanITPageAdmin extends StatelessWidget {
  const RiwayatLaporanITPageAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return const RiwayatLaporanITScreen(
      source: 'admin.lapor_it',
    );
  }
}

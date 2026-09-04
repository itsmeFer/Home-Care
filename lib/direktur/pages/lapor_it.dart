import 'package:flutter/material.dart';
import 'package:home_care/features/support_it/presentation/lapor_it_screen.dart';

export 'package:home_care/features/support_it/presentation/lapor_it_screen.dart';

class LaporITPage extends StatelessWidget {
  const LaporITPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LaporITScreen(
      source: 'direktur.lapor_it',
      title: 'Lapor IT Support',
    );
  }
}

class RiwayatLaporanITPageState extends StatelessWidget {
  const RiwayatLaporanITPageState({super.key});

  @override
  Widget build(BuildContext context) {
    return const RiwayatLaporanITScreen(
      source: 'direktur.lapor_it',
    );
  }
}

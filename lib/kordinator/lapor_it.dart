import 'package:flutter/material.dart';
import 'package:home_care/features/support_it/presentation/lapor_it_screen.dart';

export 'package:home_care/features/support_it/presentation/lapor_it_screen.dart';

class LaporITPageKoordinator extends StatelessWidget {
  const LaporITPageKoordinator({super.key});

  @override
  Widget build(BuildContext context) {
    return const LaporITScreen(
      source: 'koordinator.lapor_it',
      title: 'Lapor IT Support',
    );
  }
}

class RiwayatLaporanITPageKoordinator extends StatelessWidget {
  const RiwayatLaporanITPageKoordinator({super.key});

  @override
  Widget build(BuildContext context) {
    return const RiwayatLaporanITScreen(
      source: 'koordinator.lapor_it',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/features/support_it/presentation/lapor_it_screen.dart';

export 'package:home_care/features/support_it/presentation/lapor_it_screen.dart';

class LaporITPagePerawat extends StatelessWidget {
  const LaporITPagePerawat({super.key});

  @override
  Widget build(BuildContext context) {
    return const LaporITScreen(
      source: 'perawat.lapor_it',
      title: 'Lapor IT Support',
    );
  }
}

class RiwayatLaporanITPagePerawat extends StatelessWidget {
  const RiwayatLaporanITPagePerawat({super.key});

  @override
  Widget build(BuildContext context) {
    return const RiwayatLaporanITScreen(
      source: 'perawat.lapor_it',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/patient_app_bar.dart';
import 'widgets/widgets.dart';

export 'widgets/widgets.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  static const List<String> medicalFeatures = [
    'Pendaftaran Pasien & Rekam Medis',
    'Pencatatan Tanda Vital',
    'SOAP Notes',
    'Perawatan Luka / Home Nursing',
    'Rencana Perawatan (Care Plan)',
    'Manajemen Obat & Pengingat',
    'Hasil Lab & Radiologi',
    'Jadwal Kunjungan',
    'Edukasi Kesehatan',
  ];

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PatientAppBar(title: 'Semua Menu'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServicesGridMenu(),
            SizedBox(height: 16),
            MenuGroupSection(
              title: 'Fitur Medis',
              items: medicalFeatures,
            ),
            SizedBox(height: 16),
            SettingsGroupSection(),
          ],
        ),
      ),
    );
  }
}

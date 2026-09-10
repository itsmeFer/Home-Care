import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class PerawatExtraFields extends StatelessWidget {
  final TextEditingController profesiC;
  final TextEditingController keahlianC;
  final TextEditingController noStrC;
  final TextEditingController noSipC;
  final TextEditingController tahunExpC;
  final TextEditingController tempatKerjaC;
  final TextEditingController wilayahC;
  final TextEditingController alamatC;
  final TextEditingController kdNamaC;
  final TextEditingController kdHpC;
  final TextEditingController kdHubunganC;

  const PerawatExtraFields({
    super.key,
    required this.profesiC,
    required this.keahlianC,
    required this.noStrC,
    required this.noSipC,
    required this.tahunExpC,
    required this.tempatKerjaC,
    required this.wilayahC,
    required this.alamatC,
    required this.kdNamaC,
    required this.kdHpC,
    required this.kdHubunganC,
  });

  Widget _section(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: HCColor.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 13.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _section('Profesional'),
        const SizedBox(height: 8),
        TextFormField(
          controller: profesiC,
          decoration: const InputDecoration(
            labelText: 'Profesi (opsional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: keahlianC,
          decoration: const InputDecoration(
            labelText: 'Keahlian (opsional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: noStrC,
                decoration: const InputDecoration(
                  labelText: 'No STR (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: noSipC,
                decoration: const InputDecoration(
                  labelText: 'No SIP (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _section('Pengalaman'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: tahunExpC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tahun Pengalaman',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: tempatKerjaC,
                decoration: const InputDecoration(
                  labelText: 'Tempat Kerja Terakhir (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _section('Area Kerja'),
        const SizedBox(height: 8),
        TextFormField(
          controller: wilayahC,
          decoration: const InputDecoration(
            labelText: 'Wilayah (opsional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: alamatC,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Alamat (opsional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        _section('Kontak Darurat'),
        const SizedBox(height: 8),
        TextFormField(
          controller: kdNamaC,
          decoration: const InputDecoration(
            labelText: 'Nama Kontak Darurat (opsional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: kdHpC,
                decoration: const InputDecoration(
                  labelText: 'No HP Darurat (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: kdHubunganC,
                decoration: const InputDecoration(
                  labelText: 'Hubungan (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

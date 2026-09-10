import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'profile_avatar_header.dart';
import 'profile_security_section.dart';
import 'profile_ui_components.dart';

class ProfileViewMode extends StatelessWidget {
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? pasien;
  final String? fotoProfilUrl;
  final File? localFotoFile;
  final VoidCallback onLogout;

  const ProfileViewMode({
    super.key,
    required this.user,
    required this.pasien,
    required this.fotoProfilUrl,
    required this.localFotoFile,
    required this.onLogout,
  });

  String _formatDisplayDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nama = (pasien?['nama_lengkap'] ?? user?['name'] ?? 'Pasien').toString();
    final noRm = (pasien?['no_rekam_medis'] ?? '-').toString();
    final noHp = (pasien?['no_hp'] ?? '-').toString();
    final email = (user?['email'] ?? pasien?['email'] ?? '-').toString();
    final jk = (pasien?['jenis_kelamin'] ?? '-').toString();
    final tglLahir = _formatDisplayDate(pasien?['tanggal_lahir']);

    final nik = (pasien?['nik'] ?? '-').toString();
    final alamat = (pasien?['alamat'] ?? '-').toString();
    final kodePos = (pasien?['kode_pos'] ?? '-').toString();

    final provinsi = (pasien?['provinsi'] ?? '-').toString();
    final kota = (pasien?['kota'] ?? '-').toString();
    final kecamatan = (pasien?['kecamatan'] ?? '-').toString();
    final kelurahan = (pasien?['kelurahan'] ?? '-').toString();

    return SingleChildScrollView(
      child: Column(
        children: [
          ProfileAvatarHeader(
            nama: nama,
            noRm: noRm,
            email: email,
            fotoProfilUrl: fotoProfilUrl,
            localFotoFile: localFotoFile,
            isEditMode: false,
          ),
          const SizedBox(height: 16),
          ProfileSectionCard(
            title: 'Data Pribadi',
            icon: IconlyLight.profile,
            children: [
              ProfileInfoRow(label: 'NIK', value: nik),
              ProfileInfoRow(label: 'Jenis Kelamin', value: jk),
              ProfileInfoRow(label: 'Tanggal Lahir', value: tglLahir),
            ],
          ),
          const SizedBox(height: 14),
          ProfileSectionCard(
            title: 'Kontak & Alamat',
            icon: IconlyLight.location,
            children: [
              ProfileInfoRow(label: 'No. HP', value: noHp),
              ProfileInfoRow(label: 'Email', value: email),
              ProfileInfoRow(label: 'Alamat', value: alamat),
              ProfileInfoRow(label: 'Kelurahan', value: kelurahan),
              ProfileInfoRow(label: 'Kecamatan', value: kecamatan),
              ProfileInfoRow(label: 'Kota/Kab', value: kota),
              ProfileInfoRow(label: 'Provinsi', value: provinsi),
              ProfileInfoRow(label: 'Kode Pos', value: kodePos),
            ],
          ),
          const SizedBox(height: 14),
          ProfileSectionCard(
            title: 'Info Medis Dasar',
            icon: IconlyLight.activity,
            children: [
              ProfileInfoRow(
                label: 'Golongan Darah',
                value: (pasien?['golongan_darah'] ?? '-').toString(),
              ),
              ProfileInfoRow(
                label: 'Alergi',
                value: (pasien?['alergi'] ?? '-').toString(),
              ),
              ProfileInfoRow(
                label: 'Penyakit Menahun',
                value: (pasien?['penyakit_menahun'] ?? '-').toString(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProfileSecuritySection(onLogout: onLogout),
        ],
      ),
    );
  }
}

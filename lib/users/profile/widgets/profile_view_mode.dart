import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import '../models/user_profile_models.dart';
import 'profile_avatar_header.dart';
import 'profile_security_section.dart';
import 'profile_ui_components.dart';

class ProfileViewMode extends StatelessWidget {
  final UserModel? user;
  final PasienModel? pasien;
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

  String _formatDisplayDate(DateTime? date) {
    if (date == null) return '-';
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final nama = (pasien?.namaLengkap ?? user?.name ?? 'Pasien');
    final noRm = (pasien?.noRekamMedis ?? '-');
    final noHp = (pasien?.noHp ?? '-');
    final email = (user != null && user!.email.isNotEmpty ? user!.email : pasien?.email ?? '-');
    final jk = (pasien?.jenisKelamin ?? '-');
    final tglLahir = _formatDisplayDate(pasien?.tanggalLahir);

    final nik = (pasien?.nik ?? '-');
    final alamat = (pasien?.alamat ?? '-');
    final kodePos = (pasien?.kodePos ?? '-');

    final provinsi = (pasien?.provinsi ?? '-');
    final kota = (pasien?.kota ?? '-');
    final kecamatan = (pasien?.kecamatan ?? '-');
    final kelurahan = (pasien?.kelurahan ?? '-');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
                value: (pasien?.golonganDarah ?? '-'),
              ),
              ProfileInfoRow(
                label: 'Alergi',
                value: (pasien?.alergi ?? '-'),
              ),
              ProfileInfoRow(
                label: 'Penyakit Menahun',
                value: (pasien?.penyakitMenahun ?? '-'),
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

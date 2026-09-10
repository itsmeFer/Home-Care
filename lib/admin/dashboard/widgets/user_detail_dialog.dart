import 'package:flutter/material.dart';
import 'package:home_care/admin/dashboard/models/admin_dashboard_models.dart';
import 'package:home_care/admin/dashboard/services/admin_dashboard_service.dart';
import 'package:home_care/admin/dashboard/widgets/user_detail_widgets.dart';

class UserDetailDialog extends StatelessWidget {
  final int userId;

  const UserDetailDialog({
    super.key,
    required this.userId,
  });

  static Future<void> show(BuildContext context, int userId) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => UserDetailDialog(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: FutureBuilder<AdminUserDetail>(
        future: AdminDashboardService.fetchUserDetail(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(30),
              child: SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.redAccent, size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    'Gagal memuat detail user',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final profile = data.profile;

          return ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 560,
              maxHeight: 700,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            UserMiniChip(
                              label: data.roleName ?? 'No Role',
                              bg: const Color(0xFFEFF6FF),
                              fg: const Color(0xFF2563EB),
                            ),
                            UserMiniChip(
                              label:
                                  data.isActive ? 'Aktif' : 'Tidak Aktif',
                              bg: data.isActive
                                  ? const Color(0xFFE8FFF1)
                                  : const Color(0xFFF3F4F6),
                              fg: data.isActive
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF6B7280),
                            ),
                            UserMiniChip(
                              label: data.isFrozen ? 'Frozen' : 'Normal',
                              bg: data.isFrozen
                                  ? const Color(0xFFFFEAEA)
                                  : const Color(0xFFEFF6FF),
                              fg: data.isFrozen
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF2563EB),
                            ),
                            UserMiniChip(
                              label: data.isVerified
                                  ? 'Verified'
                                  : 'Belum Verify',
                              bg: data.isVerified
                                  ? const Color(0xFFEEFDF3)
                                  : const Color(0xFFFFF7ED),
                              fg: data.isVerified
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFEA580C),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const UserSectionTitle('Informasi Akun'),
                        UserDetailRow('ID', data.id),
                        UserDetailRow('Nama', data.name),
                        UserDetailRow('Email', data.email),
                        UserDetailRow('Role', data.roleName),
                        UserDetailRow(
                          'Email Verified At',
                          AdminRoleStyle.formatDate(data.emailVerifiedAt),
                        ),
                        UserDetailRow(
                          'Last Login',
                          AdminRoleStyle.formatDate(data.lastLoginAt),
                        ),
                        UserDetailRow('Last Login IP', data.lastLoginIp),
                        UserDetailRow(
                          'Failed Login Count',
                          data.failedLoginCount,
                        ),
                        UserDetailRow(
                          'Locked Until',
                          AdminRoleStyle.formatDate(data.lockedUntil),
                        ),
                        UserDetailRow('Frozen Reason', data.frozenReason),
                        UserDetailRow(
                          'Frozen At',
                          AdminRoleStyle.formatDate(data.frozenAt),
                        ),
                        UserDetailRow('Frozen By', data.frozenBy),
                        UserDetailRow(
                          'Tanggal Daftar',
                          AdminRoleStyle.formatDate(data.createdAt),
                        ),
                        const SizedBox(height: 18),
                        const UserSectionTitle('Profil Lengkap'),
                        if (profile == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Profil spesifik belum tersedia.',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          )
                        else ...[
                          UserDetailRow('Tipe Profil', profile['type']),
                          ..._buildProfileSections(profile),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static List<Widget> _buildProfileSections(Map<String, dynamic> profile) {
    const onlyDateFields = {'tanggal_lahir', 'verified_at'};
    const dateTimeFields = {
      'last_login_at',
      'created_at',
      'updated_at',
      'deleted_at',
    };

    const personalKeys = {
      'id',
      'nama_lengkap',
      'nik',
      'no_rekam_medis',
      'kode_perawat',
      'kode_koordinator',
      'foto_profil',
      'foto',
      'jenis_kelamin',
      'tanggal_lahir',
      'tempat_lahir',
      'golongan_darah',
      'no_hp',
      'email',
      'email_kontak',
      'profesi',
      'keahlian',
      'tahun_pengalaman',
      'tempat_kerja_terakhir',
      'jabatan',
      'wilayah',
      'online_status',
      'total_tugas',
      'tugas_berjalan',
      'koordinator_id',
    };

    const addressKeys = {
      'alamat',
      'kelurahan',
      'kecamatan',
      'kota',
      'provinsi',
      'kode_pos',
      'provinsi_id',
      'kota_id',
      'kecamatan_id',
      'kelurahan_id',
    };

    const emergencyKeys = {
      'kontak_darurat_nama',
      'kontak_darurat_nohp',
      'kontak_darurat_no_hp',
      'kontak_darurat_hubungan',
    };

    const verificationKeys = {
      'status_verifikasi',
      'verified_at',
      'verified_by',
      'catatan_verifikasi',
      'is_verified',
      'firebase_uid',
      'foto_ktp',
      'dokumen_kontrak',
      'ijazah',
      'str_file',
      'sip_file',
      'no_str',
      'no_sip',
      'sertifikat_btcls',
      'sertifikat_ppra',
      'sertifikat_lainnya',
    };

    const medicalKeys = {'alergi', 'penyakit_menahun', 'catatan'};

    List<Widget> buildSection(String title, Set<String> keys) {
      final section = <Widget>[];
      bool hasAny = false;

      for (final key in keys) {
        if (!profile.containsKey(key)) continue;

        dynamic value = profile[key];
        if (onlyDateFields.contains(key)) {
          value = AdminRoleStyle.formatDate(value, onlyDate: true);
        } else if (dateTimeFields.contains(key)) {
          value = AdminRoleStyle.formatDate(value);
        }

        hasAny = true;
        section.add(UserDetailRow(AdminRoleStyle.humanizeKey(key), value));
      }

      if (!hasAny) return [];
      return [const SizedBox(height: 12), UserSectionTitle(title), ...section];
    }

    final widgets = <Widget>[];
    widgets.addAll(buildSection('Data Pribadi', personalKeys));
    widgets.addAll(buildSection('Alamat', addressKeys));
    widgets.addAll(buildSection('Kontak Darurat', emergencyKeys));
    widgets.addAll(buildSection('Verifikasi & Dokumen', verificationKeys));
    widgets.addAll(buildSection('Informasi Tambahan', medicalKeys));
    return widgets;
  }
}

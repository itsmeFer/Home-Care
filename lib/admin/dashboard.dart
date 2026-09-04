import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_care/admin/crud_kategori.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:home_care/admin/lihat_layanan_masuk.dart' as admin;

import 'package:home_care/admin/crud_role.dart';
import 'package:home_care/admin/crud_addons.dart';
import 'package:home_care/admin/crud_banner.dart';
import 'package:home_care/admin/crud_perawat.dart';
import 'package:home_care/admin/kelola_fee.dart';
import 'package:home_care/admin/kelola_kordinator.dart';
import 'package:home_care/admin/kelola_layanan.dart';
import 'package:home_care/admin/lapor_it.dart';
import 'package:home_care/admin/lihat_catatan_fee.dart';
import 'package:home_care/admin/lihat_perawat.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/screen/login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static String get baseUrl => ApiConstants.apiBase;

  bool _isLoadingStats = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _roleStats = [];

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Logout'),
            content: const Text('Yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _fetchStatistics() async {
    try {
      if (mounted) {
        setState(() => _isLoadingStats = true);
      }

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        _showSnackBar('Token login tidak ditemukan, silakan login ulang.');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/fee/users-list/statistics'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        setState(() {
          _roleStats = (data['data']?['by_role'] as List?) ?? [];
          _summary = (data['data']?['summary'] as Map<String, dynamic>?) ?? {};
        });
      } else {
        _showSnackBar(data['message']?.toString() ?? 'Gagal memuat statistik');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan saat mengambil statistik: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<List<dynamic>> _fetchUsersByRole(String roleSlug) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan');
    }

    final uri = Uri.parse('$baseUrl/admin/fee/users-list').replace(
      queryParameters: {
        'role_slug': roleSlug,
        'per_page': '100',
        'sort_by': 'created_at',
        'sort_order': 'desc',
      },
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final dynamic data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data']?['data'] as List?) ?? [];
    }

    throw Exception(data['message']?.toString() ?? 'Gagal memuat daftar user');
  }

  Future<Map<String, dynamic>> _fetchUserDetail(int userId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/admin/fee/users-list/$userId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final dynamic data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    }

    throw Exception(data['message']?.toString() ?? 'Gagal memuat detail user');
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  IconData _roleIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'pasien':
        return Icons.personal_injury_rounded;
      case 'perawat':
        return Icons.local_hospital_rounded;
      case 'koordinator':
        return Icons.person_pin_circle_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.group_rounded;
    }
  }

  Color _roleColor(String slug) {
    switch (slug.toLowerCase()) {
      case 'pasien':
        return const Color(0xFF3B82F6);
      case 'perawat':
        return const Color(0xFF10B981);
      case 'koordinator':
        return const Color(0xFFF59E0B);
      case 'admin':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(dynamic raw, {bool onlyDate = false}) {
    if (raw == null) return '-';

    final value = raw.toString().trim();
    if (value.isEmpty || value == 'null') return '-';

    try {
      final dt = DateTime.parse(value).toLocal();

      if (onlyDate) {
        return DateFormat('dd/MM/yyyy').format(dt);
      }

      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return value;
    }
  }

  String _humanizeKey(String key) {
    const customLabels = {
      'id': 'ID',
      'nik': 'NIK',
      'no_hp': 'No HP',
      'email': 'Email',
      'foto': 'Foto',
      'foto_profil': 'Foto Profil',
      'foto_ktp': 'Foto KTP',
      'firebase_uid': 'Firebase UID',
      'no_rekam_medis': 'No Rekam Medis',
      'kode_perawat': 'Kode Perawat',
      'kode_koordinator': 'Kode Koordinator',
      'jenis_kelamin': 'Jenis Kelamin',
      'tanggal_lahir': 'Tanggal Lahir',
      'tempat_lahir': 'Tempat Lahir',
      'golongan_darah': 'Golongan Darah',
      'kode_pos': 'Kode Pos',
      'provinsi_id': 'Provinsi ID',
      'kota_id': 'Kota ID',
      'kecamatan_id': 'Kecamatan ID',
      'kelurahan_id': 'Kelurahan ID',
      'kontak_darurat_nama': 'Kontak Darurat Nama',
      'kontak_darurat_nohp': 'Kontak Darurat No HP',
      'kontak_darurat_no_hp': 'Kontak Darurat No HP',
      'kontak_darurat_hubungan': 'Kontak Darurat Hubungan',
      'penyakit_menahun': 'Penyakit Menahun',
      'is_verified': 'Is Verified',
      'verified_at': 'Verified At',
      'verified_by': 'Verified By',
      'status_verifikasi': 'Status Verifikasi',
      'last_login_at': 'Last Login',
      'last_login_ip': 'Last Login IP',
      'failed_login_count': 'Failed Login Count',
      'locked_until': 'Locked Until',
      'frozen_reason': 'Frozen Reason',
      'frozen_at': 'Frozen At',
      'frozen_by': 'Frozen By',
      'catatan_verifikasi': 'Catatan Verifikasi',
      'tahun_pengalaman': 'Tahun Pengalaman',
      'tempat_kerja_terakhir': 'Tempat Kerja Terakhir',
      'dokumen_kontrak': 'Dokumen Kontrak',
      'str_file': 'File STR',
      'sip_file': 'File SIP',
      'no_str': 'No STR',
      'no_sip': 'No SIP',
      'sertifikat_btcls': 'Sertifikat BTCLS',
      'sertifikat_ppra': 'Sertifikat PPRA',
      'sertifikat_lainnya': 'Sertifikat Lainnya',
      'online_status': 'Online Status',
      'total_tugas': 'Total Tugas',
      'tugas_berjalan': 'Tugas Berjalan',
      'koordinator_id': 'Koordinator ID',
    };

    if (customLabels.containsKey(key)) {
      return customLabels[key]!;
    }

    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((e) {
          if (e.isEmpty) return e;
          return e[0].toUpperCase() + e.substring(1);
        })
        .join(' ');
  }

  List<Widget> _profileRows(Map<String, dynamic> profile) {
    final widgets = <Widget>[];

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
          value = _formatDate(value, onlyDate: true);
        } else if (dateTimeFields.contains(key)) {
          value = _formatDate(value);
        }

        hasAny = true;
        section.add(_detailRow(_humanizeKey(key), value));
      }

      if (!hasAny) return [];

      return [const SizedBox(height: 12), _SectionTitle(title), ...section];
    }

    widgets.addAll(buildSection('Data Pribadi', personalKeys));
    widgets.addAll(buildSection('Alamat', addressKeys));
    widgets.addAll(buildSection('Kontak Darurat', emergencyKeys));
    widgets.addAll(buildSection('Verifikasi & Dokumen', verificationKeys));
    widgets.addAll(buildSection('Informasi Tambahan', medicalKeys));

    return widgets;
  }

  Future<void> _openRoleUsers({
    required String roleSlug,
    required String roleName,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F8FB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.80,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return FutureBuilder<List<dynamic>>(
              future: _fetchUsersByRole(roleSlug),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Gagal memuat daftar $roleName\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Daftar $roleName (${users.length})',
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
                      child:
                          users.isEmpty
                              ? const Center(
                                child: Text(
                                  'Belum ada data user untuk role ini.',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                              )
                              : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  final role =
                                      (user['role']?['name'] ?? '-').toString();
                                  final isActive = user['is_active'] == true;
                                  final isFrozen = user['is_frozen'] == true;
                                  final isVerified =
                                      user['is_verified'] == true;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await _openUserDetail(
                                            (user['id'] as num).toInt(),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE9EEF5),
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x0A000000),
                                                blurRadius: 10,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor: const Color(
                                                  0xFF2E7DFF,
                                                ).withOpacity(0.12),
                                                child: Text(
                                                  ((user['name'] ?? 'U')
                                                          .toString()
                                                          .trim()
                                                          .isNotEmpty)
                                                      ? (user['name'] ?? 'U')
                                                          .toString()
                                                          .trim()[0]
                                                          .toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2E7DFF),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      (user['name'] ?? '-')
                                                          .toString(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 15.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Color(
                                                          0xFF111827,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      (user['email'] ?? '-')
                                                          .toString(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        color: Color(
                                                          0xFF6B7280,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      role,
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF374151,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Wrap(
                                                      spacing: 6,
                                                      runSpacing: 6,
                                                      children: [
                                                        _MiniChip(
                                                          label:
                                                              isActive
                                                                  ? 'Aktif'
                                                                  : 'Tidak Aktif',
                                                          bg:
                                                              isActive
                                                                  ? const Color(
                                                                    0xFFE8FFF1,
                                                                  )
                                                                  : const Color(
                                                                    0xFFF3F4F6,
                                                                  ),
                                                          fg:
                                                              isActive
                                                                  ? const Color(
                                                                    0xFF15803D,
                                                                  )
                                                                  : const Color(
                                                                    0xFF6B7280,
                                                                  ),
                                                        ),
                                                        _MiniChip(
                                                          label:
                                                              isFrozen
                                                                  ? 'Frozen'
                                                                  : 'Normal',
                                                          bg:
                                                              isFrozen
                                                                  ? const Color(
                                                                    0xFFFFEAEA,
                                                                  )
                                                                  : const Color(
                                                                    0xFFEFF6FF,
                                                                  ),
                                                          fg:
                                                              isFrozen
                                                                  ? const Color(
                                                                    0xFFDC2626,
                                                                  )
                                                                  : const Color(
                                                                    0xFF2563EB,
                                                                  ),
                                                        ),
                                                        _MiniChip(
                                                          label:
                                                              isVerified
                                                                  ? 'Verified'
                                                                  : 'Belum Verify',
                                                          bg:
                                                              isVerified
                                                                  ? const Color(
                                                                    0xFFEEFDF3,
                                                                  )
                                                                  : const Color(
                                                                    0xFFFFF7ED,
                                                                  ),
                                                          fg:
                                                              isVerified
                                                                  ? const Color(
                                                                    0xFF16A34A,
                                                                  )
                                                                  : const Color(
                                                                    0xFFEA580C,
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.chevron_right_rounded,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openUserDetail(int userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserDetail(userId),
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

              final data = snapshot.data ?? {};
              final role = data['role'] as Map<String, dynamic>?;
              final profile = data['profile'] as Map<String, dynamic>?;

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
                              (data['name'] ?? 'Detail User').toString(),
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
                                _MiniChip(
                                  label: role?['name']?.toString() ?? 'No Role',
                                  bg: const Color(0xFFEFF6FF),
                                  fg: const Color(0xFF2563EB),
                                ),
                                _MiniChip(
                                  label:
                                      data['is_active'] == true
                                          ? 'Aktif'
                                          : 'Tidak Aktif',
                                  bg:
                                      (data['is_active'] == true)
                                          ? const Color(0xFFE8FFF1)
                                          : const Color(0xFFF3F4F6),
                                  fg:
                                      (data['is_active'] == true)
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF6B7280),
                                ),
                                _MiniChip(
                                  label:
                                      data['is_frozen'] == true
                                          ? 'Frozen'
                                          : 'Normal',
                                  bg:
                                      (data['is_frozen'] == true)
                                          ? const Color(0xFFFFEAEA)
                                          : const Color(0xFFEFF6FF),
                                  fg:
                                      (data['is_frozen'] == true)
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF2563EB),
                                ),
                                _MiniChip(
                                  label:
                                      data['is_verified'] == true
                                          ? 'Verified'
                                          : 'Belum Verify',
                                  bg:
                                      (data['is_verified'] == true)
                                          ? const Color(0xFFEEFDF3)
                                          : const Color(0xFFFFF7ED),
                                  fg:
                                      (data['is_verified'] == true)
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFEA580C),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const _SectionTitle('Informasi Akun'),
                            _detailRow('ID', data['id']),
                            _detailRow('Nama', data['name']),
                            _detailRow('Email', data['email']),
                            _detailRow('Role', role?['name']),
                            _detailRow(
                              'Email Verified At',
                              _formatDate(data['email_verified_at']),
                            ),
                            _detailRow(
                              'Last Login',
                              _formatDate(data['last_login_at']),
                            ),
                            _detailRow('Last Login IP', data['last_login_ip']),
                            _detailRow(
                              'Failed Login Count',
                              data['failed_login_count'],
                            ),
                            _detailRow(
                              'Locked Until',
                              _formatDate(data['locked_until']),
                            ),
                            _detailRow('Frozen Reason', data['frozen_reason']),
                            _detailRow(
                              'Frozen At',
                              _formatDate(data['frozen_at']),
                            ),
                            _detailRow('Frozen By', data['frozen_by']),
                            _detailRow(
                              'Tanggal Daftar',
                              _formatDate(data['created_at']),
                            ),
                            const SizedBox(height: 18),
                            const _SectionTitle('Profil Lengkap'),
                            if (profile == null)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'Profil spesifik belum tersedia.',
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                              )
                            else ...[
                              _detailRow('Tipe Profil', profile['type']),
                              ..._profileRows(profile),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_DashboardMenu> menus = [
      _DashboardMenu(
        title: 'Kelola Layanan',
        icon: Icons.medical_services_rounded,
        page: const KelolaLayananPage(),
      ),
      _DashboardMenu(
        title: 'Kelola Kategori',
        icon: Icons.category_rounded,
        page: const CrudKategoriPage(),
      ),
      _DashboardMenu(
        title: 'Kelola Add-Ons',
        icon: Icons.add_box_rounded,
        page: const CrudAddOnsPage(),
      ),
      _DashboardMenu(
        title: 'Kelola Koordinator',
        icon: Icons.person_pin_circle_rounded,
        page: const CrudKordinatorPage(),
      ),
      _DashboardMenu(
        title: 'Lihat Semua Perawat',
        icon: Icons.people_alt_rounded,
        page: const LihatPerawatPage(),
      ),
      _DashboardMenu(
        title: 'Lihat Layanan Masuk',
        icon: Icons.inbox_rounded,
        page: const admin.LihatLayananMasukPage(),
      ),
      _DashboardMenu(
        title: 'Kelola Banner',
        icon: Icons.branding_watermark_rounded,
        page: const CrudBannerPage(),
      ),
      _DashboardMenu(
        title: 'Kelola Role',
        icon: Icons.admin_panel_settings_rounded,
        page: const CrudRolePage(),
      ),
      _DashboardMenu(
        title: 'Kelola Fee',
        icon: Icons.currency_exchange_rounded,
        page: const KelolaFeePage(),
      ),
      _DashboardMenu(
        title: 'Lapor IT',
        icon: Icons.report_problem_rounded,
        page: const LaporITPageAdmin(),
      ),
      _DashboardMenu(
        title: 'Lihat Catatan Fee',
        icon: Icons.receipt_long_rounded,
        page: const LihatCatatanFeePage(),
      ),
      _DashboardMenu(
        title: 'Kelola Perawat',
        icon: Icons.local_hospital_rounded,
        page: const CrudPerawatPage(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            _SimpleHeader(onLogout: () => _logout(context)),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchStatistics,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    _DashboardSummaryCard(
                      isLoading: _isLoadingStats,
                      summary: _summary,
                      onRefresh: _fetchStatistics,
                    ),
                    const SizedBox(height: 14),
                    _RoleStatsSection(
                      isLoading: _isLoadingStats,
                      roleStats: _roleStats,
                      roleIcon: _roleIcon,
                      roleColor: _roleColor,
                      onTapRole: (slug, name) {
                        _openRoleUsers(roleSlug: slug, roleName: name);
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Menu Admin',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2;
                        if (constraints.maxWidth >= 700) {
                          crossAxisCount = 3;
                        }

                        return GridView.builder(
                          itemCount: menus.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.08,
                              ),
                          itemBuilder: (context, index) {
                            final item = menus[index];
                            return _MenuCard(
                              title: item.title,
                              icon: item.icon,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => item.page),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  final VoidCallback onLogout;

  const _SimpleHeader({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HCColor.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: HCColor.primary.withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.dashboard_customize_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola semua menu admin dengan cepat',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSummaryCard extends StatelessWidget {
  final bool isLoading;
  final Map<String, dynamic> summary;
  final Future<void> Function() onRefresh;

  const _DashboardSummaryCard({
    required this.isLoading,
    required this.summary,
    required this.onRefresh,
  });

  Widget _buildItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF2E7DFF)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child:
          isLoading
              ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ringkasan Pendaftar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildItem(
                        'Total User',
                        '${summary['total_users'] ?? 0}',
                        Icons.groups_rounded,
                      ),
                      const SizedBox(width: 10),
                      _buildItem(
                        'Aktif',
                        '${summary['total_active'] ?? 0}',
                        Icons.check_circle_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildItem(
                        'Frozen',
                        '${summary['total_frozen'] ?? 0}',
                        Icons.ac_unit_rounded,
                      ),
                      const SizedBox(width: 10),
                      _buildItem(
                        'Verified',
                        '${summary['total_verified'] ?? 0}',
                        Icons.verified_rounded,
                      ),
                    ],
                  ),
                ],
              ),
    );
  }
}

class _RoleStatsSection extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> roleStats;
  final IconData Function(String slug) roleIcon;
  final Color Function(String slug) roleColor;
  final void Function(String slug, String name) onTapRole;

  const _RoleStatsSection({
    required this.isLoading,
    required this.roleStats,
    required this.roleIcon,
    required this.roleColor,
    required this.onTapRole,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Pengguna Berdasarkan Role',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 10),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (roleStats.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9EEF5)),
            ),
            child: const Text(
              'Belum ada data role.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          )
        else
          GridView.builder(
            itemCount: roleStats.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) {
              final item = roleStats[index];
              final slug = (item['role_slug'] ?? 'lainnya').toString();
              final roleName = (item['role_name'] ?? 'Tanpa Role').toString();
              final total = item['total']?.toString() ?? '0';
              final color = roleColor(slug);

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onTapRole(slug, roleName),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE9EEF5)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(roleIcon(slug), color: color, size: 23),
                        ),
                        const Spacer(),
                        Text(
                          total,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          roleName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap untuk lihat daftar',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE9EEF5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: HCColor.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: HCColor.primary, size: 23),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Buka menu',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMenu {
  final String title;
  final IconData icon;
  final Widget page;

  _DashboardMenu({required this.title, required this.icon, required this.page});
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _MiniChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

Widget _detailRow(String label, dynamic value) {
  final text =
      (value == null ||
              value.toString().trim().isEmpty ||
              value.toString() == 'null')
          ? '-'
          : value.toString();

  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.35,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text(':'),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

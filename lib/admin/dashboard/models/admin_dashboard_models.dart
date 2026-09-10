import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardSummary {
  final int totalUsers;
  final int totalActive;
  final int totalFrozen;
  final int totalVerified;

  const DashboardSummary({
    this.totalUsers = 0,
    this.totalActive = 0,
    this.totalFrozen = 0,
    this.totalVerified = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return DashboardSummary(
      totalUsers: toInt(json['total_users']),
      totalActive: toInt(json['total_active']),
      totalFrozen: toInt(json['total_frozen']),
      totalVerified: toInt(json['total_verified']),
    );
  }
}

class RoleStatItem {
  final String roleSlug;
  final String roleName;
  final String total;

  const RoleStatItem({
    required this.roleSlug,
    required this.roleName,
    required this.total,
  });

  factory RoleStatItem.fromJson(Map<String, dynamic> json) {
    return RoleStatItem(
      roleSlug: (json['role_slug'] ?? 'lainnya').toString(),
      roleName: (json['role_name'] ?? 'Tanpa Role').toString(),
      total: (json['total'] ?? '0').toString(),
    );
  }
}

class DashboardStatistics {
  final DashboardSummary summary;
  final List<RoleStatItem> roleStats;

  const DashboardStatistics({
    required this.summary,
    required this.roleStats,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['summary'] as Map<String, dynamic>? ?? {};
    final rawRoleStats = (json['by_role'] as List<dynamic>?) ?? [];

    return DashboardStatistics(
      summary: DashboardSummary.fromJson(rawSummary),
      roleStats: rawRoleStats
          .whereType<Map<String, dynamic>>()
          .map((e) => RoleStatItem.fromJson(e))
          .toList(),
    );
  }
}

class AdminUserItem {
  final int id;
  final String name;
  final String email;
  final String roleName;
  final bool isActive;
  final bool isFrozen;
  final bool isVerified;
  final String? createdAt;

  const AdminUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.roleName,
    required this.isActive,
    required this.isFrozen,
    required this.isVerified,
    this.createdAt,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    return AdminUserItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '-').toString(),
      email: (json['email'] ?? '-').toString(),
      roleName: (json['role']?['name'] ?? '-').toString(),
      isActive: json['is_active'] == true,
      isFrozen: json['is_frozen'] == true,
      isVerified: json['is_verified'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class AdminUserDetail {
  final int id;
  final String name;
  final String email;
  final String? roleName;
  final bool isActive;
  final bool isFrozen;
  final bool isVerified;
  final String? emailVerifiedAt;
  final String? lastLoginAt;
  final String? lastLoginIp;
  final int? failedLoginCount;
  final String? lockedUntil;
  final String? frozenReason;
  final String? frozenAt;
  final String? frozenBy;
  final String? createdAt;
  final Map<String, dynamic>? profile;

  const AdminUserDetail({
    required this.id,
    required this.name,
    required this.email,
    this.roleName,
    required this.isActive,
    required this.isFrozen,
    required this.isVerified,
    this.emailVerifiedAt,
    this.lastLoginAt,
    this.lastLoginIp,
    this.failedLoginCount,
    this.lockedUntil,
    this.frozenReason,
    this.frozenAt,
    this.frozenBy,
    this.createdAt,
    this.profile,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>?;
    final profile = json['profile'] as Map<String, dynamic>?;

    return AdminUserDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? 'Detail User').toString(),
      email: (json['email'] ?? '-').toString(),
      roleName: role?['name']?.toString(),
      isActive: json['is_active'] == true,
      isFrozen: json['is_frozen'] == true,
      isVerified: json['is_verified'] == true,
      emailVerifiedAt: json['email_verified_at']?.toString(),
      lastLoginAt: json['last_login_at']?.toString(),
      lastLoginIp: json['last_login_ip']?.toString(),
      failedLoginCount: (json['failed_login_count'] as num?)?.toInt(),
      lockedUntil: json['locked_until']?.toString(),
      frozenReason: json['frozen_reason']?.toString(),
      frozenAt: json['frozen_at']?.toString(),
      frozenBy: json['frozen_by']?.toString(),
      createdAt: json['created_at']?.toString(),
      profile: profile,
    );
  }
}

class DashboardMenu {
  final String title;
  final IconData icon;
  final Widget page;

  const DashboardMenu({
    required this.title,
    required this.icon,
    required this.page,
  });
}

class AdminRoleStyle {
  AdminRoleStyle._();

  static IconData icon(String slug) {
    switch (slug.toLowerCase()) {
      case 'pasien':
        return Icons.personal_injury_rounded;
      case 'perawat':
        return Icons.local_hospital_rounded;
      case 'koordinator':
        return Icons.person_pin_circle_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'direktur':
        return Icons.corporate_fare_rounded;
      case 'manager':
        return Icons.manage_accounts_rounded;
      case 'it':
        return Icons.terminal_rounded;
      case 'dokter':
        return Icons.medical_services_rounded;
      case 'bidan':
        return Icons.child_friendly_rounded;
      default:
        return Icons.group_rounded;
    }
  }

  static Color color(String slug) {
    switch (slug.toLowerCase()) {
      case 'pasien':
        return const Color(0xFF2563EB); // Royal Blue
      case 'perawat':
        return const Color(0xFF059669); // Emerald Green
      case 'koordinator':
        return const Color(0xFFD97706); // Warm Amber
      case 'admin':
        return const Color(0xFF7C3AED); // Purple
      case 'direktur':
        return const Color(0xFF4F46E5); // Indigo
      case 'manager':
        return const Color(0xFF0284C7); // Sky Blue
      case 'it':
        return const Color(0xFF0D9488); // Cyan Teal
      case 'dokter':
        return const Color(0xFFE11D48); // Rose
      case 'bidan':
        return const Color(0xFFDB2777); // Pink
      default:
        return const Color(0xFF64748B);
    }
  }

  static String formatDate(dynamic raw, {bool onlyDate = false}) {
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

  static String humanizeKey(String key) {
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
}

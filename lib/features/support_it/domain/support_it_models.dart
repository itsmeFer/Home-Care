import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class TicketCategoryItem {
  final String value;
  final String label;
  final IconData icon;
  final String desc;

  const TicketCategoryItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.desc,
  });

  static const List<TicketCategoryItem> defaultCategories = [
    TicketCategoryItem(
      value: 'bug',
      label: 'Bug/Error',
      icon: Icons.bug_report_outlined,
      desc: 'Kesalahan sistem',
    ),
    TicketCategoryItem(
      value: 'error',
      label: 'Error System',
      icon: Icons.error_outline,
      desc: 'Masalah teknis',
    ),
    TicketCategoryItem(
      value: 'performance',
      label: 'Performance',
      icon: Icons.speed_outlined,
      desc: 'Lambat/hang',
    ),
    TicketCategoryItem(
      value: 'access',
      label: 'Akses',
      icon: Icons.lock_outline,
      desc: 'Permission/login',
    ),
    TicketCategoryItem(
      value: 'other',
      label: 'Lainnya',
      icon: Icons.help_outline,
      desc: 'Masalah lain',
    ),
  ];
}

class TicketPriorityItem {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final String desc;

  const TicketPriorityItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.desc,
  });

  static const List<TicketPriorityItem> defaultPriorities = [
    TicketPriorityItem(
      value: 'low',
      label: 'Rendah',
      color: Color(0xFF10B981),
      icon: Icons.arrow_downward_rounded,
      desc: 'Tidak mendesak',
    ),
    TicketPriorityItem(
      value: 'medium',
      label: 'Sedang',
      color: Color(0xFFF59E0B),
      icon: Icons.remove_rounded,
      desc: 'Cukup penting',
    ),
    TicketPriorityItem(
      value: 'high',
      label: 'Tinggi',
      color: Color(0xFFEF4444),
      icon: Icons.arrow_upward_rounded,
      desc: 'Sangat mendesak',
    ),
  ];
}

class SupportTicket {
  final int id;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String? platform;
  final String? createdAt;
  final String? solvedAt;
  final String? itNotes;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.platform,
    this.createdAt,
    this.solvedAt,
    this.itNotes,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id:
          json['id'] is int
              ? json['id'] as int
              : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      subject: json['subject']?.toString() ?? 'Tanpa Judul',
      description: json['description']?.toString() ?? '-',
      category: json['category']?.toString() ?? 'bug',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'open',
      platform: json['platform']?.toString(),
      createdAt: json['created_at']?.toString(),
      solvedAt: json['solved_at']?.toString(),
      itNotes: json['it_notes']?.toString(),
    );
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.warning;
      case 'in_progress':
        return const Color(0xFF0EA5E9);
      case 'solved':
      case 'resolved':
        return AppColors.success;
      case 'closed':
      default:
        return AppColors.textSecondary;
    }
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Terbuka';
      case 'in_progress':
        return 'Diproses';
      case 'solved':
      case 'resolved':
        return 'Selesai';
      case 'closed':
        return 'Ditutup';
      default:
        return status;
    }
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  String get priorityLabel {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Rendah';
      case 'medium':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      default:
        return priority;
    }
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'bug':
        return Icons.bug_report_outlined;
      case 'error':
        return Icons.error_outline;
      case 'performance':
        return Icons.speed_outlined;
      case 'access':
        return Icons.lock_outline;
      default:
        return Icons.help_outline;
    }
  }
}

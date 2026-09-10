import 'dart:convert';
import 'package:flutter/material.dart';

class ChatRoom {
  final int id;
  final String title;
  final String lastMessage;
  final DateTime? lastTime;
  final String? koordinatorName;
  final String? perawatName;
  final String? pasienName;
  final String? layananName;
  final String? status;
  final bool isPerawatChat;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastTime,
    this.koordinatorName,
    this.perawatName,
    this.pasienName,
    this.layananName,
    this.status,
    required this.isPerawatChat,
    required this.unreadCount,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: (json['title'] ?? '').toString(),
      lastMessage: (json['last_message'] ?? '').toString(),
      lastTime: json['last_time'] != null
          ? DateTime.tryParse(json['last_time'].toString())?.toLocal()
          : null,
      koordinatorName: json['koordinator_name']?.toString(),
      perawatName: json['perawat_name']?.toString(),
      pasienName: json['pasien_name']?.toString(),
      layananName: (json['layanan_name'] ?? json['layanan']?['nama_layanan'])
          ?.toString(),
      status: json['status']?.toString(),
      isPerawatChat: json['is_perawat_chat'] == true,
      unreadCount: (json['unread_count'] ?? 0) is int
          ? (json['unread_count'] ?? 0) as int
          : int.tryParse(json['unread_count'].toString()) ?? 0,
    );
  }

  String displayTitle(String currentRole) {
    if (currentRole == 'perawat') {
      if (pasienName != null && pasienName!.trim().isNotEmpty) {
        return pasienName!;
      }
      if (title.trim().isNotEmpty) return title;
      if (layananName != null && layananName!.trim().isNotEmpty) {
        return layananName!;
      }
      return 'Chat Pasien';
    } else if (currentRole == 'koordinator') {
      if (pasienName != null && pasienName!.trim().isNotEmpty) {
        return pasienName!;
      }
      if (title.trim().isNotEmpty) return title;
      return 'Chat Pasien';
    } else {
      if (isPerawatChat) {
        return perawatName != null && perawatName!.trim().isNotEmpty
            ? 'Perawat $perawatName'
            : 'Chat Perawat';
      }
      return koordinatorName != null && koordinatorName!.trim().isNotEmpty
          ? koordinatorName!
          : (title.trim().isNotEmpty ? title : 'Chat Layanan');
    }
  }

  Color get statusColor {
    switch (status?.toLowerCase()) {
      case 'tawar':
        return const Color(0xFFD97706);
      case 'deal':
        return const Color(0xFF16A34A);
      case 'closed':
      case 'selesai':
        return const Color(0xFF64748B);
      case 'orderan_berjalan':
        return const Color(0xFF2563EB);
      case 'dibatalkan':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF475569);
    }
  }

  String get statusLabel {
    switch (status?.toLowerCase()) {
      case 'tawar':
        return 'Sedang tawar';
      case 'deal':
        return 'Sudah deal';
      case 'closed':
      case 'selesai':
        return 'Selesai';
      case 'orderan_berjalan':
        return 'Order berjalan';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return (status != null && status!.trim().isNotEmpty)
            ? status!
            : 'Chat aktif';
    }
  }
}

class ChatMessage {
  final int id;
  final int userId;
  final String role;
  final String text;
  final String type;
  final String? filePath;
  final String? fileUrl;
  final bool isMine;
  final DateTime? createdAt;

  final bool isEtalase;
  final Map<String, dynamic>? etalaseData;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.role,
    required this.text,
    required this.type,
    required this.filePath,
    required this.fileUrl,
    required this.isMine,
    this.createdAt,
    this.isEtalase = false,
    this.etalaseData,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required int currentUserId,
  }) {
    final int parsedUserId = (json['user_id'] is int)
        ? json['user_id'] as int
        : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0;

    final String rawMessage = (json['message'] ?? '').toString();

    bool isEtalase = false;
    Map<String, dynamic>? etalase;

    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is Map<String, dynamic> && decoded['etalase'] == true) {
        isEtalase = true;
        etalase = decoded;
      }
    } catch (_) {}

    return ChatMessage(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: parsedUserId,
      role: (json['role'] ?? '').toString(),
      text: rawMessage,
      type: (json['type'] ?? 'text').toString(),
      filePath: json['file_path']?.toString(),
      fileUrl: json['file_url']?.toString(),
      isMine: parsedUserId == currentUserId,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal()
          : null,
      isEtalase: isEtalase,
      etalaseData: etalase,
    );
  }
}

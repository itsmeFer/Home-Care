// lib/chat/chat_models.dart
import 'dart:convert';

class ChatRoom {
  final int id;
  final String title;
  final String lastMessage;
  final String? pasienName;       // utk koordinator: nama pasien
  final String? koordinatorName;  // utk pasien: nama koordinator
  final DateTime? lastTime;       // waktu pesan terakhir (local)

  ChatRoom({
    required this.id,
    required this.title,
    required this.lastMessage,
    this.pasienName,
    this.koordinatorName,
    this.lastTime,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      lastMessage: (json['last_message'] ?? '') as String,
      pasienName: json['pasien_name'] as String?,          // bisa null
      koordinatorName: json['koordinator_name'] as String?,// bisa null
      lastTime: json['last_time'] != null
          ? DateTime.parse(json['last_time'] as String).toLocal()
          : null,
    );
  }
}

class ChatMessage {
  final int id;
  final int userId;
  final String role;
  final String text;
  final bool isMine;
  final DateTime? createdAt; // waktu pesan dibuat (local)

  // 🆕 untuk etalase
  final bool isEtalase;
  final Map<String, dynamic>? etalaseData;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.role,
    required this.text,
    required this.isMine,
    this.createdAt,
    this.isEtalase = false,
    this.etalaseData,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    required int currentUserId,
  }) {
    final userId = json['user_id'] as int;

    bool isEtalase = false;
    Map<String, dynamic>? etalase;

    final rawMessage = json['message'] as String? ?? '';

    // 🔍 coba decode JSON untuk cek etalase
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is Map && decoded['etalase'] == true) {
        isEtalase = true;
        etalase = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // kalau gagal decode -> bukan etalase, biarkan sebagai chat biasa
    }

    return ChatMessage(
      id: json['id'] as int,
      userId: userId,
      role: json['role'] as String? ?? '',
      text: rawMessage,
      isMine: userId == currentUserId,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      isEtalase: isEtalase,
      etalaseData: etalase,
    );
  }
}

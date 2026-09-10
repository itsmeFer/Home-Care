import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

class EtalaseData {
  final int id;
  final String namaLayanan;
  final int harga;
  final String? deskripsi;
  final String? gambar;
  final String? kategori;
  final int? durasiMenit;
  final String? syaratPerawat;
  final String? lokasiTersedia;

  const EtalaseData({
    required this.id,
    required this.namaLayanan,
    required this.harga,
    this.deskripsi,
    this.gambar,
    this.kategori,
    this.durasiMenit,
    this.syaratPerawat,
    this.lokasiTersedia,
  });

  factory EtalaseData.fromJson(Map<String, dynamic> json) {
    final rawId = json['layanan_id'] ?? json['id'] ?? 0;
    final int id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    final rawHarga = json['harga'] ?? json['tarif'] ?? 0;
    final int harga =
        rawHarga is int ? rawHarga : int.tryParse(rawHarga.toString()) ?? 0;
    final rawDurasi = json['durasi_menit'];
    final int? durasi =
        rawDurasi is int ? rawDurasi : int.tryParse(rawDurasi?.toString() ?? '');

    return EtalaseData(
      id: id,
      namaLayanan:
          (json['nama'] ?? json['nama_layanan'] ?? json['title'] ?? 'Layanan')
              .toString(),
      harga: harga,
      deskripsi: json['deskripsi']?.toString(),
      gambar: json['gambar']?.toString() ?? json['image_url']?.toString(),
      kategori: json['kategori']?.toString(),
      durasiMenit: durasi,
      syaratPerawat: json['syarat_perawat']?.toString(),
      lokasiTersedia: json['lokasi_tersedia']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etalase': true,
      'layanan_id': id,
      'nama_layanan': namaLayanan,
      'harga': harga,
      'deskripsi': deskripsi,
      'gambar': gambar,
      'kategori': kategori,
      'durasi_menit': durasiMenit,
      'syarat_perawat': syaratPerawat,
      'lokasi_tersedia': lokasiTersedia,
    };
  }
}

class ChatDealHelper {
  ChatDealHelper._();

  static bool isTawarHarga(String text) =>
      text.trim().startsWith('[PENAWARAN HARGA]');

  static bool isDealHarga(String text) => text.trim().startsWith('[DEAL HARGA]');

  static String? extractNominal(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('nominal:') || lower.startsWith('disepakati:')) {
        final digits = line.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) return digits;
      }
    }
    return null;
  }

  static String formatTawarMessage({required String harga, String? catatan}) {
    final buffer = StringBuffer()
      ..writeln('[PENAWARAN HARGA]')
      ..writeln('Nominal: Rp $harga');
    if (catatan != null && catatan.trim().isNotEmpty) {
      buffer.writeln('Catatan: ${catatan.trim()}');
    }
    return buffer.toString();
  }

  static String formatDealMessage({
    required String nominal,
    required String role,
  }) {
    final buffer = StringBuffer()
      ..writeln('[DEAL HARGA]')
      ..writeln('Disepakati: Rp $nominal')
      ..writeln('Disepakati oleh: $role');
    return buffer.toString();
  }
}

class DealState {
  final bool hasDeal;
  final String? dealHargaDisplay;
  final int? dealHarga;
  final int? layananId;

  const DealState({
    required this.hasDeal,
    this.dealHargaDisplay,
    this.dealHarga,
    this.layananId,
  });

  static DealState compute({
    required List<ChatMessage> messages,
    required bool negoEnabled,
  }) {
    if (!negoEnabled) return const DealState(hasDeal: false);

    int? lastEtalaseIndex;
    int? lastDealIndex;
    String? dealNominal;

    for (int i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (m.isEtalase && m.etalaseData != null) lastEtalaseIndex = i;
      if (ChatDealHelper.isDealHarga(m.text)) {
        final nominal = ChatDealHelper.extractNominal(m.text);
        if (nominal != null) {
          dealNominal = nominal;
          lastDealIndex = i;
        }
      }
    }

    if (lastEtalaseIndex != null &&
        lastDealIndex != null &&
        lastDealIndex > lastEtalaseIndex) {
      final etalaseMsg = messages[lastEtalaseIndex];
      final e = etalaseMsg.etalaseData!;
      final rawId = e['layanan_id'] ?? e['id'];

      int? layananId;
      if (rawId is int) {
        layananId = rawId;
      } else if (rawId is String) {
        layananId = int.tryParse(rawId);
      }

      int? dealHarga;
      String? dealHargaDisplay;
      if (dealNominal != null) {
        dealHarga = int.tryParse(dealNominal);
        final formatted = NumberFormat.decimalPattern(
          'id_ID',
        ).format(dealHarga ?? 0);
        dealHargaDisplay = 'Rp $formatted';
      }

      return DealState(
        hasDeal: true,
        dealHargaDisplay: dealHargaDisplay,
        dealHarga: dealHarga,
        layananId: layananId,
      );
    }

    return const DealState(hasDeal: false);
  }
}



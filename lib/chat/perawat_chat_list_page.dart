// lib/chat/perawat_chat_list_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat.dart' show ChatRoomPage; // pastikan path ini benar

const String kBaseUrl = 'http://192.168.1.6:8000/api';

class PerawatChatListPage extends StatefulWidget {
  const PerawatChatListPage({Key? key}) : super(key: key);

  @override
  State<PerawatChatListPage> createState() => _PerawatChatListPageState();
}

class _PerawatChatListPageState extends State<PerawatChatListPage> {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  List<_PerawatChatRoomItem> _rooms = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Token tidak ditemukan. Silakan login sebagai perawat.';
      });
      return;
    }

    try {
      final uri = Uri.parse('$kBaseUrl/perawat/chat-rooms');
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) {
        String? msg;
        try {
          final body = json.decode(res.body);
          msg = body['message']?.toString();
        } catch (_) {}

        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage =
              'Gagal memuat daftar chat (${res.statusCode})${msg != null ? '\n$msg' : ''}';
        });
        return;
      }

      final decoded = json.decode(res.body);

      final List data;
      if (decoded is List) {
        data = decoded;
      } else {
        data = (decoded['data'] ?? []) as List;
      }

      final rooms = data
          .map((e) => _PerawatChatRoomItem.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _isLoading = false;
        _isError = false;
        _rooms = rooms;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd MMM HH:mm', 'id_ID').format(dt);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'tawar':
        return Colors.orange;
      case 'deal':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'tawar':
        return 'Sedang tawar';
      case 'deal':
        return 'Sudah deal';
      case 'closed':
        return 'Selesai';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Pasien (Perawat)'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRooms,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _errorMessage ?? 'Gagal memuat data.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: _fetchRooms,
              child: const Text('Coba Lagi'),
            ),
          ),
        ],
      );
    }

    if (_rooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'Belum ada chat dari pasien.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final item = _rooms[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomPage(
                    roomId: item.id,
                    roomTitle: item.title.isNotEmpty
                        ? item.title
                        : item.layananName.isNotEmpty
                            ? item.layananName
                            : 'Chat Pasien',
                    role: 'perawat', // 🔥 penting
                  ),
                ),
              );
            },
            title: Text(
              item.pasienName.isNotEmpty ? item.pasienName : 'Pasien',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.layananName.isNotEmpty)
                  Text(
                    item.layananName,
                    style: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(height: 2),
                Text(
                  item.lastMessage.isNotEmpty
                      ? item.lastMessage
                      : '(Belum ada pesan)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: _statusColor(item.status).withOpacity(0.1),
                      ),
                      child: Text(
                        _statusLabel(item.status),
                        style: TextStyle(
                          fontSize: 10,
                          color: _statusColor(item.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.lastTime != null)
                      Text(
                        _formatTime(item.lastTime),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

// ==============================
//  MODEL ROOM SEDERHANA
// ==============================
class _PerawatChatRoomItem {
  final int id;
  final String title;
  final String pasienName;
  final String layananName;
  final String status;
  final String lastMessage;
  final DateTime? lastTime;

  _PerawatChatRoomItem({
    required this.id,
    required this.title,
    required this.pasienName,
    required this.layananName,
    required this.status,
    required this.lastMessage,
    required this.lastTime,
  });

  factory _PerawatChatRoomItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTime;
    final rawTime = json['last_time'];

    if (rawTime != null) {
      try {
        parsedTime = DateTime.parse(rawTime.toString());
      } catch (_) {}
    }

    return _PerawatChatRoomItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      pasienName: json['pasien_name']?.toString() ?? '',
      layananName: json['layanan_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      lastMessage: json['last_message']?.toString() ?? '',
      lastTime: parsedTime,
    );
  }
}

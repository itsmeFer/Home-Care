// lib/chat/koordinator_chat_list_page.dart
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:home_care/chat.dart';
import 'package:home_care/chat/chat_models.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'http://192.168.1.6:8000/api';

class KoordinatorChatListPage extends StatefulWidget {
  const KoordinatorChatListPage({super.key});

  @override
  State<KoordinatorChatListPage> createState() =>
      _KoordinatorChatListPageState();
}

class _KoordinatorChatListPageState extends State<KoordinatorChatListPage> {
  bool _isLoading = true;
  String? _error;
  List<ChatRoom> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login berakhir, silakan login ulang.';
        });
        return;
      }

      final res = await http.get(
        Uri.parse('$kBaseUrl/koordinator/chat-rooms'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error =
              'Gagal memuat daftar chat (${res.statusCode} ${res.reasonPhrase})';
        });
        return;
      }

      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['success'] != true) {
        setState(() {
          _isLoading = false;
          _error = body['message']?.toString() ?? 'Gagal memuat chat.';
        });
        return;
      }

      final List data = body['data'] as List;
      final rooms = data
          .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat dengan Pasien')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _rooms.isEmpty
          ? const Center(child: Text('Belum ada chat.'))
          : ListView.separated(
              itemCount: _rooms.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final room = _rooms[index];
                // di ListTile:
               return ListTile(
  leading: const CircleAvatar(child: Icon(Icons.person)),
  // 🔥 judul = nama pasien
  title: Text(room.pasienName ?? room.title),
  subtitle: room.lastMessage.isNotEmpty
      ? Text(
          room.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )
      : const Text(
          'Belum ada pesan',
          style: TextStyle(fontSize: 12),
        ),
  // 🔥 waktu di trailing
  trailing: room.lastTime == null
      ? null
      : Text(
          DateFormat('dd MMM\nHH:mm').format(room.lastTime!),
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          roomId: room.id,
          roomTitle: room.pasienName ?? room.title,
          role: 'koordinator',
        ),
      ),
    );
  },
);

              },
            ),
    );
  }
}

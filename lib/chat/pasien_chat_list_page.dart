// lib/chat/pasien_chat_list_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/chat.dart'; // ChatRoomPage + kBaseUrl
import 'package:home_care/chat/chat_models.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasienChatListPage extends StatefulWidget {
  const PasienChatListPage({super.key});

  @override
  State<PasienChatListPage> createState() => _PasienChatListPageState();
}

class _PasienChatListPageState extends State<PasienChatListPage> {
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
        Uri.parse('$kBaseUrl/pasien/chat-rooms'),
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

  // ===========================
  // HAPUS ROOM (API DELETE)
  // ===========================
  Future<void> _deleteRoom(ChatRoom room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Chat'),
          content: Text(
            'Yakin ingin menghapus chat dengan '
            '${room.koordinatorName?.isNotEmpty == true ? room.koordinatorName! : (room.title.isEmpty ? 'koordinator ini' : room.title)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login berakhir, silakan login ulang.'),
          ),
        );
        return;
      }

      final res = await http.delete(
        Uri.parse('$kBaseUrl/pasien/chat-rooms/${room.id}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          _rooms.removeWhere((r) => r.id == room.id);
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Chat berhasil dihapus')));
      } else {
        String msg = 'Gagal menghapus chat (${res.statusCode})';
        try {
          final body = json.decode(res.body) as Map<String, dynamic>;
          if (body['message'] != null) {
            msg = body['message'].toString();
          }
        } catch (_) {}

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  // ===========================
  // BANGUN TILE ROOM
  // ===========================
 Widget _buildRoomTile(ChatRoom room) {
  final bool isPerawatChat = room.isPerawatChat;

  // judul room
  final title = isPerawatChat
      ? (room.perawatName?.isNotEmpty == true
          ? 'Chat dengan Perawat ${room.perawatName}'
          : 'Chat dengan Perawat')
      : (room.koordinatorName?.isNotEmpty == true
          ? room.koordinatorName!
          : (room.title.isEmpty ? 'Chat Layanan' : room.title));

  return ListTile(
    leading: CircleAvatar(
      child: Icon(isPerawatChat ? Icons.local_hospital : Icons.support_agent),
    ),
    title: Text(title),
    subtitle: room.lastMessage.isNotEmpty
        ? Text(
            room.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : const Text('Belum ada pesan', style: TextStyle(fontSize: 12)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (room.lastTime != null)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text(
              DateFormat('dd MMM\nHH:mm').format(room.lastTime!),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          tooltip: 'Hapus chat',
          onPressed: () => _deleteRoom(room),
        ),
      ],
    ),

    // ⬇ ini yang penting: simpleChat = true kalau room perawat
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            roomId: room.id,
            roomTitle: title,
            role: 'pasien',
            simpleChat: isPerawatChat, // 👈 chat ke perawat = simple
          ),
        ),
      );
    },

    onLongPress: () => _deleteRoom(room),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat dengan Koordinator')),
      body: RefreshIndicator(
        onRefresh: _loadRooms,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(_error!)),
                ],
              )
            : _rooms.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('Belum ada chat dengan koordinator.')),
                ],
              )
            : ListView.separated(
                itemCount: _rooms.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final room = _rooms[index];
                  return _buildRoomTile(room);
                },
              ),
      ),
    );
  }
}

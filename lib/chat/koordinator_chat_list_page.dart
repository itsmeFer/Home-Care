// lib/chat/koordinator_chat_list_page.dart
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:home_care/chat.dart';
import 'package:home_care/chat/chat_models.dart';
import 'package:home_care/chat/chat_unread_counter.dart'; // sesuaikan path
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'http://147.93.81.243/api';

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

      // total unread global
      final totalUnread = rooms.fold<int>(
        0,
        (sum, room) => sum + room.unreadCount,
      );
      ChatUnreadCounter.setTotal(totalUnread);

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

  Widget _buildUnreadBadge(int unreadCount) {
    if (unreadCount <= 0) return const SizedBox.shrink();

    final text = unreadCount > 99 ? '99+' : unreadCount.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRoomTile(ChatRoom room) {
    final isUnread = room.unreadCount > 0;
    final title = room.pasienName?.isNotEmpty == true
        ? room.pasienName!
        : (room.title.isNotEmpty ? room.title : 'Chat Pasien');

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          if (isUnread)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: room.lastMessage.isNotEmpty
          ? Text(
              room.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                color: isUnread ? Colors.black87 : Colors.grey[700],
              ),
            )
          : const Text(
              'Belum ada pesan',
              style: TextStyle(fontSize: 12),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (room.lastTime != null)
            Text(
              DateFormat('dd MMM HH:mm').format(room.lastTime!),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: isUnread ? Colors.blue : Colors.grey,
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          const SizedBox(height: 6),
          _buildUnreadBadge(room.unreadCount),
        ],
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomPage(
              roomId: room.id,
              roomTitle: title,
              role: 'koordinator',
            ),
          ),
        );

        _loadRooms();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat dengan Pasien')),
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
                          Center(child: Text('Belum ada chat.')),
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
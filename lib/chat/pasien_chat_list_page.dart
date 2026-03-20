import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/chat.dart';
import 'package:home_care/chat/chat_models.dart';
import 'package:home_care/chat/chat_unread_counter.dart';
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

  Future<void> _deleteRoom(ChatRoom room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final name =
            room.koordinatorName?.isNotEmpty == true
                ? room.koordinatorName!
                : (room.title.isEmpty ? 'kontak ini' : room.title);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Hapus Chat'),
          content: Text('Yakin ingin menghapus chat dengan $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
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

        final totalUnread = _rooms.fold<int>(
          0,
          (sum, item) => sum + item.unreadCount,
        );
        ChatUnreadCounter.setTotal(totalUnread);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat berhasil dihapus')),
        );
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

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('dd MMM • HH:mm').format(dateTime);
  }

  Widget _buildUnreadBadge(int unreadCount) {
    if (unreadCount <= 0) return const SizedBox.shrink();

    final text = unreadCount > 99 ? '99+' : unreadCount.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: const BoxConstraints(minWidth: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isPerawatChat, bool isUnread) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isPerawatChat
              ? [const Color(0xFF0EA5E9), const Color(0xFF2563EB)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Icon(
              isPerawatChat ? Icons.local_hospital_rounded : Icons.support_agent,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (isUnread)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(ChatRoom room, double horizontalPadding) {
    final bool isPerawatChat = room.isPerawatChat;

    final title = isPerawatChat
        ? (room.perawatName?.isNotEmpty == true
              ? 'Perawat ${room.perawatName}'
              : 'Chat Perawat')
        : (room.koordinatorName?.isNotEmpty == true
              ? room.koordinatorName!
              : (room.title.isEmpty ? 'Chat Layanan' : room.title));

    final isUnread = room.unreadCount > 0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 6,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomPage(
                  roomId: room.id,
                  roomTitle: title,
                  role: 'pasien',
                  simpleChat: isPerawatChat,
                ),
              ),
            );

            _loadRooms();
          },
          onLongPress: () => _deleteRoom(room),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUnread
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFF1F5F9),
              ),
              color: isUnread ? const Color(0xFFF8FBFF) : Colors.white,
            ),
            child: Row(
              children: [
                _buildAvatar(isPerawatChat, isUnread),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (room.lastTime != null)
                            Text(
                              _formatTime(room.lastTime),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isUnread
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF94A3B8),
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        room.lastMessage.isNotEmpty
                            ? room.lastMessage
                            : 'Belum ada pesan',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          height: 1.35,
                          fontSize: 13.5,
                          color: room.lastMessage.isNotEmpty
                              ? (isUnread
                                    ? const Color(0xFF334155)
                                    : const Color(0xFF64748B))
                              : const Color(0xFF94A3B8),
                          fontWeight: isUnread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUnreadBadge(room.unreadCount),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _deleteRoom(room),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateView({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xFF64748B),
              ),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final horizontalPadding = width >= 900
        ? width * 0.18
        : width >= 600
            ? 24.0
            : 12.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRooms,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.72,
                        child: _buildStateView(
                          icon: Icons.error_outline_rounded,
                          title: 'Gagal memuat chat',
                          subtitle: _error!,
                          buttonText: 'Coba lagi',
                          onPressed: _loadRooms,
                        ),
                      ),
                    ],
                  )
                : _rooms.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.72,
                            child: _buildStateView(
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'Belum ada chat',
                              subtitle:
                                  'Percakapan dengan koordinator atau perawat akan muncul di sini.',
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        itemCount: _rooms.length,
                        itemBuilder: (context, index) {
                          final room = _rooms[index];
                          return _buildRoomTile(room, horizontalPadding);
                        },
                      ),
      ),
    );
  }
}
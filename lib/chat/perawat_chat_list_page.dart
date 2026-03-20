// lib/chat/perawat_chat_list_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat.dart' show ChatRoomPage;

const String kBaseUrl = 'http://147.93.81.243/api';

class PerawatChatListPage extends StatefulWidget {
  const PerawatChatListPage({super.key});

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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage =
              'Token tidak ditemukan. Silakan login sebagai perawat.';
        });
        return;
      }

      debugPrint('FETCH PERAWAT CHAT START');

      final uri = Uri.parse('$kBaseUrl/perawat/chat-rooms');
      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('FETCH STATUS: ${res.statusCode}');
      debugPrint('FETCH BODY: ${res.body}');

      if (res.statusCode != 200) {
        String? msg;
        try {
          final body = json.decode(res.body);
          if (body is Map) {
            msg = body['message']?.toString();
          }
        } catch (_) {}

        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage =
              'Gagal memuat daftar chat (${res.statusCode})${msg != null ? '\n$msg' : ''}';
        });
        return;
      }

      final decoded = json.decode(res.body);

      List data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final raw = decoded['data'];
        if (raw is List) {
          data = raw;
        }
      }

      final rooms = data
          .whereType<Map>()
          .map(
            (e) => _PerawatChatRoomItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();

      debugPrint('ROOMS COUNT: ${rooms.length}');

      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _isLoading = false;
        _isError = false;
      });
    } catch (e, s) {
      debugPrint('FETCH ERROR: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    try {
      return DateFormat('dd MMM HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'tawar':
        return Colors.orange;
      case 'deal':
        return Colors.green;
      case 'closed':
      case 'selesai':
        return Colors.grey;
      case 'orderan_berjalan':
        return Colors.blue;
      case 'dibatalkan':
        return Colors.red;
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
      case 'selesai':
        return 'Selesai';
      case 'orderan_berjalan':
        return 'Order berjalan';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status.isEmpty ? 'Chat aktif' : status;
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

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'BUILD PERAWAT CHAT PAGE -> loading=$_isLoading, error=$_isError, rooms=${_rooms.length}',
    );

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
        physics: const AlwaysScrollableScrollPhysics(),
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
        final isUnread = item.unreadCount > 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              try {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomPage(
                      roomId: item.id,
                      roomTitle: item.title.isNotEmpty
                          ? item.title
                          : item.layananName.isNotEmpty
                              ? item.layananName
                              : 'Chat Pasien',
                      role: 'perawat',
                    ),
                  ),
                );

                _fetchRooms();
              } catch (e, s) {
                debugPrint('NAVIGATE CHAT ROOM ERROR: $e');
                debugPrintStack(stackTrace: s);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal membuka chat: $e')),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
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
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.pasienName.isNotEmpty ? item.pasienName : 'Pasien',
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                        if (item.layananName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.layananName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          item.lastMessage.isNotEmpty
                              ? item.lastMessage
                              : '(Belum ada pesan)',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isUnread ? FontWeight.w600 : FontWeight.normal,
                            color: isUnread ? Colors.black87 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: _statusColor(
                                  item.status,
                                ).withValues(alpha: 0.1),
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
                            if (item.lastTime != null)
                              Text(
                                _formatTime(item.lastTime),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isUnread ? Colors.blue : Colors.grey,
                                  fontWeight: isUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildUnreadBadge(item.unreadCount),
                      const SizedBox(height: 6),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PerawatChatRoomItem {
  final int id;
  final String title;
  final String pasienName;
  final String layananName;
  final String status;
  final String lastMessage;
  final DateTime? lastTime;
  final int unreadCount;

  _PerawatChatRoomItem({
    required this.id,
    required this.title,
    required this.pasienName,
    required this.layananName,
    required this.status,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
  });

  factory _PerawatChatRoomItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTime;
    final rawTime = json['last_time'];

    if (rawTime != null) {
      try {
        parsedTime = DateTime.tryParse(rawTime.toString());
      } catch (_) {}
    }

    return _PerawatChatRoomItem(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      pasienName: json['pasien_name']?.toString() ?? '',
      layananName: json['layanan_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      lastMessage: json['last_message']?.toString() ?? '',
      lastTime: parsedTime,
      unreadCount: json['unread_count'] is int
          ? json['unread_count'] as int
          : int.tryParse('${json['unread_count']}') ?? 0,
    );
  }
}
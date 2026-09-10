import 'package:flutter/material.dart';
import 'package:home_care/chat/chat_models.dart';
import 'package:home_care/chat/chat_unread_counter.dart';
import 'package:home_care/chat/services/chat_service.dart';
import 'package:home_care/chat/widgets/chat_room_tile.dart';
import 'package:home_care/chat/widgets/chat_state_views.dart';
import 'package:home_care/features/chat/presentation/screens/chat_room_page.dart';

class PerawatChatListPage extends StatefulWidget {
  const PerawatChatListPage({super.key});

  @override
  State<PerawatChatListPage> createState() => _PerawatChatListPageState();
}

class _PerawatChatListPageState extends State<PerawatChatListPage> {
  final TextEditingController _searchC = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<ChatRoom> _allRooms = [];
  List<ChatRoom> _filteredRooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _searchC.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await ChatService.fetchPerawatChatRooms();

      if (!mounted) return;

      final totalUnread = rooms.fold<int>(
        0,
        (sum, room) => sum + room.unreadCount,
      );
      ChatUnreadCounter.setTotal(totalUnread);

      setState(() {
        _allRooms = rooms;
        _isLoading = false;
      });
      _onSearchChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchC.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredRooms = _allRooms);
    } else {
      setState(() {
        _filteredRooms = _allRooms.where((r) {
          final titleMatch =
              r.displayTitle('perawat').toLowerCase().contains(query);
          final msgMatch = r.lastMessage.toLowerCase().contains(query);
          final pasienMatch =
              r.pasienName?.toLowerCase().contains(query) ?? false;
          final layananMatch =
              r.layananName?.toLowerCase().contains(query) ?? false;
          return titleMatch || msgMatch || pasienMatch || layananMatch;
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Chat Pasien (Perawat)'),
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          ChatSearchBar(
            controller: _searchC,
            hintText: 'Cari nama pasien, layanan, atau pesan...',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRooms,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: ChatErrorStateView(
              errorMessage: _error!,
              onRetry: _loadRooms,
            ),
          ),
        ],
      );
    }

    if (_allRooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: const ChatEmptyStateView(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Belum ada chat',
              subtitle: 'Percakapan dari pasien akan muncul di sini.',
            ),
          ),
        ],
      );
    }

    if (_filteredRooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: const ChatEmptyStateView(
              icon: Icons.search_off_rounded,
              title: 'Tidak ditemukan',
              subtitle: 'Tidak ada percakapan yang cocok dengan pencarian.',
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 2, bottom: 20),
      itemCount: _filteredRooms.length,
      itemBuilder: (context, index) {
        final room = _filteredRooms[index];
        final title = room.displayTitle('perawat');

        return ChatRoomTile(
          room: room,
          currentRole: 'perawat',
          onTap: () async {
            try {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomPage(
                    roomId: room.id,
                    roomTitle: title,
                    role: 'perawat',
                  ),
                ),
              );
              _loadRooms();
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal membuka chat: $e')),
              );
            }
          },
        );
      },
    );
  }
}

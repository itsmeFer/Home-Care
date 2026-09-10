import 'package:flutter/material.dart';
import 'package:home_care/features/chat/data/models/chat_models.dart';
import 'package:home_care/features/chat/presentation/controllers/chat_unread_counter.dart';
import 'package:home_care/features/chat/data/services/chat_service.dart';
import 'package:home_care/features/chat/presentation/widgets/chat_room_tile.dart';
import 'package:home_care/features/chat/presentation/widgets/chat_state_views.dart';
import 'package:home_care/features/chat/presentation/screens/chat_room_page.dart';
import 'widgets/widgets.dart';

/// Halaman Daftar Chat untuk Pasien/User.
/// Menampilkan percakapan aktif dengan koordinator dan perawat secara real-time.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

/// Backward compatibility alias for existing code referencing PasienChatListPage.
typedef PasienChatListPage = ChatPage;

class _ChatPageState extends State<ChatPage> {
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

  Future<void> _loadRooms({bool isRefresh = false}) async {
    // Only show full skeleton loader on cold start; do not blink on pull-to-refresh
    if (!isRefresh && _allRooms.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final rooms = await ChatService.fetchPasienChatRooms();
      if (!mounted) return;

      final totalUnread = rooms.fold<int>(
        0,
        (sum, room) => sum + room.unreadCount,
      );
      ChatUnreadCounter.setTotal(totalUnread);

      setState(() {
        _allRooms = rooms;
        _isLoading = false;
        _error = null;
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
      if (_filteredRooms.length != _allRooms.length) {
        setState(() => _filteredRooms = List.from(_allRooms));
      }
    } else {
      final matched = _allRooms.where((r) {
        final titleMatch =
            r.displayTitle('pasien').toLowerCase().contains(query);
        final msgMatch = r.lastMessage.toLowerCase().contains(query);
        final layananMatch =
            r.layananName?.toLowerCase().contains(query) ?? false;
        return titleMatch || msgMatch || layananMatch;
      }).toList();

      setState(() => _filteredRooms = matched);
    }
  }

  Future<void> _deleteRoom(ChatRoom room) async {
    final name = room.displayTitle('pasien');
    final confirm = await DeleteChatDialog.show(context, name);
    if (confirm != true) return;

    try {
      await ChatService.deletePasienChatRoom(room.id);
      if (!mounted) return;

      setState(() {
        _allRooms.removeWhere((r) => r.id == room.id);
      });
      _onSearchChanged();

      final totalUnread = _allRooms.fold<int>(
        0,
        (sum, item) => sum + item.unreadCount,
      );
      ChatUnreadCounter.setTotal(totalUnread);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat berhasil dihapus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
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
      body: Column(
        children: [
          ChatSearchBar(
            controller: _searchC,
            hintText: 'Cari nama perawat / koordinator / layanan...',
            onClear: () {
              _searchC.clear();
              _onSearchChanged();
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadRooms(isRefresh: true),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // 1. Shimmer Skeleton Loading State
    if (_isLoading) {
      return const ChatListSkeleton();
    }

    // 2. Error State with Retry
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: ChatErrorStateView(
              errorMessage: _error!,
              onRetry: () => _loadRooms(),
            ),
          ),
        ],
      );
    }

    // 3. Completely Empty State
    if (_allRooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: const ChatEmptyStateView(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Belum ada chat',
              subtitle:
                  'Percakapan dengan koordinator atau perawat akan muncul di sini.',
            ),
          ),
        ],
      );
    }

    // 4. Search Not Found State
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

    // 5. Active Chat Rooms List
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 2, bottom: 20),
      itemCount: _filteredRooms.length,
      itemBuilder: (context, index) {
        final room = _filteredRooms[index];
        final title = room.displayTitle('pasien');

        return ChatRoomTile(
          room: room,
          currentRole: 'pasien',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomPage(
                  roomId: room.id,
                  roomTitle: title,
                  role: 'pasien',
                  simpleChat: room.isPerawatChat,
                ),
              ),
            );
            _loadRooms(isRefresh: true);
          },
          onDelete: () => _deleteRoom(room),
        );
      },
    );
  }
}

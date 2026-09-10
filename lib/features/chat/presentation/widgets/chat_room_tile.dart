import 'package:flutter/material.dart';
import 'package:home_care/features/chat/data/models/chat_models.dart';
import 'package:intl/intl.dart';

class ChatRoomTile extends StatelessWidget {
  final ChatRoom room;
  final String currentRole;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ChatRoomTile({
    super.key,
    required this.room,
    required this.currentRole,
    required this.onTap,
    this.onDelete,
  });

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat('HH:mm').format(dateTime);
    }
    return DateFormat('dd MMM • HH:mm').format(dateTime);
  }

  Widget _buildAvatar(bool isUnread) {
    List<Color> gradientColors;
    IconData icon;

    if (currentRole == 'pasien') {
      if (room.isPerawatChat) {
        gradientColors = const [Color(0xFF0EA5E9), Color(0xFF2563EB)];
        icon = Icons.local_hospital_rounded;
      } else {
        gradientColors = const [Color(0xFF10B981), Color(0xFF059669)];
        icon = Icons.support_agent;
      }
    } else if (currentRole == 'perawat') {
      gradientColors = const [Color(0xFF3B82F6), Color(0xFF1D4ED8)];
      icon = Icons.person_rounded;
    } else {
      // Koordinator
      gradientColors = const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
      icon = Icons.person_rounded;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: gradientColors),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          if (isUnread)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 13,
                height: 13,
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

  Widget _buildUnreadBadge(int count) {
    if (count <= 0) return const SizedBox.shrink();
    final text = count > 99 ? '99+' : count.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      constraints: const BoxConstraints(minWidth: 22),
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

  @override
  Widget build(BuildContext context) {
    final isUnread = room.unreadCount > 0;
    final title = room.displayTitle(currentRole);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          onLongPress: onDelete,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isUnread
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFF1F5F9),
              ),
              color: isUnread ? const Color(0xFFF8FBFF) : Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildAvatar(isUnread),
                const SizedBox(width: 13),
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
                                fontSize: 15,
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
                      if (room.layananName != null &&
                          room.layananName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          room.layananName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        room.lastMessage.isNotEmpty
                            ? room.lastMessage
                            : 'Belum ada pesan',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          height: 1.3,
                          fontSize: 13,
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
                      if (room.status != null &&
                          room.status!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: room.statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            room.statusLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: room.statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUnreadBadge(room.unreadCount),
                    if (onDelete != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

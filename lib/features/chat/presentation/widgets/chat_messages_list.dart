import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:home_care/features/chat/data/models/chat_models.dart';
import 'package:home_care/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:home_care/features/chat/presentation/widgets/etalase_bubble.dart';

class ChatMessagesList extends StatelessWidget {
  final ScrollController controller;
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool negoEnabled;
  final bool hasDeal;
  final String role;
  final ValueChanged<ChatMessage>? onApproveTawar;

  const ChatMessagesList({
    super.key,
    required this.controller,
    required this.messages,
    required this.isLoading,
    this.error,
    required this.negoEnabled,
    required this.hasDeal,
    required this.role,
    this.onApproveTawar,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final timeText =
            msg.createdAt == null
                ? ''
                : DateFormat('HH:mm').format(msg.createdAt!);

        if (negoEnabled && msg.isEtalase && msg.etalaseData != null) {
          return EtalaseBubble(msg: msg, timeText: timeText);
        }

        final isTawar = ChatDealHelper.isTawarHarga(msg.text);
        final imageUrl =
            msg.type == 'image' && msg.fileUrl != null ? msg.fileUrl : null;

        return ChatBubble(
          message: msg,
          timeText: timeText,
          imageUrl: imageUrl,
          onImageTap:
              imageUrl == null
                  ? null
                  : () => ChatBubble.openImagePreview(context, imageUrl),
          extra:
              negoEnabled &&
                      !hasDeal &&
                      role == 'koordinator' &&
                      isTawar &&
                      !msg.isMine &&
                      onApproveTawar != null
                  ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(12),
                      minimumSize: Size.zero,
                      onPressed: () => onApproveTawar!(msg),
                      child: const Text(
                        'Setujui harga ini',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  )
                  : null,
        );
      },
    );
  }
}

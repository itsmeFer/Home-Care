import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_care/features/chat/data/models/chat_models.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String timeText;
  final String? imageUrl;
  final VoidCallback? onImageTap;
  final Widget? extra;

  const ChatBubble({
    super.key,
    required this.message,
    required this.timeText,
    this.imageUrl,
    this.onImageTap,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  isMine
                      ? const Color(0xFF007AFF)
                      : Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                imageUrl != null ? 8 : 14,
                imageUrl != null ? 8 : 12,
                imageUrl != null ? 8 : 14,
                10,
              ),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null) ...[
                    GestureDetector(
                      onTap: onImageTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          imageUrl!,
                          width: 220,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                width: 220,
                                height: 220,
                                color: Colors.black12,
                                child: const Icon(
                                  CupertinoIcons.photo,
                                  size: 40,
                                ),
                              ),
                        ),
                      ),
                    ),
                    if (message.text.trim().isNotEmpty)
                      const SizedBox(height: 10),
                  ],
                  if (message.text.trim().isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        height: 1.35,
                        color: isMine ? Colors.white : const Color(0xFF111111),
                        fontSize: 15,
                      ),
                    ),
                  if (extra != null) extra!,
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMine ? Colors.white70 : const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void openImagePreview(BuildContext context, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'image-preview',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      pageBuilder: (_, __, ___) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 52,
                  right: 20,
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MetaText extends StatelessWidget {
  final String label;
  final String? value;

  const MetaText({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 13, color: Color(0xFF3A3A3C)),
      ),
    );
  }
}

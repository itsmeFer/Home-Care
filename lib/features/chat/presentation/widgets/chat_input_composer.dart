import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatInputComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isBlocked;
  final bool isSending;
  final bool showEtalase;
  final bool showTawar;
  final String hintText;
  final VoidCallback onEtalaseTap;
  final VoidCallback onTawarTap;
  final VoidCallback onImageTap;
  final VoidCallback onSendTap;

  const ChatInputComposer({
    super.key,
    required this.controller,
    required this.isBlocked,
    required this.isSending,
    required this.showEtalase,
    required this.showTawar,
    required this.hintText,
    required this.onEtalaseTap,
    required this.onTawarTap,
    required this.onImageTap,
    required this.onSendTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ComposerAction(
              icon: CupertinoIcons.photo,
              onTap: isBlocked || isSending ? null : onImageTap,
            ),
            if (showEtalase)
              ComposerAction(
                icon: CupertinoIcons.bag,
                onTap: isBlocked || isSending ? null : onEtalaseTap,
              ),
            if (showTawar)
              ComposerAction(
                icon: CupertinoIcons.tag,
                onTap: isBlocked || isSending ? null : onTawarTap,
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  readOnly: isBlocked || isSending,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) {
                    if (!isBlocked && !isSending) {
                      onSendTap();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              child: CupertinoButton(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(999),
                onPressed: isBlocked || isSending ? null : onSendTap,
                child:
                    isSending
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CupertinoActivityIndicator(
                            color: Colors.white,
                          ),
                        )
                        : const Icon(
                          CupertinoIcons.arrow_up,
                          color: Colors.white,
                          size: 20,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComposerAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const ComposerAction({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Icon(
        icon,
        size: 22,
        color:
            onTap == null ? const Color(0xFFB0B0B5) : const Color(0xFF007AFF),
      ),
    );
  }
}

class GlassBottomSheet extends StatelessWidget {
  final Widget child;

  const GlassBottomSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SheetActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SheetActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF007AFF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';

/// Isolated confirmation dialog for deleting a chat room.
class DeleteChatDialog extends StatelessWidget {
  final String partnerName;

  const DeleteChatDialog({
    super.key,
    required this.partnerName,
  });

  /// Static helper to display the dialog and return the confirmation result.
  static Future<bool?> show(BuildContext context, String partnerName) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteChatDialog(partnerName: partnerName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Hapus Chat',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Color(0xFF0F172A),
        ),
      ),
      content: Text(
        'Yakin ingin menghapus percakapan dengan $partnerName?',
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF475569),
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Batal',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Hapus',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

class ActionChipX extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionChipX({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          color: const Color(0xFFFFFFFF),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 12.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OutlineButtonX extends StatefulWidget {
  final IconData icon;
  final String label;
  final FutureOr<void> Function()? onTap;
  final bool enabled;

  const OutlineButtonX({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<OutlineButtonX> createState() => _OutlineButtonXState();
}

class _OutlineButtonXState extends State<OutlineButtonX> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (!widget.enabled || widget.onTap == null || _busy) return;

    setState(() => _busy = true);
    try {
      await widget.onTap!.call();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.onTap == null || _busy;

    return Opacity(
      opacity: disabled ? 0.65 : 1.0,
      child: InkWell(
        onTap: disabled ? null : _handleTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            color: const Color(0xFFF8FAFC),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(widget.icon, size: 18, color: const Color(0xFF0EA5E9)),
              const SizedBox(width: 8),
              Text(
                _busy ? 'Loading…' : widget.label,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 12.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PillBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  const PillBadge({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0EA5E9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 12.2,
            ),
          ),
        ],
      ),
    );
  }
}

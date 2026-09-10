import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_care/features/chat/presentation/widgets/chat_input_composer.dart';

class TawarHargaBottomSheet extends StatefulWidget {
  final Future<bool> Function(String harga, String? catatan) onSendTawar;

  const TawarHargaBottomSheet({super.key, required this.onSendTawar});

  @override
  State<TawarHargaBottomSheet> createState() => _TawarHargaBottomSheetState();
}

class _TawarHargaBottomSheetState extends State<TawarHargaBottomSheet> {
  late final TextEditingController _hargaController;
  late final TextEditingController _catatanController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _hargaController = TextEditingController();
    _catatanController = TextEditingController();
  }

  @override
  void dispose() {
    _hargaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBottomSheet(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                width: 42,
                child: Divider(thickness: 4, color: Color(0xFFD1D1D6)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tawar Harga',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tulis nominal dan catatan singkat untuk koordinator.',
              style: TextStyle(color: Color(0xFF636366)),
            ),
            const SizedBox(height: 16),
            _frostField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              hint: 'Nominal tawaran',
              prefix: 'Rp ',
            ),
            const SizedBox(height: 10),
            _frostField(
              controller: _catatanController,
              hint: 'Catatan opsional',
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(16),
                onPressed:
                    _isSubmitting
                        ? null
                        : () async {
                          final nav = Navigator.of(context);
                          setState(() => _isSubmitting = true);
                          final ok = await widget.onSendTawar(
                            _hargaController.text,
                            _catatanController.text,
                          );
                          if (!mounted) return;
                          setState(() => _isSubmitting = false);
                          if (ok) nav.pop();
                        },
                child:
                    _isSubmitting
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text('Kirim Penawaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frostField({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

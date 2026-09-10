import 'package:flutter/material.dart';
import 'package:home_care/admin/perawat/models/perawat_admin_models.dart';
import 'package:home_care/core/theme/app_colors.dart';

class VerifikasiPerawatDialog extends StatefulWidget {
  final String initial;
  final String? initialNote;

  const VerifikasiPerawatDialog({
    super.key,
    required this.initial,
    this.initialNote,
  });

  @override
  State<VerifikasiPerawatDialog> createState() =>
      _VerifikasiPerawatDialogState();
}

class _VerifikasiPerawatDialogState extends State<VerifikasiPerawatDialog> {
  late String _status;
  late TextEditingController _noteC;

  @override
  void initState() {
    super.initState();
    _status = widget.initial;
    _noteC = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteC.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      PerawatVerifyResult(_status, _noteC.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ubah Status Verifikasi',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Status',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _status,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'verified', child: Text('Verified')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'pending'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteC,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: HCColor.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

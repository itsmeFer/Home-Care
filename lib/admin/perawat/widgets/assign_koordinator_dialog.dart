import 'package:flutter/material.dart';
import 'package:home_care/admin/perawat/models/perawat_admin_models.dart';
import 'package:home_care/core/theme/app_colors.dart';

class AssignKoordinatorDialog extends StatefulWidget {
  final int? currentKoordinatorId;
  final List<KoordinatorItem> coordinators;
  final String perawatName;

  const AssignKoordinatorDialog({
    super.key,
    required this.currentKoordinatorId,
    required this.coordinators,
    required this.perawatName,
  });

  @override
  State<AssignKoordinatorDialog> createState() =>
      _AssignKoordinatorDialogState();
}

class _AssignKoordinatorDialogState extends State<AssignKoordinatorDialog> {
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentKoordinatorId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Assign Koordinator',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perawat: ${widget.perawatName}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Koordinator',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tanpa Koordinator'),
                    ),
                    ...widget.coordinators.map(
                      (k) => DropdownMenuItem<int?>(
                        value: k.id,
                        child: Text('${k.nama} • ID ${k.id}'),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedId = v),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, widget.currentKoordinatorId),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedId),
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

import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

class KoordinatorMultiSelectDialog extends StatefulWidget {
  final List<KoordinatorItem> allKoordinator;
  final Set<int> selectedIds;

  const KoordinatorMultiSelectDialog({
    super.key,
    required this.allKoordinator,
    required this.selectedIds,
  });

  @override
  State<KoordinatorMultiSelectDialog> createState() =>
      _KoordinatorMultiSelectDialogState();
}

class _KoordinatorMultiSelectDialogState
    extends State<KoordinatorMultiSelectDialog> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selectedIds};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Kelola Koordinator',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 420,
        child: widget.allKoordinator.isEmpty
            ? const Center(child: Text('Belum ada data koordinator'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.allKoordinator.length,
                itemBuilder: (_, i) {
                  final item = widget.allKoordinator[i];
                  final checked = _selected.contains(item.id);

                  return CheckboxListTile(
                    value: checked,
                    activeColor: HCColor.primary,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selected.add(item.id);
                        } else {
                          _selected.remove(item.id);
                        }
                      });
                    },
                    title: Text(
                      item.namaLengkap,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        if ((item.kodeKoordinator ?? '').isNotEmpty)
                          'Kode: ${item.kodeKoordinator}',
                        if ((item.wilayah ?? '').isNotEmpty)
                          'Wilayah: ${item.wilayah}',
                      ].join(' • '),
                      style: const TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected.toList()),
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

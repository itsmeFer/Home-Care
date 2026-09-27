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
  final TextEditingController _searchC = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selectedIds};
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  List<KoordinatorItem> get _filteredList {
    if (_searchQuery.trim().isEmpty) return widget.allKoordinator;
    final q = _searchQuery.toLowerCase().trim();
    return widget.allKoordinator.where((item) {
      final name = item.namaLengkap.toLowerCase();
      final code = (item.kodeKoordinator ?? '').toLowerCase();
      final wilayah = (item.wilayah ?? '').toLowerCase();
      return name.contains(q) || code.contains(q) || wilayah.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Kelola Koordinator',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchC,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari koordinator / wilayah...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchC.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selected.length} koordinator dipilih',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (filtered.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        final allFilteredIds =
                            filtered.map((e) => e.id).toSet();
                        if (_selected.containsAll(allFilteredIds)) {
                          _selected.removeAll(allFilteredIds);
                        } else {
                          _selected.addAll(allFilteredIds);
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _selected.containsAll(filtered.map((e) => e.id))
                          ? 'Batal Semua'
                          : 'Pilih Semua',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const Divider(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'Tidak ditemukan koordinator sesuai pencarian'
                              : 'Belum ada data koordinator',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final item = filtered[i];
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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
                          contentPadding: EdgeInsets.zero,
                        );
                      },
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

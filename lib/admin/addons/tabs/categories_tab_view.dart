import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/services/addon_admin_service.dart';

class CategoriesTabView extends StatefulWidget {
  final Function(Map<String, dynamic> item) onEditCategory;
  final VoidCallback onCategoriesChanged;

  const CategoriesTabView({
    super.key,
    required this.onEditCategory,
    required this.onCategoriesChanged,
  });

  @override
  State<CategoriesTabView> createState() => CategoriesTabViewState();
}

class CategoriesTabViewState extends State<CategoriesTabView> {
  bool _loading = true;
  List<dynamic> _catItems = [];

  String _catQ = "";
  int? _catIsActive;
  final int _catPerPage = 15;
  int _catPage = 1;
  int _catLastPage = 1;

  final TextEditingController _catSearchCtrl = TextEditingController();
  bool _catReorderMode = false;

  @override
  void initState() {
    super.initState();
    fetchCategories(resetPage: true);
  }

  @override
  void dispose() {
    _catSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchCategories({bool resetPage = false}) async {
    if (resetPage) _catPage = 1;
    setState(() => _loading = true);

    try {
      final data = await AddonAdminService.fetchCategoryCrud(
        page: _catPage,
        perPage: _catPerPage,
        q: _catQ,
        isActive: _catIsActive,
      );

      if (mounted) {
        setState(() {
          _catItems = data["data"] ?? [];
          _catPage = data["current_page"] ?? 1;
          _catLastPage = data["last_page"] ?? 1;
        });
      }
    } on TimeoutException {
      _showToast("Koneksi timeout saat memuat kategori.");
    } catch (e) {
      _showToast("Error list kategori: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleCategory(int id, bool newValue) async {
    try {
      final msg = await AddonAdminService.toggleCategory(id, newValue);
      _showToast(msg);
      await fetchCategories();
      widget.onCategoriesChanged();
    } on TimeoutException {
      _showToast("Koneksi timeout saat mengubah status.");
    } catch (e) {
      _showToast("Error toggle: $e");
    }
  }

  Future<void> _deleteCategory(int id) async {
    try {
      final msg = await AddonAdminService.deleteCategory(id);
      _showToast(msg);
      await fetchCategories(resetPage: true);
      widget.onCategoriesChanged();
    } on TimeoutException {
      _showToast("Koneksi timeout saat menghapus kategori.");
    } catch (e) {
      _showToast("Error hapus kategori: $e");
    }
  }

  Future<void> _reorderCategoriesCommit() async {
    try {
      final items = <Map<String, dynamic>>[];
      for (int i = 0; i < _catItems.length; i++) {
        items.add({"id": _catItems[i]["id"], "sort_order": i});
      }

      final msg = await AddonAdminService.reorderCategories(items);
      _showToast(msg);
      await fetchCategories(resetPage: true);
      widget.onCategoriesChanged();
    } on TimeoutException {
      _showToast("Koneksi timeout saat menyimpan urutan.");
    } catch (e) {
      _showToast("Error reorder: $e");
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll("Exception: ", "")),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _chip(String text, {Color? accent}) {
    final bg = (accent ?? Colors.grey.shade200).withValues(alpha: 0.15);
    final fg = accent ?? Colors.grey.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (accent ?? Colors.grey.shade300).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _catItems.isEmpty
                  ? const Center(child: Text("Belum ada kategori"))
                  : _catReorderMode
                      ? _buildReorderList()
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _catItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildCategoryCard(_catItems[i]),
                        ),
        ),
        if (!_catReorderMode) _buildPagination(),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _catSearchCtrl,
                  decoration: InputDecoration(
                    hintText: "Cari nama kategori...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _catQ.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _catSearchCtrl.clear();
                              setState(() => _catQ = "");
                              fetchCategories(resetPage: true);
                            },
                          ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (v) {
                    setState(() => _catQ = v);
                    fetchCategories(resetPage: true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: Text(_catReorderMode ? "Reorder ON" : "Reorder"),
                selected: _catReorderMode,
                onSelected: (v) => setState(() => _catReorderMode = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            value: _catIsActive,
            decoration: InputDecoration(
              labelText: "Status",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem<int?>(value: null, child: Text("Semua", overflow: TextOverflow.ellipsis)),
              DropdownMenuItem<int?>(value: 1, child: Text("Aktif", overflow: TextOverflow.ellipsis)),
              DropdownMenuItem<int?>(value: 0, child: Text("Nonaktif", overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) {
              setState(() => _catIsActive = v);
              fetchCategories(resetPage: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReorderList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _catItems.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _catItems.removeAt(oldIndex);
          _catItems.insert(newIndex, item);
        });
      },
      footer: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _reorderCategoriesCommit,
            icon: const Icon(Icons.save_outlined),
            label: const Text("Simpan Urutan (reorder)"),
          ),
        ),
      ),
      itemBuilder: (_, i) {
        final c = _catItems[i];
        return Container(
          key: ValueKey("cat_${c["id"]}"),
          margin: const EdgeInsets.only(bottom: 10),
          child: _buildCategoryCard(c, reorderHandle: true),
        );
      },
    );
  }

  Widget _buildCategoryCard(dynamic c, {bool reorderHandle = false}) {
    final bool active = c["is_active"] == true;
    final int addonsCount = (c["addons_count"] is int)
        ? c["addons_count"]
        : int.tryParse("${c["addons_count"]}") ?? 0;

    final String name = c["name"]?.toString() ?? "-";
    final String desc = c["description"]?.toString() ?? "";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.trim().characters.first.toUpperCase() : "?",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (reorderHandle)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.drag_handle),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip("$addonsCount add-on"),
                    _chip(
                      active ? "Aktif" : "Nonaktif",
                      accent: active ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                if (desc.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Switch(
                      value: active,
                      onChanged: (v) => _toggleCategory(c["id"], v),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: "Edit",
                      onPressed: () => widget.onEditCategory(Map<String, dynamic>.from(c)),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: "Hapus",
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Hapus kategori?"),
                            content: const Text(
                              "Ini akan soft delete. Add-on di dalamnya tetap ada (tanpa kategori).",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Batal"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Hapus"),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) _deleteCategory(c["id"]);
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text("Page $_catPage / $_catLastPage"),
          const Spacer(),
          IconButton(
            onPressed: _catPage <= 1 || _loading
                ? null
                : () {
                    setState(() => _catPage -= 1);
                    fetchCategories();
                  },
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: _catPage >= _catLastPage || _loading
                ? null
                : () {
                    setState(() => _catPage += 1);
                    fetchCategories();
                  },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

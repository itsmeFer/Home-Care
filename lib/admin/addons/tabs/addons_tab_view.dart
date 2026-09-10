import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/services/addon_admin_service.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';

class AddonsTabView extends StatefulWidget {
  final List<dynamic> categoriesDropdown;
  final bool loadingCategoriesDropdown;
  final Function(Map<String, dynamic> item) onEditAddon;

  const AddonsTabView({
    super.key,
    required this.categoriesDropdown,
    required this.loadingCategoriesDropdown,
    required this.onEditAddon,
  });

  @override
  State<AddonsTabView> createState() => AddonsTabViewState();
}

class AddonsTabViewState extends State<AddonsTabView> {
  bool _loading = true;
  List<dynamic> _addons = [];

  String _q = "";
  int? _selectedCategoryId;
  int? _filterActive;

  final int _perPage = 15;
  int _currentPage = 1;
  int _lastPage = 1;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAddons(resetPage: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchAddons({bool resetPage = false}) async {
    if (resetPage) _currentPage = 1;

    setState(() => _loading = true);
    try {
      final data = await AddonAdminService.fetchAddons(
        page: _currentPage,
        perPage: _perPage,
        q: _q,
        categoryId: _selectedCategoryId,
        isActive: _filterActive,
      );

      if (mounted) {
        setState(() {
          _addons = data["data"] ?? [];
          _currentPage = data["current_page"] ?? 1;
          _lastPage = data["last_page"] ?? 1;
        });
      }
    } on TimeoutException {
      _showToast("Koneksi timeout saat memuat add-ons.");
    } catch (e) {
      _showToast("Error list add-ons: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAddon(int id, bool newValue) async {
    try {
      await AddonAdminService.toggleAddon(id, newValue);
      _showToast("Status berhasil diubah");
      await fetchAddons();
    } on TimeoutException {
      _showToast("Koneksi timeout saat toggle status.");
    } catch (e) {
      _showToast("Error toggle: $e");
    }
  }

  Future<void> _deleteAddon(int id) async {
    try {
      await AddonAdminService.deleteAddon(id);
      _showToast("Add-on berhasil dihapus");
      await fetchAddons();
    } on TimeoutException {
      _showToast("Koneksi timeout saat menghapus add-on.");
    } catch (e) {
      _showToast("Error hapus: $e");
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
              : _addons.isEmpty
                  ? const Center(child: Text("Belum ada add-ons"))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _addons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildAddonCard(_addons[i]),
                    ),
        ),
        _buildPagination(),
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
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: "Cari kode/nama/desk...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _q = "");
                        fetchAddons(resetPage: true);
                      },
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (v) {
              setState(() => _q = v);
              fetchAddons(resetPage: true);
            },
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              final categoryField = DropdownButtonFormField<int?>(
                isExpanded: true,
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: "Kategori",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text("Semua kategori", overflow: TextOverflow.ellipsis),
                  ),
                  ...widget.categoriesDropdown.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c["id"],
                      child: Text("${c["name"]}", overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) {
                  setState(() => _selectedCategoryId = v);
                  fetchAddons(resetPage: true);
                },
              );

              final statusField = DropdownButtonFormField<int?>(
                isExpanded: true,
                value: _filterActive,
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
                  setState(() => _filterActive = v);
                  fetchAddons(resetPage: true);
                },
              );

              if (isNarrow) {
                return Column(
                  children: [
                    categoryField,
                    const SizedBox(height: 10),
                    statusField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: categoryField),
                  const SizedBox(width: 10),
                  Expanded(child: statusField),
                ],
              );
            },
          ),
          if (widget.loadingCategoriesDropdown)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text("Memuat kategori dropdown..."),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddonCard(dynamic a) {
    final bool aktif = a["aktif"] == true;
    final bool qtyEnabled = a["is_qty_enabled"] == true;

    final category = a["category"];
    final categoryName = category != null ? (category["name"] ?? "-") : "-";

    final gambar = a["gambar"];
    final priceFormatted = a["harga_fix_formatted"] ?? AppFormatters.currency(a["harga_fix"] ?? 0);
    final mediaBase = ApiConstants.apiBase;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 68,
              height: 68,
              color: Colors.grey.shade100,
              child: gambar == null
                  ? Icon(Icons.extension_outlined, color: Colors.grey.shade500)
                  : AppCachedImage(
                      imageUrl: "$mediaBase/media/$gambar",
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorWidget: Icon(Icons.broken_image_outlined, color: Colors.grey.shade500),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a["nama_addon"] ?? "-",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  a["kode_addon"] ?? "-",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip("Kategori: $categoryName"),
                    _chip(priceFormatted),
                    _chip(qtyEnabled ? "Qty: ON" : "Qty: OFF"),
                    _chip(
                      aktif ? "Aktif" : "Nonaktif",
                      accent: aktif ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                if ((a["deskripsi"] ?? "").toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    a["deskripsi"],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Switch(
                      value: aktif,
                      onChanged: (v) => _toggleAddon(a["id"], v),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: "Edit",
                      onPressed: () => widget.onEditAddon(Map<String, dynamic>.from(a)),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: "Hapus",
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Hapus add-on?"),
                            content: const Text(
                              "Ini akan soft delete. Data transaksi yang sudah ada aman.",
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
                        if (ok == true) _deleteAddon(a["id"]);
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
          Text("Page $_currentPage / $_lastPage"),
          const Spacer(),
          IconButton(
            onPressed: _currentPage <= 1 || _loading
                ? null
                : () {
                    setState(() => _currentPage -= 1);
                    fetchAddons();
                  },
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: _currentPage >= _lastPage || _loading
                ? null
                : () {
                    setState(() => _currentPage += 1);
                    fetchAddons();
                  },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/models/addon_admin_model.dart';
import 'package:home_care/admin/addons/services/addon_admin_service.dart';
import 'package:home_care/admin/addons/widgets/addon_pagination_bar.dart';
import 'package:home_care/admin/addons/widgets/addon_states.dart';
import 'package:home_care/admin/addons/widgets/category_card.dart';
import 'package:home_care/admin/addons/widgets/category_filter_bar.dart';
import 'package:home_care/admin/addons/widgets/category_reorder_list.dart';
import 'package:home_care/core/theme/app_colors.dart';

class CategoriesTabView extends StatefulWidget {
  final Function(AddonCategoryItem item) onEditCategory;
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
  String? _errorMessage;
  List<AddonCategoryItem> _catItems = [];

  String _catQ = "";
  int? _catIsActive;
  final int _catPerPage = 15;
  int _catPage = 1;
  int _catLastPage = 1;
  int _catTotalItems = 0;

  final TextEditingController _catSearchCtrl = TextEditingController();
  Timer? _catSearchDebounce;
  bool _catReorderMode = false;
  bool _isSavingOrder = false;

  @override
  void initState() {
    super.initState();
    fetchCategories(resetPage: true);
  }

  @override
  void dispose() {
    _catSearchDebounce?.cancel();
    _catSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchCategories({bool resetPage = false}) async {
    if (resetPage) _catPage = 1;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await AddonAdminService.fetchCategoryCrud(
        page: _catPage,
        perPage: _catPerPage,
        q: _catQ,
        isActive: _catIsActive,
      );

      if (mounted) {
        setState(() {
          _catItems = result.items;
          _catPage = result.currentPage;
          _catLastPage = result.lastPage;
          _catTotalItems = result.total;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _errorMessage = "Koneksi timeout saat memuat kategori.");
        _showToast("Koneksi timeout saat memuat kategori.");
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceAll("Exception: ", "");
      if (mounted) {
        setState(() => _errorMessage = cleanMsg);
        _showToast("Error list kategori: $cleanMsg");
      }
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
      _showToast("Error toggle: ${e.toString().replaceAll('Exception: ', '')}");
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
      _showToast("Error hapus kategori: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }

  Future<void> _reorderCategoriesCommit() async {
    setState(() => _isSavingOrder = true);
    try {
      final items = <Map<String, dynamic>>[];
      for (int i = 0; i < _catItems.length; i++) {
        items.add({"id": _catItems[i].id, "sort_order": i});
      }

      final msg = await AddonAdminService.reorderCategories(items);
      _showToast(msg);
      setState(() => _catReorderMode = false);
      await fetchCategories(resetPage: true);
      widget.onCategoriesChanged();
    } on TimeoutException {
      _showToast("Koneksi timeout saat menyimpan urutan.");
    } catch (e) {
      _showToast("Error reorder: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      if (mounted) setState(() => _isSavingOrder = false);
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.replaceAll("Exception: ", "")),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetFilter() {
    _catSearchDebounce?.cancel();
    _catSearchCtrl.clear();
    setState(() {
      _catQ = "";
      _catIsActive = null;
    });
    fetchCategories(resetPage: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CategoryFilterBar(
          searchCtrl: _catSearchCtrl,
          query: _catQ,
          isActive: _catIsActive,
          reorderMode: _catReorderMode,
          onQueryChanged: (v) {
            _catSearchDebounce?.cancel();
            _catSearchDebounce = Timer(const Duration(milliseconds: 400), () {
              if (mounted) {
                setState(() => _catQ = v);
                fetchCategories(resetPage: true);
              }
            });
          },
          onClearQuery: () {
            _catSearchDebounce?.cancel();
            _catSearchCtrl.clear();
            setState(() => _catQ = "");
            fetchCategories(resetPage: true);
          },
          onStatusChanged: (status) {
            setState(() => _catIsActive = status);
            fetchCategories(resetPage: true);
          },
          onToggleReorderMode: () {
            setState(() => _catReorderMode = !_catReorderMode);
          },
          onReset: _resetFilter,
        ),
        Expanded(
          child: _catReorderMode ? _buildReorderView() : _buildBody(),
        ),
        if (!_loading && _catItems.isNotEmpty && !_catReorderMode)
          AddonPaginationBar(
            currentPage: _catPage,
            lastPage: _catLastPage,
            totalItems: _catTotalItems,
            currentItemsCount: _catItems.length,
            onPageChanged: (newPage) {
              setState(() => _catPage = newPage);
              fetchCategories();
            },
          ),
      ],
    );
  }

  Widget _buildReorderView() {
    return CategoryReorderList(
      items: _catItems,
      isSavingOrder: _isSavingOrder,
      onReorderItem: (oldIndex, newIndex) {
        setState(() {
          final item = _catItems.removeAt(oldIndex);
          _catItems.insert(newIndex, item);
        });
      },
      onSave: _reorderCategoriesCommit,
      onCancel: () {
        setState(() => _catReorderMode = false);
        fetchCategories(resetPage: true);
      },
    );
  }

  Widget _buildBody() {
    if (_loading && _catItems.isEmpty) {
      return const AddonSkeletonList();
    }

    if (_errorMessage != null && _catItems.isEmpty) {
      return AddonErrorState(
        errorMessage: _errorMessage,
        onRetry: () => fetchCategories(resetPage: true),
      );
    }

    if (_catItems.isEmpty) {
      return AddonEmptyState(
        hasFilter: _catQ.isNotEmpty || _catIsActive != null,
        onResetFilter: _resetFilter,
        title: "Kategori Kosong",
        message: "Belum ada kategori add-on yang ditambahkan.",
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => fetchCategories(resetPage: true),
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _catItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => CategoryCard(
          item: _catItems[i],
          onEdit: widget.onEditCategory,
          onToggle: _toggleCategory,
          onDelete: _deleteCategory,
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/models/addon_admin_model.dart';
import 'package:home_care/admin/addons/services/addon_admin_service.dart';
import 'package:home_care/admin/addons/widgets/addon_card.dart';
import 'package:home_care/admin/addons/widgets/addon_filter_bar.dart';
import 'package:home_care/admin/addons/widgets/addon_pagination_bar.dart';
import 'package:home_care/admin/addons/widgets/addon_states.dart';
import 'package:home_care/core/theme/app_colors.dart';

class AddonsTabView extends StatefulWidget {
  final List<AddonCategoryItem> categoriesDropdown;
  final bool loadingCategoriesDropdown;
  final Function(AddonItem item) onEditAddon;

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
  String? _errorMessage;
  List<AddonItem> _addons = [];

  String _q = "";
  int? _selectedCategoryId;
  int? _filterActive;

  final int _perPage = 15;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    fetchAddons(resetPage: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchAddons({bool resetPage = false}) async {
    if (resetPage) _currentPage = 1;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await AddonAdminService.fetchAddons(
        page: _currentPage,
        perPage: _perPage,
        q: _q,
        categoryId: _selectedCategoryId,
        isActive: _filterActive,
      );

      if (mounted) {
        setState(() {
          _addons = result.items;
          _currentPage = result.currentPage;
          _lastPage = result.lastPage;
          _totalItems = result.total;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _errorMessage = "Koneksi timeout saat memuat add-ons.");
        _showToast("Koneksi timeout saat memuat add-ons.");
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceAll("Exception: ", "");
      if (mounted) {
        setState(() => _errorMessage = cleanMsg);
        _showToast("Error list add-ons: $cleanMsg");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAddon(int id, bool newValue) async {
    try {
      await AddonAdminService.toggleAddon(id, newValue);
      _showToast("Status add-on berhasil diubah");
      await fetchAddons();
    } on TimeoutException {
      _showToast("Koneksi timeout saat mengubah status add-on.");
    } catch (e) {
      _showToast("Error toggle: ${e.toString().replaceAll('Exception: ', '')}");
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
      _showToast("Error hapus: ${e.toString().replaceAll('Exception: ', '')}");
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
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _q = "";
      _selectedCategoryId = null;
      _filterActive = null;
    });
    fetchAddons(resetPage: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AddonFilterBar(
          searchCtrl: _searchCtrl,
          query: _q,
          selectedCategoryId: _selectedCategoryId,
          filterActive: _filterActive,
          categoriesDropdown: widget.categoriesDropdown,
          onQueryChanged: (v) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 400), () {
              if (mounted) {
                setState(() => _q = v);
                fetchAddons(resetPage: true);
              }
            });
          },
          onClearQuery: () {
            _searchDebounce?.cancel();
            _searchCtrl.clear();
            setState(() => _q = "");
            fetchAddons(resetPage: true);
          },
          onCategoryChanged: (catId) {
            setState(() => _selectedCategoryId = catId);
            fetchAddons(resetPage: true);
          },
          onStatusChanged: (status) {
            setState(() => _filterActive = status);
            fetchAddons(resetPage: true);
          },
          onReset: _resetFilter,
        ),
        Expanded(
          child: _buildBody(),
        ),
        if (!_loading && _addons.isNotEmpty)
          AddonPaginationBar(
            currentPage: _currentPage,
            lastPage: _lastPage,
            totalItems: _totalItems,
            currentItemsCount: _addons.length,
            onPageChanged: (newPage) {
              setState(() => _currentPage = newPage);
              fetchAddons();
            },
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _addons.isEmpty) {
      return const AddonSkeletonList();
    }

    if (_errorMessage != null && _addons.isEmpty) {
      return AddonErrorState(
        errorMessage: _errorMessage,
        onRetry: () => fetchAddons(resetPage: true),
      );
    }

    if (_addons.isEmpty) {
      return AddonEmptyState(
        hasFilter: _q.isNotEmpty || _selectedCategoryId != null || _filterActive != null,
        onResetFilter: _resetFilter,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => fetchAddons(resetPage: true),
      child: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _addons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => AddonCard(
          item: _addons[i],
          onEdit: widget.onEditAddon,
          onToggle: _toggleAddon,
          onDelete: _deleteAddon,
        ),
      ),
    );
  }
}

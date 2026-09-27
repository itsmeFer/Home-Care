import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/models/addon_admin_model.dart';
import 'package:home_care/admin/addons/services/addon_admin_service.dart';
import 'package:home_care/admin/addons/tabs/addons_tab_view.dart';
import 'package:home_care/admin/addons/tabs/categories_tab_view.dart';
import 'package:home_care/admin/addons/widgets/addon_form_sheet.dart';
import 'package:home_care/admin/addons/widgets/category_form_sheet.dart';
import 'package:home_care/core/theme/app_colors.dart';

class CrudAddOnsPage extends StatefulWidget {
  const CrudAddOnsPage({super.key});

  @override
  State<CrudAddOnsPage> createState() => _CrudAddOnsPageState();
}

class _CrudAddOnsPageState extends State<CrudAddOnsPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  final GlobalKey<AddonsTabViewState> _addonsTabKey = GlobalKey<AddonsTabViewState>();
  final GlobalKey<CategoriesTabViewState> _categoriesTabKey = GlobalKey<CategoriesTabViewState>();

  List<AddonCategoryItem> _categoriesDropdown = [];
  bool _loadingDropdown = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadCategoriesDropdown();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesDropdown() async {
    setState(() => _loadingDropdown = true);
    try {
      final list = await AddonAdminService.fetchCategoriesDropdown();
      if (mounted) {
        setState(() => _categoriesDropdown = list);
      }
    } catch (_) {
      // Ignored: silent dropdown fallback
    } finally {
      if (mounted) setState(() => _loadingDropdown = false);
    }
  }

  void _openAddonForm({AddonItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddonFormSheet(
        item: item,
        categoriesDropdown: _categoriesDropdown,
        onSuccess: () {
          _addonsTabKey.currentState?.fetchAddons();
        },
      ),
    );
  }

  void _openCategoryForm({AddonCategoryItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormSheet(
        item: item,
        onSuccess: () {
          _categoriesTabKey.currentState?.fetchCategories(resetPage: true);
          _loadCategoriesDropdown();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          "Add-ons & Kategori",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Muat Ulang",
            onPressed: () {
              _loadCategoriesDropdown();
              _addonsTabKey.currentState?.fetchAddons(resetPage: true);
              _categoriesTabKey.currentState?.fetchCategories(resetPage: true);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: "Tambah Data",
            onPressed: () {
              if (_tab.index == 0) {
                _openAddonForm();
              } else {
                _openCategoryForm();
              }
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(
                  icon: Icon(Icons.extension_outlined, size: 20),
                  text: "Add-ons Layanan",
                ),
                Tab(
                  icon: Icon(Icons.category_outlined, size: 20),
                  text: "Kategori Add-on",
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          AddonsTabView(
            key: _addonsTabKey,
            categoriesDropdown: _categoriesDropdown,
            loadingCategoriesDropdown: _loadingDropdown,
            onEditAddon: (item) => _openAddonForm(item: item),
          ),
          CategoriesTabView(
            key: _categoriesTabKey,
            onEditCategory: (item) => _openCategoryForm(item: item),
            onCategoriesChanged: () {
              _loadCategoriesDropdown();
              _addonsTabKey.currentState?.fetchAddons();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          if (_tab.index == 0) {
            _openAddonForm();
          } else {
            _openCategoryForm();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: AnimatedBuilder(
          animation: _tab,
          builder: (_, __) => Text(
            _tab.index == 0 ? "Tambah Add-on" : "Tambah Kategori",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

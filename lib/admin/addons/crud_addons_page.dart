import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/services/addon_admin_service.dart';
import 'package:home_care/admin/addons/tabs/addons_tab_view.dart';
import 'package:home_care/admin/addons/tabs/categories_tab_view.dart';
import 'package:home_care/admin/addons/widgets/addon_form_sheet.dart';
import 'package:home_care/admin/addons/widgets/category_form_sheet.dart';

class CrudAddOnsPage extends StatefulWidget {
  const CrudAddOnsPage({super.key});

  @override
  State<CrudAddOnsPage> createState() => _CrudAddOnsPageState();
}

class _CrudAddOnsPageState extends State<CrudAddOnsPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  final GlobalKey<AddonsTabViewState> _addonsTabKey = GlobalKey<AddonsTabViewState>();
  final GlobalKey<CategoriesTabViewState> _categoriesTabKey = GlobalKey<CategoriesTabViewState>();

  List<dynamic> _categoriesDropdown = [];
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

  void _openAddonForm({Map<String, dynamic>? item}) {
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

  void _openCategoryForm({Map<String, dynamic>? item}) {
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
      appBar: AppBar(
        title: const Text("Add-ons & Kategori"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.extension_outlined), text: "Add-ons"),
            Tab(icon: Icon(Icons.category_outlined), text: "Kategori"),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: () {
              _loadCategoriesDropdown();
              _addonsTabKey.currentState?.fetchAddons(resetPage: true);
              _categoriesTabKey.currentState?.fetchCategories(resetPage: true);
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: "Tambah",
            onPressed: () {
              if (_tab.index == 0) {
                _openAddonForm();
              } else {
                _openCategoryForm();
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tab.index == 0) {
            _openAddonForm();
          } else {
            _openCategoryForm();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

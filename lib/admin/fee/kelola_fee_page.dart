import 'package:flutter/material.dart';
import 'package:home_care/admin/fee/services/fee_admin_service.dart';
import 'package:home_care/admin/fee/tabs/fee_management_tab_view.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/admin/fee/widgets/fee_ui_components.dart';

class KelolaFeePage extends StatefulWidget {
  const KelolaFeePage({super.key});

  @override
  State<KelolaFeePage> createState() => _KelolaFeePageState();
}

class _KelolaFeePageState extends State<KelolaFeePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final FeeAdminService _service = FeeAdminService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimary,
        ).copyWith(primary: kPrimary),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kText,
          elevation: 0,
          centerTitle: false,
        ),
        dividerColor: kBorder,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Kelola Fee / Komisi',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: TabBar(
            controller: _tab,
            indicatorColor: kPrimary,
            indicatorWeight: 3,
            labelColor: kText,
            unselectedLabelColor: kTextSub,
            tabs: const [
              Tab(text: '💊 Fee Layanan'),
              Tab(text: '🧪 Fee Add-on'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: R.contentMaxWidth(context)),
            child: TabBarView(
              controller: _tab,
              children: [
                FeeManagementTabView(service: _service, isAddon: false),
                FeeManagementTabView(service: _service, isAddon: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

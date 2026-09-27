import 'package:flutter/material.dart';
import 'package:home_care/admin/fee/services/fee_admin_service.dart';
import 'package:home_care/admin/fee/widgets/fee_charts.dart';
import 'package:home_care/admin/fee/widgets/fee_item_selector_card.dart';
import 'package:home_care/admin/fee/widgets/fee_recipient_list_section.dart';
import 'package:home_care/admin/fee/widgets/fee_rule_form_dialog.dart';
import 'package:home_care/admin/fee/widgets/fee_stats_distribution_card.dart';
import 'package:home_care/admin/fee/models/fee_models.dart';
import 'package:home_care/admin/fee/widgets/fee_ui_components.dart';

class FeeManagementTabView extends StatefulWidget {
  final FeeAdminService service;
  final bool isAddon;

  const FeeManagementTabView({
    super.key,
    required this.service,
    required this.isAddon,
  });

  @override
  State<FeeManagementTabView> createState() => _FeeManagementTabViewState();
}

class _FeeManagementTabViewState extends State<FeeManagementTabView> {
  bool _loading = true;
  String? _error;

  List<dynamic> _items = [];
  int? _selectedId;

  List<FeeRule> _rules = [];
  num _sumPercent = 0;
  int _activeCount = 0;

  FeeSimMode _mode = FeeSimMode.perItem;
  FeeChartType _chartType = FeeChartType.bar;

  bool _globalLoading = false;
  String? _globalError;
  List<FeeSimItem> _globalItems = [];
  num _globalTotalNominal = 0;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await widget.service.fetchItems(widget.isAddon);
      _items = list;

      if (_items.isNotEmpty) {
        _selectedId ??= _items.first.id;
        await _loadRules();
      } else {
        _rules = [];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRules() async {
    final id = _selectedId;
    if (id == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.service.fetchRules(widget.isAddon, id);
      _rules = res.rules;
      _sumPercent = res.sumPercent;
      _activeCount = res.activeCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  dynamic _selectedItem() {
    if (_selectedId == null) return null;
    for (final item in _items) {
      if (item.id == _selectedId) return item;
    }
    return null;
  }

  List<FeeSimItem> _buildChartItems(dynamic item) {
    if (item == null) return [];
    final harga = item.hargaFix;
    return _rules.where((r) => r.isActive).map((r) {
      final nominal = harga * (r.percent / 100);
      return FeeSimItem(
        id: r.id,
        userId: r.userId,
        nama: r.namaPenerima,
        fotoUrl: r.fotoUrl,
        percent: r.percent,
        nominal: nominal,
        bankNama: r.bankNama,
        noRekening: r.noRekening,
        atasNama: r.atasNamaRekening,
      );
    }).toList();
  }

  Future<void> _loadGlobalSummary() async {
    if (_items.isEmpty) return;

    setState(() {
      _globalLoading = true;
      _globalError = null;
    });

    try {
      final summary = await widget.service.fetchGlobalSimulation(
        widget.isAddon,
        _items,
      );
      _globalItems = summary.items;
      _globalTotalNominal = summary.totalNominal;
    } catch (e) {
      _globalError = e.toString();
    } finally {
      if (mounted) setState(() => _globalLoading = false);
    }
  }

  Future<void> _openForm({FeeRule? existing}) async {
    if (_selectedId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => FeeRuleFormDialog(
            api: widget.service.api,
            itemId: _selectedId!,
            isAddon: widget.isAddon,
            existing: existing,
          ),
    );

    if (ok == true) {
      await _loadRules();
    }
  }

  Future<void> _recalc() async {
    final id = _selectedId;
    if (id == null) return;

    try {
      await widget.service.recalculateSplit(widget.isAddon, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Persentase dibagi ulang (100% dibagi rata).'),
          ),
        );
      }
      await _loadRules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmDelete(FeeRule r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => RoundedDialog(
            width: R.dialogWidth(context, max: 560),
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nonaktifkan Penerima?',
                    style: TextStyle(color: kText, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Penerima "${r.namaPenerima}" akan dinonaktifkan.',
                    style: const TextStyle(color: kTextSub),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: RBtn(
                          filled: false,
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RBtn(
                          filled: true,
                          color: kDanger,
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Nonaktifkan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (ok == true) {
      try {
        await widget.service.deleteRule(widget.isAddon, r.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Penerima dinonaktifkan.')),
          );
        }
        await _loadRules();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _selectedItem();
    final pad = R.pagePadding(context);
    final chartItems = _buildChartItems(item);
    final totalNominal = chartItems.fold<num>(0, (p, e) => p + e.nominal);
    final itemLabel = widget.isAddon ? 'add-on' : 'layanan';

    return RefreshIndicator(
      onRefresh: () async {
        await _loadItems();
        if (_mode == FeeSimMode.semuaItem) {
          await _loadGlobalSummary();
        }
      },
      child: ListView(
        padding: pad,
        children: [
          FeeItemSelectorCard(
            isAddon: widget.isAddon,
            items: _items,
            selectedId: _selectedId,
            selectedItem: item,
            loading: _loading,
            activeCount: _activeCount,
            sumPercent: _sumPercent,
            onItemSelected: (v) async {
              setState(() => _selectedId = v);
              await _loadRules();
            },
            onRecalc: _recalc,
            onAddRecipient: () => _openForm(),
          ),

          const SizedBox(height: 14),

          FeeStatsDistributionCard(
            itemLabel: itemLabel,
            mode: _mode,
            chartType: _chartType,
            onModeChanged: (newMode) async {
              setState(() => _mode = newMode);
              if (newMode == FeeSimMode.semuaItem &&
                  _globalItems.isEmpty &&
                  !_globalLoading) {
                await _loadGlobalSummary();
              }
            },
            onChartTypeChanged: (newChart) {
              setState(() => _chartType = newChart);
            },
            loading: _loading,
            error: _error,
            items: chartItems,
            totalNominal: totalNominal,
            globalLoading: _globalLoading,
            globalError: _globalError,
            globalItems: _globalItems,
            globalTotalNominal: _globalTotalNominal,
          ),

          const SizedBox(height: 14),

          FeeRecipientListSection(
            mode: _mode,
            itemLabel: itemLabel,
            loading: _loading,
            error: _error,
            rules: _rules,
            selectedItem: item,
            onEditRule: (r) => _openForm(existing: r),
            onDeleteRule: _confirmDelete,
            globalLoading: _globalLoading,
            globalError: _globalError,
            globalItems: _globalItems,
          ),

          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

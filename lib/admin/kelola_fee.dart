import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart' as core_net;
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';
import 'package:home_care/utils/app_cached_image.dart';
import 'package:home_care/features/fee_management/presentation/widgets/fee_dialogs.dart';
import 'package:home_care/features/fee_management/presentation/widgets/fee_ui_components.dart';
import 'package:home_care/features/fee_management/presentation/widgets/fee_charts.dart';

export 'package:home_care/features/fee_management/domain/fee_models.dart';

const Color kBg = AppColors.background;
const Color kCard = AppColors.card;
const Color kBorder = AppColors.border;
const Color kPrimary = Color(0xFF2563EB);
const Color kText = AppColors.textPrimary;
const Color kTextSub = AppColors.textSecondary;
const Color kDanger = AppColors.danger;
const Color kSuccess = AppColors.success;
const Color kAddon = Color(0xFF7C3AED);

String get kBaseUrl => ApiConstants.baseUrl;
String get kApiBase => ApiConstants.apiBase;

String get kFeeLayananUrl => ApiConstants.adminFeeLayanan;
String get kFeeRulesUrl => ApiConstants.adminFeeRules;

String get kFeeAddonsUrl => ApiConstants.adminFeeAddons;
String get kFeeAddonRulesUrl => ApiConstants.adminFeeAddonRules;

String get kFeeUsersUrl => ApiConstants.adminFeeUsers;
String get kFeeCreateUserUrl => ApiConstants.adminFeeCreateUser;
String get kRolesUrl => ApiConstants.adminRoles;

class R {
  static double w(BuildContext c) => MediaQuery.of(c).size.width;

  static bool isPhone(BuildContext c) => w(c) < 600;
  static bool isTablet(BuildContext c) => w(c) >= 600 && w(c) < 1024;
  static bool isDesktop(BuildContext c) => w(c) >= 1024;

  static double contentMaxWidth(BuildContext c) {
    final width = w(c);
    if (width >= 1400) return 1120;
    if (width >= 1200) return 1040;
    if (width >= 1024) return 960;
    return width;
  }

  static EdgeInsets pagePadding(BuildContext c) {
    if (isPhone(c)) return const EdgeInsets.all(14);
    if (isTablet(c)) return const EdgeInsets.all(18);
    return const EdgeInsets.all(22);
  }

  static double dialogWidth(BuildContext c, {double max = 720}) {
    final width = w(c);
    final v = (width * 0.92).clamp(320, max);
    return v.toDouble();
  }

  static double dialogHeight(BuildContext c, {double max = 620}) {
    final h = MediaQuery.of(c).size.height;
    final v = (h * 0.86).clamp(420, max);
    return v.toDouble();
  }
}

String? resolveMediaUrl(dynamic raw) => ApiConstants.resolveMediaUrl(raw);

InputDecoration fieldDeco({String? hint, Widget? prefixIcon}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextSub),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kDanger, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

String formatRupiah(num value) => AppFormatters.formatRupiah(value);

List<Map<String, dynamic>> extractList(dynamic res) {
  if (res is List) return res.cast<Map<String, dynamic>>();

  if (res is Map) {
    final d = res['data'];
    if (d is List) return d.cast<Map<String, dynamic>>();
    if (d is Map && d['data'] is List) {
      return (d['data'] as List).cast<Map<String, dynamic>>();
    }
  }
  return [];
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

typedef ApiClient = FeeApiBridge;

enum _SimMode { perItem, semuaItem }

typedef _ChartType = FeeChartType;

class _RBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool filled;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double radius;

  const _RBtn({
    required this.child,
    required this.onPressed,
    required this.filled,
    this.color,
    this.textColor,
    this.icon,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (filled ? kPrimary : Colors.white);
    final fg = textColor ?? (filled ? Colors.white : kPrimary);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: filled ? bg : Colors.white,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              border: filled ? null : Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: fg, fontWeight: FontWeight.w800),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;
  const _MiniChip({required this.text, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kPrimary;
    final bg = c.withOpacity(0.10);
    final bd = c.withOpacity(0.28);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: bd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              color: kText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(color: kTextSub, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDanger.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDanger.withOpacity(0.28)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: kText, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _HintBox extends StatelessWidget {
  final String text;
  const _HintBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(color: kTextSub, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _MiniCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _RoundedDialog extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;

  const _RoundedDialog({
    required this.child,
    this.width,
    this.height,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? R.dialogWidth(context);
    final h = height;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.white,
          child: SizedBox(width: w, height: h, child: child),
        ),
      ),
    );
  }
}

Widget _avatarCircle({
  required String? url,
  required IconData fallback,
  double radius = 22,
}) {
  if (url == null || url.trim().isEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: kPrimary.withOpacity(0.10),
      child: Icon(fallback, color: kPrimary),
    );
  }

  return AppCircleAvatar(
    imageUrl: url,
    radius: radius,
    fallbackIcon: fallback,
    backgroundColor: kPrimary.withOpacity(0.10),
    foregroundColor: kPrimary,
  );
}

class KelolaFeePage extends StatefulWidget {
  const KelolaFeePage({super.key});

  @override
  State<KelolaFeePage> createState() => _KelolaFeePageState();
}

class _KelolaFeePageState extends State<KelolaFeePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _api = ApiClient();

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
        scaffoldBackgroundColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kText,
          elevation: 0,
          centerTitle: false,
        ),
        dividerColor: kBorder,
      ),
      child: Scaffold(
        backgroundColor: kBg,
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
                _FeeManagementTab(api: _api, isAddon: false),
                _FeeManagementTab(api: _api, isAddon: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeeManagementTab extends StatefulWidget {
  final ApiClient api;
  final bool isAddon;

  const _FeeManagementTab({required this.api, required this.isAddon});

  @override
  State<_FeeManagementTab> createState() => _FeeManagementTabState();
}

class _FeeManagementTabState extends State<_FeeManagementTab> {
  bool _loading = true;
  String? _error;

  List<dynamic> _items = [];
  int? _selectedId;

  List<FeeRule> _rules = [];
  num _sumPercent = 0;
  int _activeCount = 0;

  _SimMode _mode = _SimMode.perItem;
  _ChartType _chartType = _ChartType.bar;

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
      final url = widget.isAddon ? kFeeAddonsUrl : kFeeLayananUrl;
      final res = await widget.api.getJson(
        url,
        query: {'per_page': '200', 'aktif': '1'},
      );
      final list = extractList(res);

      if (widget.isAddon) {
        _items = list.map((e) => Addon.fromJson(e)).toList();
      } else {
        _items = list.map((e) => Layanan.fromJson(e)).toList();
      }

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
    if (_selectedId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = widget.isAddon ? kFeeAddonRulesUrl : kFeeRulesUrl;
      final idKey = widget.isAddon ? 'addon_id' : 'layanan_id';

      final res = await widget.api.getJson(
        url,
        query: {idKey: _selectedId.toString(), 'per_page': '200', 'aktif': '1'},
      );

      final pageObj =
          (res['data'] is Map)
              ? Map<String, dynamic>.from(res['data'])
              : <String, dynamic>{};
      final rawList = pageObj['data'];
      final list = (rawList is List) ? rawList : const [];

      _rules =
          list
              .where((e) => e is Map)
              .map((e) => FeeRule.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();

      final meta =
          (res['meta'] is Map)
              ? Map<String, dynamic>.from(res['meta'])
              : <String, dynamic>{};

      _sumPercent = parseNum(meta['sum_percent_active']);
      _activeCount =
          (meta['active_count'] ?? 0) is num
              ? (meta['active_count'] as num).toInt()
              : 0;
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
      final Map<int, FeeSimItem> agg = {};
      num grandTotal = 0;

      final baseUrl = widget.isAddon ? kFeeAddonRulesUrl : kFeeRulesUrl;

      for (final item in _items) {
        final res = await widget.api.getJson('$baseUrl/${item.id}/simulate');
        final list = (res['data'] ?? []) as List;

        for (final row in list) {
          final simItem = FeeSimItem.fromJson(row as Map<String, dynamic>);
          if (simItem.userId == null) continue;

          final key = simItem.userId!;
          final existing = agg[key];

          if (existing == null) {
            agg[key] = simItem;
          } else {
            agg[key] = FeeSimItem(
              id: existing.id,
              userId: existing.userId,
              nama: existing.nama,
              fotoUrl: existing.fotoUrl ?? simItem.fotoUrl,
              percent: existing.percent + simItem.percent,
              nominal: existing.nominal + simItem.nominal,
              bankNama: existing.bankNama ?? simItem.bankNama,
              noRekening: existing.noRekening ?? simItem.noRekening,
              atasNama: existing.atasNama ?? simItem.atasNama,
            );
          }
          grandTotal += simItem.nominal;
        }
      }

      final listAgg =
          agg.values.toList()..sort((a, b) => b.nominal.compareTo(a.nominal));

      _globalItems = listAgg;
      _globalTotalNominal = grandTotal;
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
            api: widget.api,
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
      final url =
          widget.isAddon
              ? '$kFeeAddonRulesUrl/$id/recalc'
              : '$kFeeRulesUrl/$id/recalc';
      await widget.api.postJson(url, {});
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
          (_) => _RoundedDialog(
            width: R.dialogWidth(context, max: 560),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _RBtn(
                          filled: false,
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RBtn(
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
        final url =
            widget.isAddon
                ? '$kFeeAddonRulesUrl/${r.id}'
                : '$kFeeRulesUrl/${r.id}';
        await widget.api.deleteJson(url);
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
    final itemIcon =
        widget.isAddon
            ? Icons.extension_outlined
            : Icons.medical_services_outlined;
    final itemColor = widget.isAddon ? kAddon : kPrimary;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadItems();
        if (_mode == _SimMode.semuaItem) {
          await _loadGlobalSummary();
        }
      },
      child: ListView(
        padding: pad,
        children: [

          _MiniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih $itemLabel untuk mengatur penerima fee:',
                  style: const TextStyle(
                    color: kTextSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<int>(
                  value: _selectedId,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  decoration: fieldDeco(
                    hint: 'Pilih $itemLabel',
                    prefixIcon: Icon(itemIcon),
                  ),
                  items:
                      _items.map((i) {
                        return DropdownMenuItem<int>(
                          value: i.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              if ((i.gambarUrl ?? '').isNotEmpty) ...[
                                AppCachedImage(
                                  imageUrl: i.gambarUrl,
                                  width: 28,
                                  height: 28,
                                  borderRadius: BorderRadius.circular(8),
                                  fit: BoxFit.cover,
                                  errorWidget: const SizedBox(width: 28, height: 28),
                                ),
                                const SizedBox(width: 10),
                              ] else ...[
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: itemColor.withOpacity(.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    itemIcon,
                                    size: 16,
                                    color: itemColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  '${i.nama} • ${formatRupiah(i.hargaFix)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: kText),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  selectedItemBuilder: (context) {
                    return _items.map<Widget>((i) {
                      return Row(
                        children: [
                          if ((i.gambarUrl ?? '').isNotEmpty) ...[
                            AppCachedImage(
                              imageUrl: i.gambarUrl,
                              width: 24,
                              height: 24,
                              borderRadius: BorderRadius.circular(8),
                              fit: BoxFit.cover,
                              errorWidget: Icon(itemIcon, size: 16, color: itemColor),
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            Icon(itemIcon, size: 18, color: itemColor),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              i.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: kText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                  onChanged:
                      _loading
                          ? null
                          : (v) async {
                            setState(() => _selectedId = v);
                            await _loadRules();
                          },
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniChip(
                      text: 'Aktif: $_activeCount orang',
                      icon: Icons.people_alt_outlined,
                      color: itemColor,
                    ),
                    _MiniChip(
                      text: 'Total %: ${_sumPercent.toStringAsFixed(2)}%',
                      icon: Icons.percent,
                      color: itemColor,
                    ),
                    if (item != null)
                      _MiniChip(
                        text: 'Harga: ${formatRupiah(item.hargaFix)}',
                        icon: Icons.payments_outlined,
                        color: itemColor,
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                if (R.isPhone(context)) ...[
                  _RBtn(
                    filled: false,
                    onPressed: _loading ? null : _recalc,
                    icon: Icons.calculate,
                    color: itemColor,
                    child: const Text('Bagi Ulang %'),
                  ),
                  const SizedBox(height: 10),
                  _RBtn(
                    filled: true,
                    onPressed: _loading ? null : () => _openForm(),
                    icon: Icons.add,
                    color: itemColor,
                    child: const Text('Tambah Penerima'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _RBtn(
                          filled: false,
                          onPressed: _loading ? null : _recalc,
                          icon: Icons.calculate,
                          color: itemColor,
                          child: const Text('Bagi Ulang %'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RBtn(
                          filled: true,
                          onPressed: _loading ? null : () => _openForm(),
                          icon: Icons.add,
                          color: itemColor,
                          child: const Text('Tambah Penerima'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          _MiniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistik Distribusi Fee',
                  style: TextStyle(
                    color: kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('Per ${itemLabel.capitalize()}'),
                      selected: _mode == _SimMode.perItem,
                      onSelected: (v) {
                        if (!v) return;
                        setState(() => _mode = _SimMode.perItem);
                      },
                    ),
                    ChoiceChip(
                      label: Text(
                        'Semua ${itemLabel.capitalize()} (Leaderboard)',
                      ),
                      selected: _mode == _SimMode.semuaItem,
                      onSelected: (v) async {
                        if (!v) return;
                        setState(() => _mode = _SimMode.semuaItem);
                        if (_globalItems.isEmpty && !_globalLoading) {
                          await _loadGlobalSummary();
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Bar'),
                      selected: _chartType == _ChartType.bar,
                      onSelected: (v) {
                        if (!v) return;
                        setState(() => _chartType = _ChartType.bar);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Pie'),
                      selected: _chartType == _ChartType.pie,
                      onSelected: (v) {
                        if (!v) return;
                        setState(() => _chartType = _ChartType.pie);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Gunung'),
                      selected: _chartType == _ChartType.area,
                      onSelected: (v) {
                        if (!v) return;
                        setState(() => _chartType = _ChartType.area);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (_mode == _SimMode.perItem)
                  _buildChartSection(
                    loading: _loading,
                    error: _error,
                    items: chartItems,
                    totalNominal: totalNominal,
                    isGlobal: false,
                  )
                else
                  _buildChartSection(
                    loading: _globalLoading,
                    error: _globalError,
                    items: _globalItems,
                    totalNominal: _globalTotalNominal,
                    isGlobal: true,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (_mode == _SimMode.perItem) ...[
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorBox(message: _error!)
            else if (_rules.isEmpty)
              _HintBox(
                text:
                    'Belum ada penerima fee untuk $itemLabel ini. Klik "Tambah Penerima".',
              )
            else
              ..._rules.map(
                (r) => _RecipientCard(
                  rule: r,
                  itemHargaFix: item?.hargaFix ?? 0,
                  onEdit: () => _openForm(existing: r),
                  onDelete: () => _confirmDelete(r),
                ),
              ),
          ] else ...[
            if (_globalLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_globalError != null)
              _ErrorBox(message: _globalError!)
            else if (_globalItems.isEmpty)
              const _HintBox(text: 'Belum ada data leaderboard.')
            else ...[
              Text(
                'Leaderboard Penerima Fee (semua $itemLabel)',
                style: const TextStyle(
                  color: kText,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_globalItems.length, (i) {
                final x = _globalItems[i];
                return _LeaderboardCard(item: x, rank: i + 1);
              }),
            ],
          ],

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildChartSection({
    required bool loading,
    required String? error,
    required List<FeeSimItem> items,
    required num totalNominal,
    required bool isGlobal,
  }) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (error != null) {
      return _ErrorBox(message: error);
    }
    if (items.isEmpty) {
      return _HintBox(
        text:
            isGlobal
                ? 'Belum ada data fee global untuk ditampilkan.'
                : 'Belum ada penerima fee aktif.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniChip(
              text: 'Total dibagi: ${formatRupiah(totalNominal)}',
              icon: Icons.summarize_outlined,
            ),
            _MiniChip(
              text: 'Penerima: ${items.length}',
              icon: Icons.people_alt_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: FeeChartSwitcher(
            items: items,
            totalNominal: totalNominal,
            chartType: _chartType,
            isGlobal: isGlobal,
          ),
        ),
      ],
    );
  }
}

class _RecipientCard extends StatefulWidget {
  final FeeRule rule;
  final num itemHargaFix;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecipientCard({
    required this.rule,
    required this.itemHargaFix,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_RecipientCard> createState() => _RecipientCardState();
}

class _RecipientCardState extends State<_RecipientCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.rule;
    final badgeColor = r.isActive ? kSuccess : kDanger;
    final num nominal =
        r.isActive ? (widget.itemHargaFix * (r.percent / 100)) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _avatarCircle(
                  url: r.fotoUrl,
                  fallback: r.userId != null ? Icons.person : Icons.badge,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.namaPenerima,
                        style: const TextStyle(
                          color: kText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MiniChip(
                            text: r.isActive ? 'Aktif' : 'Nonaktif',
                            color: badgeColor,
                            icon:
                                r.isActive
                                    ? Icons.check_circle_outline
                                    : Icons.block_outlined,
                          ),
                          _MiniChip(
                            text: 'Share: ${r.percent.toStringAsFixed(4)}%',
                            icon: Icons.percent,
                          ),
                          InkWell(
                            onTap: () => setState(() => _open = !_open),
                            borderRadius: BorderRadius.circular(100),
                            child: _MiniChip(
                              text: _open ? 'Tutup nominal' : 'Lihat nominal',
                              icon:
                                  _open ? Icons.expand_less : Icons.expand_more,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit, color: kTextSub),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: kTextSub),
                  tooltip: 'Nonaktifkan',
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState:
                  _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: kBorder, height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniChip(
                          text: 'Harga: ${formatRupiah(widget.itemHargaFix)}',
                          icon: Icons.payments_outlined,
                        ),
                        _MiniChip(
                          text: 'Nominal: ${formatRupiah(nominal)}',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if ((r.noHpPenerima ?? '').isNotEmpty ||
                        (r.emailPenerima ?? '').isNotEmpty)
                      Text(
                        '${r.noHpPenerima ?? '-'} • ${r.emailPenerima ?? '-'}',
                        style: const TextStyle(color: kTextSub),
                      ),
                    if ((r.bankNama ?? '').isNotEmpty ||
                        (r.noRekening ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${r.bankNama ?? '-'} • ${r.noRekening ?? '-'}',
                        style: TextStyle(color: kTextSub.withOpacity(0.9)),
                      ),
                      if ((r.atasNamaRekening ?? '').isNotEmpty)
                        Text(
                          'a/n ${r.atasNamaRekening}',
                          style: TextStyle(color: kTextSub.withOpacity(0.9)),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final FeeSimItem item;
  final int rank;

  const _LeaderboardCard({super.key, required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        rank == 1
            ? Colors.amber.shade600
            : rank == 2
            ? Colors.blueGrey.shade400
            : rank == 3
            ? Colors.brown.shade400
            : kPrimary.withOpacity(0.15);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _avatarCircle(url: item.fotoUrl, fallback: Icons.person, radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  style: const TextStyle(
                    color: kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Total: ${formatRupiah(item.nominal)}',
                  style: const TextStyle(color: kTextSub, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.percent.toStringAsFixed(2)}%',
            style: const TextStyle(
              color: kTextSub,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

/* ===========================================================
   THEME (PUTIH)
=========================================================== */

const Color kBg = Color(0xFFF7F8FA);
const Color kCard = Colors.white;
const Color kBorder = Color(0xFFE5E7EB);
const Color kPrimary = Color(0xFF2563EB);
const Color kText = Color(0xFF111827);
const Color kTextSub = Color(0xFF6B7280);
const Color kDanger = Color(0xFFDC2626);
const Color kSuccess = Color(0xFF16A34A);
const Color kAddon = Color(0xFF7C3AED); // warna untuk addon

/* ===========================================================
   CONFIG
=========================================================== */

const String kBaseUrl = 'http://192.168.1.6:8000';
String get kApiBase => '$kBaseUrl/api';

// Endpoints LAYANAN
String get kFeeLayananUrl => '$kApiBase/admin/fee/layanan';
String get kFeeRulesUrl => '$kApiBase/admin/fee/rules';

// Endpoints ADDON
String get kFeeAddonsUrl => '$kApiBase/admin/fee/addons';
String get kFeeAddonRulesUrl => '$kApiBase/admin/fee/addon-rules';

// Misc
String get kFeeUsersUrl => '$kApiBase/admin/fee/users';
String get kFeeCreateUserUrl => '$kApiBase/admin/fee/create-user';
String get kRolesUrl => '$kApiBase/admin/roles';

/* ===========================================================
   RESPONSIVE HELPERS
=========================================================== */

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

/* ===========================================================
   HELPERS
=========================================================== */

String? resolveMediaUrl(dynamic raw) {
  final s = (raw ?? '').toString().trim();
  if (s.isEmpty) return null;
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  if (s.startsWith('/storage/')) return '$kBaseUrl$s';
  if (s.startsWith('storage/')) return '$kBaseUrl/$s';
  return '$kBaseUrl/storage/$s';
}

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

String formatRupiah(num value) {
  final v = value.round();
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromEnd = s.length - i;
    buf.write(s[i]);
    if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
      buf.write('.');
    }
  }
  return 'Rp ${buf.toString()}';
}

num parseNum(dynamic x) {
  if (x == null) return 0;
  if (x is num) return x;
  return num.tryParse(x.toString()) ?? 0;
}

bool parseBool(dynamic x) {
  if (x is bool) return x;
  if (x is num) return x != 0;
  if (x is String) return x == '1' || x.toLowerCase() == 'true';
  return false;
}

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

/* ===========================================================
   API CLIENT
=========================================================== */

class ApiClient {
  Future<String?> _getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('auth_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getJson(String url, {Map<String, String>? query}) async {
    final uri = Uri.parse(url).replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers());
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (body ?? {}) as Map<String, dynamic>;
    }
    final err = _extractError(body) ?? 'HTTP ${res.statusCode}';
    throw err;
  }

  Future<Map<String, dynamic>> postJson(String url, Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (body ?? {}) as Map<String, dynamic>;
    }
    final err = _extractError(body) ?? 'HTTP ${res.statusCode}';
    throw err;
  }

  Future<Map<String, dynamic>> putJson(String url, Map<String, dynamic> payload) async {
    final res = await http.put(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (body ?? {}) as Map<String, dynamic>;
    }
    final err = _extractError(body) ?? 'HTTP ${res.statusCode}';
    throw err;
  }

  Future<Map<String, dynamic>> deleteJson(String url) async {
    final res = await http.delete(Uri.parse(url), headers: await _headers());
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (body ?? {}) as Map<String, dynamic>;
    }
    final err = _extractError(body) ?? 'HTTP ${res.statusCode}';
    throw err;
  }

  String? _extractError(dynamic body) {
    try {
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
      if (body is Map && body['errors'] != null) {
        final errs = body['errors'];
        if (errs is Map && errs.isNotEmpty) {
          final firstKey = errs.keys.first;
          final firstVal = errs[firstKey];
          if (firstVal is List && firstVal.isNotEmpty) {
            return firstVal.first.toString();
          }
          return '$firstKey: $firstVal';
        }
      }
    } catch (_) {}
    return null;
  }
}

/* ===========================================================
   MODELS
=========================================================== */

class Layanan {
  final int id;
  final String nama;
  final num hargaFix;
  final String? gambarUrl;

  Layanan({required this.id, required this.nama, required this.hargaFix, required this.gambarUrl});

  factory Layanan.fromJson(Map<String, dynamic> j) => Layanan(
        id: (j['id'] as num).toInt(),
        nama: (j['nama_layanan'] ?? j['nama'] ?? '').toString(),
        hargaFix: parseNum(j['harga_fix']),
        gambarUrl: resolveMediaUrl(j['gambar_url'] ?? j['gambar']),
      );
}

class Addon {
  final int id;
  final String nama;
  final num hargaFix;
  final String? gambarUrl;

  Addon({required this.id, required this.nama, required this.hargaFix, required this.gambarUrl});

  factory Addon.fromJson(Map<String, dynamic> j) => Addon(
        id: (j['id'] as num).toInt(),
        nama: (j['nama_addon'] ?? j['nama'] ?? '').toString(),
        hargaFix: parseNum(j['harga_fix']),
        gambarUrl: resolveMediaUrl(j['gambar_url'] ?? j['gambar']),
      );
}

class RoleOption {
  final int id;
  final String name;
  final String slug;

  RoleOption({required this.id, required this.name, required this.slug});

  factory RoleOption.fromJson(Map<String, dynamic> j) => RoleOption(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
      );
}

class SelectableUser {
  final int id;
  final String role;
  final String email;
  final String displayName;
  final String? noHp;
  final String? fotoUrl;

  SelectableUser({
    required this.id,
    required this.role,
    required this.email,
    required this.displayName,
    required this.noHp,
    required this.fotoUrl,
  });

  factory SelectableUser.fromJson(Map<String, dynamic> j) => SelectableUser(
        id: (j['id'] as num).toInt(),
        role: (j['role'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        displayName: (j['display_name'] ?? j['name'] ?? '').toString(),
        noHp: j['no_hp']?.toString(),
        fotoUrl: resolveMediaUrl(j['foto_url'] ?? j['avatar_url'] ?? j['foto']),
      );
}

class FeeRule {
  final int id;
  final int? layananId;
  final int? addonId;
  final int? userId;
  final String namaPenerima;
  final String? emailPenerima;
  final String? noHpPenerima;
  final String? bankNama;
  final String? bankKode;
  final String? noRekening;
  final String? atasNamaRekening;
  final num percent;
  final bool isActive;
  final String? fotoUrl;

  FeeRule({
    required this.id,
    this.layananId,
    this.addonId,
    required this.userId,
    required this.namaPenerima,
    required this.emailPenerima,
    required this.noHpPenerima,
    required this.bankNama,
    required this.bankKode,
    required this.noRekening,
    required this.atasNamaRekening,
    required this.percent,
    required this.isActive,
    required this.fotoUrl,
  });

  factory FeeRule.fromJson(Map<String, dynamic> j) {
    final user = (j['user'] is Map) ? (j['user'] as Map<String, dynamic>) : null;
    final rawFoto = j['foto_url'] ??
        j['avatar_url'] ??
        j['foto'] ??
        user?['foto_url'] ??
        user?['avatar_url'] ??
        user?['foto'] ??
        user?['gambar'] ??
        user?['photo'];

    return FeeRule(
      id: (j['id'] as num).toInt(),
      layananId: j['layanan_id'] == null ? null : (j['layanan_id'] as num).toInt(),
      addonId: j['addon_id'] == null ? null : (j['addon_id'] as num).toInt(),
      userId: j['user_id'] == null ? null : (j['user_id'] as num).toInt(),
      namaPenerima: (j['nama_penerima'] ?? '').toString(),
      emailPenerima: j['email_penerima']?.toString(),
      noHpPenerima: j['no_hp_penerima']?.toString(),
      bankNama: j['bank_nama']?.toString(),
      bankKode: j['bank_kode']?.toString(),
      noRekening: j['no_rekening']?.toString(),
      atasNamaRekening: j['atas_nama_rekening']?.toString(),
      percent: parseNum(j['percent']),
      isActive: parseBool(j['is_active']),
      fotoUrl: resolveMediaUrl(rawFoto),
    );
  }
}

class FeeSimItem {
  final int id;
  final int? userId;
  final String nama;
  final String? fotoUrl;
  final num percent;
  final num nominal;
  final String? bankNama;
  final String? noRekening;
  final String? atasNama;

  FeeSimItem({
    required this.id,
    required this.userId,
    required this.nama,
    required this.fotoUrl,
    required this.percent,
    required this.nominal,
    required this.bankNama,
    required this.noRekening,
    required this.atasNama,
  });

  factory FeeSimItem.fromJson(Map<String, dynamic> j) => FeeSimItem(
        id: (j['id'] as num).toInt(),
        userId: j['user_id'] == null ? null : (j['user_id'] as num).toInt(),
        nama: (j['nama_penerima'] ?? '').toString(),
        fotoUrl: resolveMediaUrl(j['foto_url'] ?? j['avatar_url'] ?? j['foto']),
        percent: parseNum(j['percent']),
        nominal: parseNum(j['nominal']),
        bankNama: j['bank_nama']?.toString(),
        noRekening: j['no_rekening']?.toString(),
        atasNama: j['atas_nama_rekening']?.toString(),
      );
}

enum _SimMode { perItem, semuaItem }
enum _ChartType { bar, pie, area }

/* ===========================================================
   SMALL UI HELPERS
=========================================================== */

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
          Text(text, style: const TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.w700)),
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
      child: Text(text, style: const TextStyle(color: kTextSub, fontWeight: FontWeight.w800)),
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
      child: Text(message, style: const TextStyle(color: kText, fontWeight: FontWeight.w700)),
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
      child: Text(text, style: const TextStyle(color: kTextSub, fontWeight: FontWeight.w600)),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _MiniCard({required this.child, this.padding = const EdgeInsets.all(14), this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6)),
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

  const _RoundedDialog({required this.child, this.width, this.height, this.radius = 18});

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

Widget _avatarCircle({required String? url, required IconData fallback, double radius = 22}) {
  if (url == null || url.trim().isEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: kPrimary.withOpacity(0.10),
      child: Icon(fallback, color: kPrimary),
    );
  }

  return CircleAvatar(
    radius: radius,
    backgroundColor: kPrimary.withOpacity(0.10),
    child: ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(fallback, color: kPrimary),
      ),
    ),
  );
}

/* ===========================================================
   PAGE UTAMA
=========================================================== */

class KelolaFeePage extends StatefulWidget {
  const KelolaFeePage({super.key});

  @override
  State<KelolaFeePage> createState() => _KelolaFeePageState();
}

class _KelolaFeePageState extends State<KelolaFeePage> with SingleTickerProviderStateMixin {
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
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary).copyWith(primary: kPrimary),
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
          title: const Text('Kelola Fee / Komisi', style: TextStyle(fontWeight: FontWeight.w800)),
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

/* ===========================================================
   TAB GENERIK (LAYANAN / ADDON)
=========================================================== */

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
      final res = await widget.api.getJson(url, query: {'per_page': '200', 'aktif': '1'});
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

      final res = await widget.api.getJson(url, query: {
        idKey: _selectedId.toString(),
        'per_page': '200',
        'aktif': '1',
      });

      final pageObj = (res['data'] is Map) ? Map<String, dynamic>.from(res['data']) : <String, dynamic>{};
      final rawList = pageObj['data'];
      final list = (rawList is List) ? rawList : const [];

      _rules = list.where((e) => e is Map).map((e) => FeeRule.fromJson(Map<String, dynamic>.from(e as Map))).toList();

      final meta = (res['meta'] is Map) ? Map<String, dynamic>.from(res['meta']) : <String, dynamic>{};

      _sumPercent = parseNum(meta['sum_percent_active']);
      _activeCount = (meta['active_count'] ?? 0) is num ? (meta['active_count'] as num).toInt() : 0;
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

      final listAgg = agg.values.toList()..sort((a, b) => b.nominal.compareTo(a.nominal));

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
      builder: (_) => _FeeRuleFormDialog(
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
      final url = widget.isAddon ? '$kFeeAddonRulesUrl/$id/recalc' : '$kFeeRulesUrl/$id/recalc';
      await widget.api.postJson(url, {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Persentase dibagi ulang (100% dibagi rata).')),
        );
      }
      await _loadRules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmDelete(FeeRule r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _RoundedDialog(
        width: R.dialogWidth(context, max: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nonaktifkan Penerima?', style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text('Penerima "${r.namaPenerima}" akan dinonaktifkan.', style: const TextStyle(color: kTextSub)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _RBtn(filled: false, onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RBtn(filled: true, color: kDanger, onPressed: () => Navigator.pop(context, true), child: const Text('Nonaktifkan')),
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
        final url = widget.isAddon ? '$kFeeAddonRulesUrl/${r.id}' : '$kFeeRulesUrl/${r.id}';
        await widget.api.deleteJson(url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penerima dinonaktifkan.')));
        }
        await _loadRules();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
    final itemIcon = widget.isAddon ? Icons.extension_outlined : Icons.medical_services_outlined;
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
          // CARD PILIH ITEM
          _MiniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih $itemLabel untuk mengatur penerima fee:', style: const TextStyle(color: kTextSub, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                
                DropdownButtonFormField<int>(
                  value: _selectedId,
                  dropdownColor: Colors.white,
                  decoration: fieldDeco(hint: 'Pilih $itemLabel', prefixIcon: Icon(itemIcon)),
                  items: _items.map((i) {
                    return DropdownMenuItem<int>(
                      value: i.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((i.gambarUrl ?? '').isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(i.gambarUrl!, width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 28, height: 28)),
                            ),
                            const SizedBox(width: 10),
                          ],
                          SizedBox(
                            width: 260,
                            child: Text('${i.nama} • ${formatRupiah(i.hargaFix)}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: kText)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _loading ? null : (v) async {
                    setState(() => _selectedId = v);
                    await _loadRules();
                  },
                ),
                
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniChip(text: 'Aktif: $_activeCount orang', icon: Icons.people_alt_outlined, color: itemColor),
                    _MiniChip(text: 'Total %: ${_sumPercent.toStringAsFixed(2)}%', icon: Icons.percent, color: itemColor),
                    if (item != null) _MiniChip(text: 'Harga: ${formatRupiah(item.hargaFix)}', icon: Icons.payments_outlined, color: itemColor),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                if (R.isPhone(context)) ...[
                  _RBtn(filled: false, onPressed: _loading ? null : _recalc, icon: Icons.calculate, color: itemColor, child: const Text('Bagi Ulang %')),
                  const SizedBox(height: 10),
                  _RBtn(filled: true, onPressed: _loading ? null : () => _openForm(), icon: Icons.add, color: itemColor, child: const Text('Tambah Penerima')),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: _RBtn(filled: false, onPressed: _loading ? null : _recalc, icon: Icons.calculate, color: itemColor, child: const Text('Bagi Ulang %'))),
                      const SizedBox(width: 10),
                      Expanded(child: _RBtn(filled: true, onPressed: _loading ? null : () => _openForm(), icon: Icons.add, color: itemColor, child: const Text('Tambah Penerima'))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 14),
          
          // CARD CHART
          _MiniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statistik Distribusi Fee', style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w800)),
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
                      label: Text('Semua ${itemLabel.capitalize()} (Leaderboard)'),
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
                    ChoiceChip(label: const Text('Bar'), selected: _chartType == _ChartType.bar, onSelected: (v) { if (!v) return; setState(() => _chartType = _ChartType.bar); }),
                    ChoiceChip(label: const Text('Pie'), selected: _chartType == _ChartType.pie, onSelected: (v) { if (!v) return; setState(() => _chartType = _ChartType.pie); }),
                    ChoiceChip(label: const Text('Gunung'), selected: _chartType == _ChartType.area, onSelected: (v) { if (!v) return; setState(() => _chartType = _ChartType.area); }),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                if (_mode == _SimMode.perItem)
                  _buildChartSection(loading: _loading, error: _error, items: chartItems, totalNominal: totalNominal, isGlobal: false)
                else
                  _buildChartSection(loading: _globalLoading, error: _globalError, items: _globalItems, totalNominal: _globalTotalNominal, isGlobal: true),
              ],
            ),
          ),
          
          const SizedBox(height: 14),
          
          // LIST
          if (_mode == _SimMode.perItem) ...[
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_error != null)
              _ErrorBox(message: _error!)
            else if (_rules.isEmpty)
              _HintBox(text: 'Belum ada penerima fee untuk $itemLabel ini. Klik "Tambah Penerima".')
            else
              ..._rules.map((r) => _RecipientCard(rule: r, itemHargaFix: item?.hargaFix ?? 0, onEdit: () => _openForm(existing: r), onDelete: () => _confirmDelete(r))),
          ] else ...[
            if (_globalLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_globalError != null)
              _ErrorBox(message: _globalError!)
            else if (_globalItems.isEmpty)
              const _HintBox(text: 'Belum ada data leaderboard.')
            else ...[
              Text('Leaderboard Penerima Fee (semua $itemLabel)', style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w800)),
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

  Widget _buildChartSection({required bool loading, required String? error, required List<FeeSimItem> items, required num totalNominal, required bool isGlobal}) {
    if (loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    if (error != null) {
      return _ErrorBox(message: error);
    }
    if (items.isEmpty) {
      return _HintBox(text: isGlobal ? 'Belum ada data fee global untuk ditampilkan.' : 'Belum ada penerima fee aktif.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniChip(text: 'Total dibagi: ${formatRupiah(totalNominal)}', icon: Icons.summarize_outlined),
            _MiniChip(text: 'Penerima: ${items.length}', icon: Icons.people_alt_outlined),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: _FeeChartSwitcher(items: items, totalNominal: totalNominal, chartType: _chartType, isGlobal: isGlobal),
        ),
      ],
    );
  }
}

/* ===========================================================
   CARD PENERIMA
=========================================================== */

class _RecipientCard extends StatefulWidget {
  final FeeRule rule;
  final num itemHargaFix;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecipientCard({required this.rule, required this.itemHargaFix, required this.onEdit, required this.onDelete});

  @override
  State<_RecipientCard> createState() => _RecipientCardState();
}

class _RecipientCardState extends State<_RecipientCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.rule;
    final badgeColor = r.isActive ? kSuccess : kDanger;
    final num nominal = r.isActive ? (widget.itemHargaFix * (r.percent / 100)) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _avatarCircle(url: r.fotoUrl, fallback: r.userId != null ? Icons.person : Icons.badge, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.namaPenerima, style: const TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MiniChip(text: r.isActive ? 'Aktif' : 'Nonaktif', color: badgeColor, icon: r.isActive ? Icons.check_circle_outline : Icons.block_outlined),
                          _MiniChip(text: 'Share: ${r.percent.toStringAsFixed(4)}%', icon: Icons.percent),
                          InkWell(
                            onTap: () => setState(() => _open = !_open),
                            borderRadius: BorderRadius.circular(100),
                            child: _MiniChip(text: _open ? 'Tutup nominal' : 'Lihat nominal', icon: _open ? Icons.expand_less : Icons.expand_more),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: widget.onEdit, icon: const Icon(Icons.edit, color: kTextSub), tooltip: 'Edit'),
                IconButton(onPressed: widget.onDelete, icon: const Icon(Icons.delete_outline, color: kTextSub), tooltip: 'Nonaktifkan'),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
                        _MiniChip(text: 'Harga: ${formatRupiah(widget.itemHargaFix)}', icon: Icons.payments_outlined),
                        _MiniChip(text: 'Nominal: ${formatRupiah(nominal)}', icon: Icons.account_balance_wallet_outlined),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if ((r.noHpPenerima ?? '').isNotEmpty || (r.emailPenerima ?? '').isNotEmpty)
                      Text('${r.noHpPenerima ?? '-'} • ${r.emailPenerima ?? '-'}', style: const TextStyle(color: kTextSub)),
                    if ((r.bankNama ?? '').isNotEmpty || (r.noRekening ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('${r.bankNama ?? '-'} • ${r.noRekening ?? '-'}', style: TextStyle(color: kTextSub.withOpacity(0.9))),
                      if ((r.atasNamaRekening ?? '').isNotEmpty) Text('a/n ${r.atasNamaRekening}', style: TextStyle(color: kTextSub.withOpacity(0.9))),
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

/* ===========================================================
   LEADERBOARD CARD
=========================================================== */

class _LeaderboardCard extends StatelessWidget {
  final FeeSimItem item;
  final int rank;

  const _LeaderboardCard({super.key, required this.item, required this.rank});

  @override
  Widget build(BuildContext context) {
    final badgeColor = rank == 1
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(999)),
            child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          _avatarCircle(url: item.fotoUrl, fallback: Icons.person, radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nama, style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Total: ${formatRupiah(item.nominal)}', style: const TextStyle(color: kTextSub, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${item.percent.toStringAsFixed(2)}%', style: const TextStyle(color: kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/* ===========================================================
   CHART SWITCHER
=========================================================== */

class _FeeChartSwitcher extends StatelessWidget {
  final List<FeeSimItem> items;
  final num totalNominal;
  final _ChartType chartType;
  final bool isGlobal;

  const _FeeChartSwitcher({required this.items, required this.totalNominal, required this.chartType, required this.isGlobal});

  @override
  Widget build(BuildContext context) {
    Widget chart;
    switch (chartType) {
      case _ChartType.bar:
        chart = _FeeBarChart(items: items, totalNominal: totalNominal);
        break;
      case _ChartType.pie:
        chart = _FeePieChart(items: items, totalNominal: totalNominal);
        break;
      case _ChartType.area:
        chart = _FeeAreaChart(items: items, totalNominal: totalNominal);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isGlobal ? 'Grafik Distribusi Fee Global' : 'Grafik Distribusi Fee per Penerima', style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Expanded(child: chart),
      ],
    );
  }
}

/* ===========================================================
   BAR CHART
=========================================================== */

class _FeeBarChart extends StatelessWidget {
  final List<FeeSimItem> items;
  final num totalNominal;

  const _FeeBarChart({required this.items, required this.totalNominal});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    num maxNominal = 0;
    for (final i in items) {
      if (i.nominal > maxNominal) maxNominal = i.nominal;
    }
    if (maxNominal <= 0) maxNominal = 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barMaxWidth = constraints.maxWidth - 80;

        return SingleChildScrollView(
          child: Column(
            children: items.map((e) {
              final ratio = e.nominal <= 0 ? 0.0 : (e.nominal / maxNominal).clamp(0, 1).toDouble();
              final barWidth = (barMaxWidth * ratio).clamp(10, barMaxWidth).toDouble();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(e.nama, style: const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text('${e.percent.toStringAsFixed(2)}%', style: const TextStyle(color: kTextSub, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(height: 12, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(999))),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                height: 12,
                                width: barWidth,
                                decoration: BoxDecoration(color: kPrimary.withOpacity(0.85), borderRadius: BorderRadius.circular(999)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(formatRupiah(e.nominal), style: const TextStyle(color: kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/* ===========================================================
   PIE CHART
=========================================================== */

class _FeePieChart extends StatelessWidget {
  final List<FeeSimItem> items;
  final num totalNominal;

  const _FeePieChart({required this.items, required this.totalNominal});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty || totalNominal <= 0) {
      return const Center(child: Text('Tidak ada data untuk pie chart.', style: TextStyle(color: kTextSub)));
    }

    final sections = items.map((e) {
      final value = e.nominal.toDouble();
      return PieChartSectionData(
        value: value,
        title: '${e.percent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(PieChartData(sections: sections, sectionsSpace: 1, centerSpaceRadius: 30)),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((e) {
                final persen = e.nominal <= 0 || totalNominal <= 0 ? 0.0 : (e.nominal / totalNominal * 100);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: kPrimary.withOpacity(0.8), borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 6),
                      Expanded(child: Text(e.nama, style: const TextStyle(color: kText, fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 6),
                      Text('${persen.toStringAsFixed(1)}%', style: const TextStyle(color: kTextSub, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/* ===========================================================
   AREA CHART
=========================================================== */

class _FeeAreaChart extends StatelessWidget {
  final List<FeeSimItem> items;
  final num totalNominal;

  const _FeeAreaChart({required this.items, required this.totalNominal});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Tidak ada data untuk grafik gunung.', style: TextStyle(color: kTextSub)));
    }

    double maxY = 0;
    for (final i in items) {
      if (i.nominal > maxY) maxY = i.nominal.toDouble();
    }
    if (maxY <= 0) maxY = 1;

    final spots = <FlSpot>[];
    for (int i = 0; i < items.length; i++) {
      spots.add(FlSpot(i.toDouble(), items[i].nominal.toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8.0, left: 2),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (items.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= items.length) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 4), child: Text('${idx + 1}', style: const TextStyle(color: kTextSub, fontSize: 10)));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 40,
                showTitles: true,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: kTextSub, fontSize: 10)),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [kPrimary.withOpacity(0.35), kPrimary.withOpacity(0.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===========================================================
   USER PICKER DIALOG
=========================================================== */

class _UserPickerDialog extends StatefulWidget {
  final ApiClient api;
  final int itemId;
  
  const _UserPickerDialog({required this.api, required this.itemId});

  @override
  State<_UserPickerDialog> createState() => _UserPickerDialogState();
}

class _UserPickerDialogState extends State<_UserPickerDialog> {
  final _search = TextEditingController();
  bool _loading = false;
  String? _error;
  List<SelectableUser> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.getJson(kFeeUsersUrl, query: {
        'per_page': '20',
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
      });

      final data = (res['data'] ?? {}) as Map<String, dynamic>;
      final list = (data['data'] ?? []) as List;
      _items = list.map((e) => SelectableUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RoundedDialog(
      width: R.dialogWidth(context, max: 720),
      height: R.dialogHeight(context, max: 620),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cari & Pilih User (kecuali pasien)', style: TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(controller: _search, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'Cari nama / email...', prefixIcon: const Icon(Icons.search)), onSubmitted: (_) => _load()),
            const SizedBox(height: 12),
            if (_error != null) _ErrorBox(message: _error!),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const _HintBox(text: 'User tidak ditemukan.')
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(color: kBorder, height: 1),
                          itemBuilder: (_, i) {
                            final u = _items[i];
                            return ListTile(
                              onTap: () => Navigator.pop(context, u),
                              leading: _avatarCircle(url: u.fotoUrl, fallback: Icons.person, radius: 20),
                              title: Text(u.displayName, style: const TextStyle(color: kText, fontWeight: FontWeight.w800)),
                              subtitle: Text('${u.role} • ${u.email}${(u.noHp ?? '').isNotEmpty ? ' • ${u.noHp}' : ''}', style: const TextStyle(color: kTextSub)),
                              trailing: const Icon(Icons.chevron_right, color: kTextSub),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _RBtn(filled: false, onPressed: () => Navigator.pop(context), child: const Text('Tutup'))),
                const SizedBox(width: 10),
                Expanded(child: _RBtn(filled: true, onPressed: _loading ? null : _load, icon: Icons.refresh, child: const Text('Cari'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* ===========================================================
   CREATE USER DIALOG
=========================================================== */

class _CreatedUserResult {
  final int userId;
  final String name;
  final String email;
  final String role;
  final String? noHp;

  _CreatedUserResult({required this.userId, required this.name, required this.email, required this.role, required this.noHp});
}

class _CreateUserDialog extends StatefulWidget {
  final ApiClient api;
  final int itemId;
  final bool isAddon;
  final double? percent;

  const _CreateUserDialog({required this.api, required this.itemId, required this.isAddon, required this.percent});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _noHp = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  final _bankNama = TextEditingController();
  final _bankKode = TextEditingController();
  final _noRek = TextEditingController();
  final _atasNama = TextEditingController();

  List<RoleOption> _roleOptions = [];
  RoleOption? _selectedRole;
  bool _loadingRoles = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _noHp.dispose();
    _password.dispose();
    _bankNama.dispose();
    _bankKode.dispose();
    _noRek.dispose();
    _atasNama.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    setState(() => _loadingRoles = true);

    try {
      final res = await widget.api.getJson(kRolesUrl, query: {'per_page': '100'});
      final list = extractList(res);
      _roleOptions = list.map((e) => RoleOption.fromJson(e as Map<String, dynamic>)).toList();

      if (_roleOptions.isNotEmpty) {
        _selectedRole ??= _roleOptions.first;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loadingRoles = false);
    }
  }

  String? _validatePassword(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (s.length < 8) return 'Password minimal 8 karakter.';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(s);
    final hasDigit = RegExp(r'\d').hasMatch(s);
    if (!hasLetter || !hasDigit) return 'Password harus kombinasi huruf dan angka.';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final idKey = widget.isAddon ? 'addon_id' : 'layanan_id';

    final payload = <String, dynamic>{
      idKey: widget.itemId,
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text.trim().isEmpty ? null : _password.text.trim(),
      'role': _selectedRole?.slug,
      'no_hp_penerima': _noHp.text.trim().isEmpty ? null : _noHp.text.trim(),
      'bank_nama': _bankNama.text.trim().isEmpty ? null : _bankNama.text.trim(),
      'bank_kode': _bankKode.text.trim().isEmpty ? null : _bankKode.text.trim(),
      'no_rekening': _noRek.text.trim().isEmpty ? null : _noRek.text.trim(),
      'atas_nama_rekening': _atasNama.text.trim().isEmpty ? null : _atasNama.text.trim(),
      'percent': widget.percent,
    };

    setState(() => _saving = true);
    try {
      final res = await widget.api.postJson(kFeeCreateUserUrl, payload);
      final data = (res['data'] ?? {}) as Map<String, dynamic>;
      final user = (data['user'] ?? {}) as Map<String, dynamic>;

      final result = _CreatedUserResult(
        userId: (user['id'] as num).toInt(),
        name: (user['name'] ?? '').toString(),
        email: (user['email'] ?? '').toString(),
        role: (user['role'] ?? '').toString(),
        noHp: payload['no_hp_penerima'] as String?,
      );

      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemLabel = widget.isAddon ? 'add-on' : 'layanan';

    return _RoundedDialog(
      width: R.dialogWidth(context, max: 760),
      height: R.dialogHeight(context, max: 680),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buat User Baru (Sekaligus jadi penerima fee $itemLabel)', style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                if (_error != null) _ErrorBox(message: _error!),

                const _Label('Nama'),
                TextFormField(
                  controller: _name,
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(hint: 'Nama lengkap', prefixIcon: const Icon(Icons.badge_outlined)),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                if (R.isPhone(context)) ...[
                  const _Label('Email'),
                  TextFormField(
                    controller: _email,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(hint: 'email@domain.com', prefixIcon: const Icon(Icons.email_outlined)),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Email wajib diisi';
                      if (!s.contains('@')) return 'Email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const _Label('No HP (opsional)'),
                  TextFormField(
                    controller: _noHp,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(hint: '08xxxxxxxxxx', prefixIcon: const Icon(Icons.phone_outlined)),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label('Email'),
                            TextFormField(
                              controller: _email,
                              style: const TextStyle(color: kText),
                              decoration: fieldDeco(hint: 'email@domain.com', prefixIcon: const Icon(Icons.email_outlined)),
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'Email wajib diisi';
                                if (!s.contains('@')) return 'Email tidak valid';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label('No HP (opsional)'),
                            TextFormField(
                              controller: _noHp,
                              style: const TextStyle(color: kText),
                              decoration: fieldDeco(hint: '08xxxxxxxxxx', prefixIcon: const Icon(Icons.phone_outlined)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const _Label('Jabatan/Role'),
                _loadingRoles
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator(minHeight: 4))
                    : DropdownButtonFormField<RoleOption>(
                        value: _selectedRole,
                        decoration: fieldDeco(hint: 'Pilih role', prefixIcon: const Icon(Icons.admin_panel_settings_outlined)),
                        items: _roleOptions.map((r) {
                          return DropdownMenuItem<RoleOption>(
                            value: r,
                            child: Text(r.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: _saving ? null : (v) => setState(() => _selectedRole = v),
                        validator: (v) => v == null ? 'Role/jabatan wajib dipilih.' : null,
                      ),

                const SizedBox(height: 12),
                const _Label('Password (opsional)'),
                TextFormField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(hint: 'Kosongkan untuk auto-generate', prefixIcon: const Icon(Icons.lock_outline)).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: kTextSub),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 12),
                const _Label('Rekening (opsional)'),

                if (R.isPhone(context)) ...[
                  TextFormField(controller: _bankNama, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'Bank', prefixIcon: const Icon(Icons.account_balance_outlined))),
                  const SizedBox(height: 12),
                  TextFormField(controller: _bankKode, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'Kode bank', prefixIcon: const Icon(Icons.confirmation_number_outlined))),
                  const SizedBox(height: 12),
                  TextFormField(controller: _noRek, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'No rekening', prefixIcon: const Icon(Icons.numbers_outlined))),
                  const SizedBox(height: 12),
                  TextFormField(controller: _atasNama, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'Atas nama', prefixIcon: const Icon(Icons.badge_outlined))),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _bankNama, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'Bank', prefixIcon: const Icon(Icons.account_balance_outlined)))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _bankKode, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'Kode bank', prefixIcon: const Icon(Icons.confirmation_number_outlined)))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _noRek, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'No rekening', prefixIcon: const Icon(Icons.numbers_outlined)))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _atasNama, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'Atas nama', prefixIcon: const Icon(Icons.badge_outlined)))),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                if (R.isPhone(context)) ...[
                  _RBtn(filled: false, onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal')),
                  const SizedBox(height: 10),
                  _RBtn(
                    filled: true,
                    onPressed: _saving ? null : _submit,
                    child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Buat & Tambah'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(child: _RBtn(filled: false, onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Batal'))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RBtn(
                          filled: true,
                          onPressed: _saving ? null : _submit,
                          child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Buat & Tambah'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ===========================================================
   FEE RULE FORM DIALOG
=========================================================== */

class _FeeRuleFormDialog extends StatefulWidget {
  final ApiClient api;
  final int itemId;
  final bool isAddon;
  final FeeRule? existing;

  const _FeeRuleFormDialog({required this.api, required this.itemId, required this.isAddon, this.existing});

  @override
  State<_FeeRuleFormDialog> createState() => _FeeRuleFormDialogState();
}

class _FeeRuleFormDialogState extends State<_FeeRuleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  SelectableUser? _selectedUser;
  int? _userId;

  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _noHp = TextEditingController();
  final _bankNama = TextEditingController();
  final _bankKode = TextEditingController();
  final _noRek = TextEditingController();
  final _atasNama = TextEditingController();
  final _percent = TextEditingController();

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _userId = e.userId;
      _nama.text = e.namaPenerima;
      _email.text = e.emailPenerima ?? '';
      _noHp.text = e.noHpPenerima ?? '';
      _bankNama.text = e.bankNama ?? '';
      _bankKode.text = e.bankKode ?? '';
      _noRek.text = e.noRekening ?? '';
      _atasNama.text = e.atasNamaRekening ?? '';
      _percent.text = e.percent.toString();
      _isActive = e.isActive;
    } else {
      _isActive = true;
      _percent.text = '';
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _noHp.dispose();
    _bankNama.dispose();
    _bankKode.dispose();
    _noRek.dispose();
    _atasNama.dispose();
    _percent.dispose();
    super.dispose();
  }

  Future<void> _pickUser() async {
    final picked = await showDialog<SelectableUser>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserPickerDialog(api: widget.api, itemId: widget.itemId),
    );
    if (picked == null) return;

    setState(() {
      _selectedUser = picked;
      _userId = picked.id;
      _nama.text = picked.displayName;
      _email.text = picked.email;
      _noHp.text = picked.noHp ?? '';
    });
  }

  Future<void> _openCreateUser() async {
    double? percentVal;
    final ptxt = _percent.text.trim();
    if (ptxt.isNotEmpty) {
      percentVal = double.tryParse(ptxt.replaceAll(',', '.'));
      if (percentVal == null) {
        setState(() => _error = 'Percent tidak valid.');
        return;
      }
    }

    final created = await showDialog<_CreatedUserResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateUserDialog(
        api: widget.api,
        itemId: widget.itemId,
        isAddon: widget.isAddon,
        percent: percentVal,
      ),
    );

    if (created == null) return;

    setState(() {
      _selectedUser = SelectableUser(
        id: created.userId,
        role: created.role,
        email: created.email,
        displayName: created.name,
        noHp: created.noHp,
        fotoUrl: null,
      );
      _userId = created.userId;
      _nama.text = created.name;
      _email.text = created.email;
      _noHp.text = created.noHp ?? '';
    });

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    if (_userId == null) {
      setState(() => _error = 'User wajib dipilih lewat pencarian.');
      return;
    }

    double? percentVal;
    final ptxt = _percent.text.trim();
    if (ptxt.isNotEmpty) {
      percentVal = double.tryParse(ptxt.replaceAll(',', '.'));
      if (percentVal == null) {
        setState(() => _error = 'Percent tidak valid.');
        return;
      }
    }

    final idKey = widget.isAddon ? 'addon_id' : 'layanan_id';

    final payload = <String, dynamic>{
      idKey: widget.itemId,
      'user_id': _userId,
      'bank_nama': _bankNama.text.trim().isEmpty ? null : _bankNama.text.trim(),
      'bank_kode': _bankKode.text.trim().isNotEmpty ? _bankKode.text.trim() : null,
      'no_rekening': _noRek.text.trim().isEmpty ? null : _noRek.text.trim(),
      'atas_nama_rekening': _atasNama.text.trim().isEmpty ? null : _atasNama.text.trim(),
      'percent': percentVal,
      'is_active': _isActive,
    };

    payload.removeWhere((k, v) => v == null);

    setState(() => _saving = true);
    try {
      final baseUrl = widget.isAddon ? kFeeAddonRulesUrl : kFeeRulesUrl;

      if (widget.existing == null) {
        await widget.api.postJson(baseUrl, payload);
      } else {
        await widget.api.putJson('$baseUrl/${widget.existing!.id}', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final itemLabel = widget.isAddon ? 'add-on' : 'layanan';

    return _RoundedDialog(
      width: R.dialogWidth(context, max: 760),
      height: R.dialogHeight(context, max: 740),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit Penerima Fee $itemLabel' : 'Tambah Penerima Fee $itemLabel', style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                if (_error != null) _ErrorBox(message: _error!),
                
                const _Label('Pilih User (wajib)'),
                
                if (R.isPhone(context)) ...[
                  TextFormField(
                    controller: _nama,
                    readOnly: true,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(hint: 'Klik "Cari User" / "Buat User Baru"', prefixIcon: const Icon(Icons.person_outline)),
                    validator: (_) => _userId == null ? 'User wajib dipilih.' : null,
                  ),
                  const SizedBox(height: 10),
                  _RBtn(filled: true, onPressed: _saving ? null : _pickUser, icon: Icons.search, child: const Text('Cari User')),
                  const SizedBox(height: 10),
                  _RBtn(filled: false, onPressed: _saving ? null : _openCreateUser, icon: Icons.person_add_alt_1, child: const Text('Buat User Baru')),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nama,
                          readOnly: true,
                          style: const TextStyle(color: kText),
                          decoration: fieldDeco(hint: 'Klik "Cari User" / "Buat User Baru"', prefixIcon: const Icon(Icons.person_outline)),
                          validator: (_) => _userId == null ? 'User wajib dipilih.' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _RBtn(filled: true, onPressed: _saving ? null : _pickUser, icon: Icons.search, child: const Text('Cari'))),
                      const SizedBox(width: 10),
                      Expanded(child: _RBtn(filled: false, onPressed: _saving ? null : _openCreateUser, icon: Icons.person_add_alt_1, child: const Text('Buat'))),
                    ],
                  ),
                ],
                
                const SizedBox(height: 10),
                if (_selectedUser != null) _HintBox(text: 'Dipilih: ${_selectedUser!.displayName} • ${_selectedUser!.role}'),
                
                const SizedBox(height: 12),
                const _Label('Email (readonly)'),
                TextFormField(controller: _email, readOnly: true, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'email@domain.com', prefixIcon: const Icon(Icons.email_outlined))),
                
                const SizedBox(height: 12),
                const _Label('No HP (readonly)'),
                TextFormField(controller: _noHp, readOnly: true, style: const TextStyle(color: kText), decoration: fieldDeco(hint: '08xxxxxxxxxx', prefixIcon: const Icon(Icons.phone_outlined))),
                
                const SizedBox(height: 12),
                const _Label('Rekening (opsional)'),
                TextFormField(controller: _bankNama, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'Bank (BCA/BRI/...)', prefixIcon: const Icon(Icons.account_balance_outlined))),
                const SizedBox(height: 12),
                TextFormField(controller: _noRek, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'No rekening', prefixIcon: const Icon(Icons.numbers_outlined))),
                const SizedBox(height: 12),
                TextFormField(controller: _atasNama, style: const TextStyle(color: kText), decoration: fieldDeco(hint: 'Atas nama', prefixIcon: const Icon(Icons.badge_outlined))),
                
                const SizedBox(height: 12),
                const _Label('Persentase Fee (%)'),
                TextFormField(
                  controller: _percent,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(hint: 'contoh: 25 atau 12.5', prefixIcon: const Icon(Icons.percent)).copyWith(
                    helperText: 'Total persentase aktif per $itemLabel maksimal 100%',
                    helperStyle: const TextStyle(color: kTextSub),
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return null;
                    final val = double.tryParse(s.replaceAll(',', '.'));
                    if (val == null) return 'Percent tidak valid';
                    if (val < 0 || val > 100) return 'Percent harus 0 - 100';
                    return null;
                  },
                ),
                
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _isActive,
                  onChanged: _saving ? null : (v) => setState(() => _isActive = v),
                  activeColor: kPrimary,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif', style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
                  subtitle: Text(_isActive ? 'Penerima dihitung dalam pembagian %' : 'Tidak ikut pembagian fee', style: const TextStyle(color: kTextSub)),
                ),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _RBtn(filled: false, onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Batal'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RBtn(
                        filled: true,
                        onPressed: _saving ? null : _save,
                        child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(isEdit ? 'Simpan' : 'Tambah'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
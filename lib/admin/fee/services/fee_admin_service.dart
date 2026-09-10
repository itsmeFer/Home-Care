import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';
import 'package:home_care/features/fee_management/presentation/widgets/fee_ui_components.dart';

class FeeRulesResult {
  final List<FeeRule> rules;
  final num sumPercent;
  final int activeCount;

  const FeeRulesResult({
    required this.rules,
    required this.sumPercent,
    required this.activeCount,
  });
}

class FeeGlobalSummary {
  final List<FeeSimItem> items;
  final num totalNominal;

  const FeeGlobalSummary({
    required this.items,
    required this.totalNominal,
  });
}

class FeeAdminService {
  final FeeApiBridge api;

  FeeAdminService({FeeApiBridge? api}) : api = api ?? FeeApiBridge();

  Future<List<dynamic>> fetchItems(bool isAddon) async {
    final url =
        isAddon ? ApiConstants.adminFeeAddons : ApiConstants.adminFeeLayanan;
    final res = await api.getJson(
      url,
      query: {'per_page': '200', 'aktif': '1'},
    );
    final list = extractList(res);

    if (isAddon) {
      return list.map((e) => Addon.fromJson(e)).toList();
    } else {
      return list.map((e) => Layanan.fromJson(e)).toList();
    }
  }

  Future<FeeRulesResult> fetchRules(bool isAddon, int itemId) async {
    final url =
        isAddon ? ApiConstants.adminFeeAddonRules : ApiConstants.adminFeeRules;
    final idKey = isAddon ? 'addon_id' : 'layanan_id';

    final res = await api.getJson(
      url,
      query: {idKey: itemId.toString(), 'per_page': '200', 'aktif': '1'},
    );

    final pageObj =
        (res['data'] is Map)
            ? Map<String, dynamic>.from(res['data'])
            : <String, dynamic>{};
    final rawList = pageObj['data'];
    final list = (rawList is List) ? rawList : const [];

    final rules =
        list
            .whereType<Map>()
            .map((e) => FeeRule.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    final meta =
        (res['meta'] is Map)
            ? Map<String, dynamic>.from(res['meta'])
            : <String, dynamic>{};

    final sumPercent = parseNum(meta['sum_percent_active']);
    final activeCount =
        (meta['active_count'] ?? 0) is num
            ? (meta['active_count'] as num).toInt()
            : 0;

    return FeeRulesResult(
      rules: rules,
      sumPercent: sumPercent,
      activeCount: activeCount,
    );
  }

  Future<FeeGlobalSummary> fetchGlobalSimulation(
    bool isAddon,
    List<dynamic> items,
  ) async {
    if (items.isEmpty) {
      return const FeeGlobalSummary(items: [], totalNominal: 0);
    }

    final Map<int, FeeSimItem> agg = {};
    num grandTotal = 0;

    final baseUrl =
        isAddon ? ApiConstants.adminFeeAddonRules : ApiConstants.adminFeeRules;

    for (final item in items) {
      final res = await api.getJson('$baseUrl/${item.id}/simulate');
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

    return FeeGlobalSummary(items: listAgg, totalNominal: grandTotal);
  }

  Future<void> recalculateSplit(bool isAddon, int itemId) async {
    final baseUrl =
        isAddon ? ApiConstants.adminFeeAddonRules : ApiConstants.adminFeeRules;
    await api.postJson('$baseUrl/$itemId/recalc', {});
  }

  Future<void> deleteRule(bool isAddon, int ruleId) async {
    final baseUrl =
        isAddon ? ApiConstants.adminFeeAddonRules : ApiConstants.adminFeeRules;
    await api.deleteJson('$baseUrl/$ruleId');
  }
}

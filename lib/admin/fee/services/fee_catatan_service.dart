import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';

class FeeCatatanUserData {
  final double totalSemuaLayanan;
  final List<FeeByLayanan> byLayanan;
  final List<FeeTimelinePoint> timeline;
  final List<LeaderboardItem> leaderboard;

  const FeeCatatanUserData({
    required this.totalSemuaLayanan,
    required this.byLayanan,
    required this.timeline,
    required this.leaderboard,
  });

  const FeeCatatanUserData.empty()
      : totalSemuaLayanan = 0,
        byLayanan = const [],
        timeline = const [],
        leaderboard = const [];
}

class FeeCatatanService {
  static Future<List<SimpleUserOption>> searchUsers(String query) async {
    final jsonRes = await ApiClient.get(
      ApiConstants.adminFeeSearchableUsers,
      queryParams: {
        'per_page': 20,
        if (query.trim().isNotEmpty) 'search': query.trim(),
      },
    );

    if (jsonRes is Map && jsonRes['success'] == true) {
      final data = jsonRes['data'] ?? {};
      final list = (data['data'] ?? []) as List;

      return list
          .map((e) =>
              SimpleUserOption.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  static Future<FeeCatatanUserData> fetchCatatanUser({
    required int userId,
    required String range,
    required String status,
    int? layananId,
  }) async {
    final params = <String, dynamic>{
      'user_id': userId,
      'range': range,
      'status': status,
    };

    if (layananId != null) {
      params['layanan_id'] = layananId;
    }

    final jsonRes = await ApiClient.get(
      ApiConstants.adminFeeCatatanUser,
      queryParams: params,
    );

    if (jsonRes is Map && jsonRes['success'] == true) {
      final data = jsonRes['data'] ?? {};

      final totalSemua = (data['total_semua_layanan'] ?? 0).toDouble();

      final byLayananRaw = (data['total_per_layanan'] ?? []) as List;
      final byLayanan = byLayananRaw
          .map((e) =>
              FeeByLayanan.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final timelineRaw = (data['timeline'] ?? []) as List;
      final timeline = timelineRaw
          .map((e) => FeeTimelinePoint(
                date: DateTime.tryParse(e['tanggal']?.toString() ?? '') ??
                    DateTime.now(),
                amount: (e['total_fee'] ?? 0).toDouble(),
              ))
          .toList();

      final leaderboardRaw = (data['leaderboard'] ?? []) as List;
      final leaderboard = leaderboardRaw
          .map((e) =>
              LeaderboardItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return FeeCatatanUserData(
        totalSemuaLayanan: totalSemua,
        byLayanan: byLayanan,
        timeline: timeline,
        leaderboard: leaderboard,
      );
    } else if (jsonRes is Map && jsonRes.containsKey('message')) {
      throw Exception(jsonRes['message']);
    }

    throw Exception('Gagal memuat data fee user');
  }
}

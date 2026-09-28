import 'package:home_care/core/network/api_client.dart';

class PerawatDashboardService {
  static Future<int> getChatUnread() async {
    try {
      final res = await ApiClient.get('/chat/unread-summary');
      if (res is Map && res['success'] == true) {
        final data = res['data'];
        if (data is Map && data['total_unread'] != null) {
          final totalUnread = data['total_unread'];
          if (totalUnread is int) return totalUnread;
          return int.tryParse(totalUnread?.toString() ?? '0') ?? 0;
        }
        final totalUnread = res['total_unread'];
        if (totalUnread is int) return totalUnread;
        return int.tryParse(totalUnread?.toString() ?? '0') ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> getOrderUnread() async {
    try {
      final res = await ApiClient.get('/perawat/order-layanan');
      List data = [];
      if (res is List) {
        data = res;
      } else if (res is Map) {
        final raw = res['data'];
        if (raw is List) data = raw;
      }

      final relevantStatuses = const [
        'mendapatkan_perawat',
        'sedang_dalam_perjalanan',
        'sampai_ditempat',
        'sedang_berjalan',
      ];

      return data.where((item) {
        if (item is! Map) return false;
        final status = item['status_order']?.toString() ?? '';
        return relevantStatuses.contains(status);
      }).length;
    } catch (_) {
      return 0;
    }
  }
}

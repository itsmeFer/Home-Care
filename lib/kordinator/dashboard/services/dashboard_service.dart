import 'package:home_care/core/network/api_client.dart';

class KoordinatorDashboardService {
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
      final res = await ApiClient.get('/koordinator/order-layanan', queryParams: {'status': 'Pending'});
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).length;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

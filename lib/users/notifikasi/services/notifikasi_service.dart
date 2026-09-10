import 'package:flutter/foundation.dart';
import 'package:home_care/core/network/api_client.dart';
import '../models/notifikasi_model.dart';

class NotifikasiService {
  const NotifikasiService();

  Future<List<AppNotificationItem>> fetchNotifications() async {
    try {
      final res = await ApiClient.get('/notifications');
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data
            .map(
              (e) => AppNotificationItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<bool> markAsRead(int id) async {
    try {
      await ApiClient.post('/notifications/$id/read');
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await ApiClient.post('/notifications/read-all');
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }
}

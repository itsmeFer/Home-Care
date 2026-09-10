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

  Future<int> fetchUnreadCount() async {
    try {
      final res = await ApiClient.get('/notifications');
      if (res is Map && res['success'] == true) {
        if (res['meta'] is Map && res['meta']['unread_count'] != null) {
          final raw = res['meta']['unread_count'];
          return raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
        }
        if (res['data'] is List) {
          final List list = res['data'] as List;
          return list.where((e) => e is Map && e['is_read'] != true).length;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching unread notification count: $e');
      return 0;
    }
  }
}


import 'package:flutter/foundation.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import '../models/search_models.dart';

class UserSearchService {
  const UserSearchService();

  Future<List<LayananSearchResult>> searchLayanan(String keyword) async {
    try {
      final res = await ApiClient.get(
        '/layanan/search',
        queryParams: {'q': keyword},
      );
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data
            .map(
              (e) => LayananSearchResult.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching layanan: $e');
      return [];
    }
  }

  Future<List<SearchHistoryItem>> fetchSearchHistory() async {
    try {
      final res = await ApiClient.get('/pasien/search-history');
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data
            .map(
              (e) => SearchHistoryItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .take(5)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading search history: $e');
      return [];
    }
  }

  Future<void> saveSearchHistory(String keyword) async {
    final clean = keyword.trim();
    if (clean.length < 2) return;

    try {
      await ApiClient.post('/pasien/search-history', body: {'keyword': clean});
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> deleteHistory(int id) async {
    try {
      await ApiClient.delete('/pasien/search-history/$id');
    } catch (e) {
      debugPrint('Error deleting history item: $e');
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await ApiClient.delete('/pasien/search-history');
    } catch (e) {
      debugPrint('Error clearing all search history: $e');
    }
  }

  Future<List<RecentViewedLayananItem>> fetchRecentViewed() async {
    try {
      final res = await ApiClient.get('/pasien/recent-viewed-layanan');
      if (res is Map && res['data'] is List) {
        final List data = res['data'] as List;
        return data
            .map(
              (e) => RecentViewedLayananItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading recent viewed layanan: $e');
      return [];
    }
  }

  Future<void> saveRecentViewed(int layananId) async {
    try {
      await ApiClient.post(
        '/pasien/recent-viewed-layanan',
        body: {'layanan_id': layananId},
      );
    } catch (e) {
      debugPrint('Error saving recent viewed: $e');
    }
  }
}

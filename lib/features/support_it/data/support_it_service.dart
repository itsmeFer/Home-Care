import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/support_it/domain/support_it_models.dart';

class SupportItService {
  static Future<void> submitReport(Map<String, dynamic> payload) async {
    await ApiClient.post('/support-tickets', body: payload);
  }

  static Future<List<SupportTicket>> fetchTickets({
    String? status,
    String? priority,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (priority != null && priority.isNotEmpty) {
      queryParams['priority'] = priority;
    }

    final decoded = await ApiClient.get(
      '/support-tickets',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (decoded is Map && decoded['success'] == true) {
      final data = decoded['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    throw decoded is Map
        ? (decoded['message']?.toString() ?? 'Gagal memuat riwayat laporan.')
        : 'Gagal memuat riwayat laporan.';
  }
}

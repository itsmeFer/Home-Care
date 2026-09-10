import 'package:flutter/foundation.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/orders/domain/order_models.dart';

class HistoriPemesananService {
  const HistoriPemesananService();

  Future<List<OrderHistory>> fetchAllOrders() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/pasien/order-layanan'),
        ApiClient.get('/pasien/order-drafts'),
      ]);

      final orderRes = results[0];
      final draftRes = results[1];

      final List<OrderHistory> finalOrders = [];
      if (orderRes is Map && orderRes['success'] == true && orderRes['data'] is List) {
        final List list = orderRes['data'] as List;
        for (final item in list) {
          if (item is Map) {
            finalOrders.add(OrderHistory.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      final List<OrderHistory> draftOrders = [];
      if (draftRes is Map && draftRes['success'] == true && draftRes['data'] is List) {
        final List list = draftRes['data'] as List;
        for (final item in list) {
          if (item is Map) {
            final draft = Map<String, dynamic>.from(item);
            final draftStatus =
                draft['status']?.toString().toLowerCase().trim() ?? 'draft';

            String paymentStatus;
            switch (draftStatus) {
              case 'expired':
                paymentStatus = 'expired';
                break;
              case 'dibayar':
                paymentStatus = 'dibayar';
                break;
              case 'dibatalkan':
                paymentStatus = 'gagal';
                break;
              case 'menunggu_pembayaran':
              case 'draft':
              default:
                paymentStatus = 'belum_bayar';
                break;
            }

            draftOrders.add(
              OrderHistory(
                id: draft['id'] as int,
                kodeOrder: draft['draft_code']?.toString() ?? '-',
                statusOrder: draftStatus,
                statusPembayaran: paymentStatus,
                namaLayanan: draft['nama_layanan']?.toString() ?? '-',
                totalBayar: double.tryParse(draft['total_bayar']?.toString() ?? '0') ?? 0,
                tanggalMulai: draft['tanggal_mulai']?.toString(),
                jamMulai: draft['jam_mulai']?.toString(),
                tipeLayanan: draft['tipe_layanan']?.toString(),
                metodePembayaran: null,
                qty: int.tryParse(draft['qty']?.toString() ?? '1') ?? 1,
                gambarLayanan: null,
                isDraft: true,
                draftId: draft['id'] as int,
                hasRating: false,
                expiredAt: draft['expired_at']?.toString(),
              ),
            );
          }
        }
      }

      return [...draftOrders, ...finalOrders];
    } catch (e) {
      debugPrint('Error fetchAllOrders: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchOrderDetail(int orderId) async {
    try {
      final res = await ApiClient.get('/pasien/order-layanan/$orderId');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetchOrderDetail: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchDraftDetail(int draftId) async {
    try {
      final res = await ApiClient.get('/pasien/order-draft/$draftId');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetchDraftDetail: $e');
      return null;
    }
  }

  Future<void> cancelOrder(int orderId, String alasan) async {
    final res = await ApiClient.post(
      '/pasien/order-layanan/$orderId/cancel',
      body: {'alasan_batal': alasan},
    );
    if (res is Map && res['success'] == true) return;
    throw Exception(res is Map ? (res['message'] ?? 'Gagal membatalkan pesanan') : 'Gagal membatalkan pesanan');
  }

  Future<void> confirmPaymentCod(int orderId) async {
    final res = await ApiClient.post(
      '/pasien/order-layanan/$orderId/bayar',
      body: {'method': 'cod'},
    );
    if (res is Map && res['success'] == true) return;
    throw Exception(res is Map ? (res['message'] ?? 'Gagal konfirmasi pembayaran') : 'Gagal konfirmasi pembayaran');
  }

  Future<Map<String, dynamic>?> fetchRating(int orderId) async {
    try {
      final res = await ApiClient.get('/pasien/order-layanan/$orderId/rating');
      if (res is Map && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetchRating: $e');
      return null;
    }
  }

  Future<void> submitRating({
    required int orderId,
    required int ratingLayanan,
    required int ratingPerawat,
    required String komentar,
  }) async {
    final res = await ApiClient.post(
      '/pasien/order-layanan/$orderId/rating',
      body: {
        'rating_layanan': ratingLayanan,
        'rating_perawat': ratingPerawat,
        'komentar': komentar,
      },
    );
    if (res is Map && res['success'] == true) return;
    throw Exception(res is Map ? (res['message'] ?? 'Gagal mengirim rating') : 'Gagal mengirim rating');
  }
}

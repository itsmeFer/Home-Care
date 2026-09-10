import 'package:home_care/chat/chat_models.dart';
import 'package:home_care/core/network/api_client.dart';

class ChatService {
  ChatService._();

  static Future<List<ChatRoom>> fetchPasienChatRooms() async {
    final body = await ApiClient.get('/pasien/chat-rooms');
    if (body is Map && body['data'] is List) {
      final List raw = body['data'] as List;
      return raw
          .whereType<Map>()
          .map((e) => ChatRoom.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<void> deletePasienChatRoom(int roomId) async {
    await ApiClient.delete('/pasien/chat-rooms/$roomId');
  }

  static Future<List<ChatRoom>> fetchKoordinatorChatRooms() async {
    final body = await ApiClient.get('/koordinator/chat-rooms');
    if (body is Map && body['data'] is List) {
      final List raw = body['data'] as List;
      return raw
          .whereType<Map>()
          .map((e) => ChatRoom.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  static Future<List<ChatRoom>> fetchPerawatChatRooms() async {
    final body = await ApiClient.get('/perawat/chat-rooms');
    List raw = [];
    if (body is List) {
      raw = body;
    } else if (body is Map) {
      final data = body['data'];
      if (data is List) {
        raw = data;
      }
    }

    return raw
        .whereType<Map>()
        .map((e) => ChatRoom.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

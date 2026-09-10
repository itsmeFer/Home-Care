import 'package:http/http.dart' as http;
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/features/chat/data/models/chat_models.dart';

class ChatService {
  ChatService._();

  static String apiPrefixForRole(String role) {
    switch (role) {
      case 'perawat':
        return '/perawat/chats';
      case 'koordinator':
        return '/koordinator/chats';
      case 'pasien':
      default:
        return '/pasien/chats';
    }
  }

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

  static Future<List<ChatMessage>> fetchRoomMessages({
    required int roomId,
    required String role,
    required int currentUserId,
  }) async {
    final prefix = apiPrefixForRole(role);
    final body = await ApiClient.get('$prefix/$roomId/messages');
    if (body is Map && body['data'] is List) {
      final List raw = body['data'] as List;
      return raw
          .whereType<Map>()
          .map(
            (e) => ChatMessage.fromJson(
              Map<String, dynamic>.from(e),
              currentUserId: currentUserId,
            ),
          )
          .toList();
    }
    return [];
  }

  static Future<ChatMessage?> sendMessage({
    required int roomId,
    required String role,
    required String message,
    required int currentUserId,
  }) async {
    final prefix = apiPrefixForRole(role);
    final body = await ApiClient.post(
      '$prefix/$roomId/messages',
      body: {'message': message},
    );

    if (body is Map && body['data'] is Map) {
      return ChatMessage.fromJson(
        Map<String, dynamic>.from(body['data']),
        currentUserId: currentUserId,
      );
    }
    return null;
  }

  static Future<ChatMessage?> sendImageMessage({
    required int roomId,
    required String role,
    required String imagePath,
    required int currentUserId,
    String? message,
  }) async {
    final prefix = apiPrefixForRole(role);
    final uri = Uri.parse('${ApiConstants.apiBase}$prefix/$roomId/messages');
    final request = http.MultipartRequest('POST', uri);

    if (message != null && message.trim().isNotEmpty) {
      request.fields['message'] = message.trim();
    }
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final body = await ApiClient.sendMultipart(request);
    if (body is Map && body['data'] is Map) {
      return ChatMessage.fromJson(
        Map<String, dynamic>.from(body['data']),
        currentUserId: currentUserId,
      );
    }
    return null;
  }

  static Future<ChatMessage?> sendEtalase({
    required int roomId,
    required int layananId,
    required int currentUserId,
  }) async {
    final body = await ApiClient.post(
      '/pasien/chat-rooms/$roomId/etalase',
      body: {'layanan_id': layananId.toString()},
    );

    if (body is Map && body['data'] is Map) {
      return ChatMessage.fromJson(
        Map<String, dynamic>.from(body['data']),
        currentUserId: currentUserId,
      );
    }
    return null;
  }

  static Future<List<EtalaseData>> fetchEtalaseList() async {
    final body = await ApiClient.get('/layanan');
    List rawList = [];
    if (body is List) {
      rawList = body;
    } else if (body is Map) {
      final data = body['data'];
      if (data is List) {
        rawList = data;
      }
    }

    final host = ApiConstants.apiBase.replaceFirst('/api', '');

    return rawList.whereType<Map>().map((e) {
      final item = Map<String, dynamic>.from(e);
      final raw = item['gambar']?.toString();
      if (raw != null && raw.isNotEmpty && !raw.startsWith('http')) {
        item['gambar'] = '$host/storage/$raw';
      }
      return EtalaseData.fromJson(item);
    }).toList();
  }

  static Future<ChatMessage?> sendTawarHarga({
    required int roomId,
    required String role,
    required String harga,
    required int currentUserId,
    String? catatan,
  }) async {
    final messageText = ChatDealHelper.formatTawarMessage(
      harga: harga,
      catatan: catatan,
    );
    return sendMessage(
      roomId: roomId,
      role: role,
      message: messageText,
      currentUserId: currentUserId,
    );
  }

  static Future<ChatMessage?> sendDealHarga({
    required int roomId,
    required String role,
    required String nominal,
    required int currentUserId,
  }) async {
    final messageText = ChatDealHelper.formatDealMessage(
      nominal: nominal,
      role: role,
    );
    return sendMessage(
      roomId: roomId,
      role: role,
      message: messageText,
      currentUserId: currentUserId,
    );
  }
}

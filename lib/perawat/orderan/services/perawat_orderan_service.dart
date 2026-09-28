import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PerawatOrderanService {
  static Future<Map<String, dynamic>> fetchDetail(int orderId) async {
    final decoded = await ApiClient.get('/perawat/order-layanan/$orderId');
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw 'Format respons detail order tidak sesuai.';
  }

  static Future<Map<String, dynamic>> performAction(String endpoint) async {
    final decoded = await ApiClient.post('/perawat/order-layanan/$endpoint');
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw 'Format respons aksi order tidak sesuai.';
  }

  static Future<Map<String, dynamic>> performActionWithBody(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final decoded = await ApiClient.post(
      '/perawat/order-layanan/$endpoint',
      body: body,
    );
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw 'Format respons aksi order tidak sesuai.';
  }

  static Future<Map<String, dynamic>> uploadPhoto({
    required String endpoint,
    required String fieldName,
    required XFile photo,
  }) async {
    final uri = Uri.parse('${ApiConstants.apiBase}/perawat/order-layanan/$endpoint');
    final request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      final bytes = await photo.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: photo.name),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, photo.path),
      );
    }

    final decoded = await ApiClient.sendMultipart(request);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw 'Format respons upload foto tidak sesuai.';
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_exceptions.dart';
import 'package:home_care/core/services/storage_service.dart';

class ApiClient {
  ApiClient._();

  static final http.Client _client = http.Client();
  static const Duration timeoutDuration = Duration(seconds: 25);

  static VoidCallback? onUnauthorized;

  static Future<Map<String, String>> _buildHeaders({
    Map<String, String>? customHeaders,
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  static Uri _resolveUri(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Uri.parse(url);
    }
    if (url.startsWith('/api/')) {
      return Uri.parse('${ApiConstants.baseUrl}$url');
    }
    if (url.startsWith('/')) {
      return Uri.parse('${ApiConstants.apiBase}$url');
    }
    return Uri.parse('${ApiConstants.apiBase}/$url');
  }

  static Future<dynamic> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    var uri = _resolveUri(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      uri = uri.replace(queryParameters: stringParams);
    }

    try {
      final requestHeaders = await _buildHeaders(
        customHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final response = await _client
          .get(uri, headers: requestHeaders)
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw NoInternetException('Waktu koneksi habis. Coba beberapa saat lagi.');
    }
  }

  static Future<dynamic> post(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = _resolveUri(url);

    try {
      final requestHeaders = await _buildHeaders(
        customHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final encodedBody = body != null && body is! String ? jsonEncode(body) : body;

      final response = await _client
          .post(uri, headers: requestHeaders, body: encodedBody)
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw NoInternetException('Waktu koneksi habis. Coba beberapa saat lagi.');
    }
  }

  static Future<dynamic> put(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = _resolveUri(url);

    try {
      final requestHeaders = await _buildHeaders(
        customHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final encodedBody = body != null && body is! String ? jsonEncode(body) : body;

      final response = await _client
          .put(uri, headers: requestHeaders, body: encodedBody)
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw NoInternetException('Waktu koneksi habis. Coba beberapa saat lagi.');
    }
  }

  static Future<dynamic> delete(
    String url, {
    dynamic body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = _resolveUri(url);

    try {
      final requestHeaders = await _buildHeaders(
        customHeaders: headers,
        requiresAuth: requiresAuth,
      );

      final encodedBody = body != null && body is! String ? jsonEncode(body) : body;

      final response = await _client
          .delete(uri, headers: requestHeaders, body: encodedBody)
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw NoInternetException('Waktu koneksi habis. Coba beberapa saat lagi.');
    }
  }

  static Future<dynamic> sendMultipart(http.MultipartRequest request) async {
    try {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw NoInternetException();
    } on TimeoutException {
      throw NoInternetException('Waktu koneksi habis. Coba beberapa saat lagi.');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    final code = response.statusCode;
    dynamic decodedBody;

    try {
      if (response.body.isNotEmpty) {
        decodedBody = jsonDecode(response.body);
      }
    } catch (_) {
      decodedBody = response.body;
    }

    if (code >= 200 && code < 300) {
      return decodedBody;
    }

    if (code == 401) {
      onUnauthorized?.call();
      throw UnauthorizedException(
        decodedBody is Map ? (decodedBody['message'] ?? 'Sesi berakhir.') : 'Sesi berakhir.',
      );
    }

    if (code == 404) {
      throw NotFoundException(
        decodedBody is Map ? (decodedBody['message'] ?? 'Data tidak ditemukan.') : 'Data tidak ditemukan.',
      );
    }

    if (code == 422 && decodedBody is Map && decodedBody.containsKey('errors')) {
      final errors = decodedBody['errors'];
      if (errors is Map<String, dynamic>) {
        throw ValidationException(errors, decodedBody['message'] ?? 'Validasi gagal.');
      }
    }

    String message = 'Terjadi kesalahan ($code)';
    if (decodedBody is Map && decodedBody.containsKey('message') && decodedBody['message'] != null) {
      message = decodedBody['message'].toString();
    } else if (response.body.isNotEmpty) {
      message = response.body;
    }

    if (code >= 500) {
      throw ServerException(message);
    }

    throw ApiException(message, statusCode: code, details: decodedBody);
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Central HTTP client. Automatically attaches JWT Bearer token to every request.
class ApiClient {
  static const _storage = FlutterSecureStorage();

  static Future<String?> _getToken() => _storage.read(key: 'jwt_token');

  static Future<void> saveToken(String token) =>
      _storage.write(key: 'jwt_token', value: token);

  static Future<void> clearToken() => _storage.delete(key: 'jwt_token');

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static const Duration _timeout = Duration(seconds: 20);

  static Future<dynamic> get(String path) async {
    return _run(() async {
      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: await _headers(),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    });
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    return _run(() async {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    });
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _run(() async {
      final response = await http
          .patch(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handleResponse(response) as Map<String, dynamic>;
    });
  }

  static Future<dynamic> delete(String path) async {
    return _run(() async {
      final response = await http
          .delete(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: await _headers(),
          )
          .timeout(_timeout);
      return _handleResponse(response);
    });
  }

  /// Multipart POST for image uploads (admin menu management)
  static Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields, {
    File? imageFile,
    String imageField = 'image',
  }) async {
    return _run(() async {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}$path'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields.addAll(fields);
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(imageField, imageFile.path),
        );
      }
      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response) as Map<String, dynamic>;
    });
  }

  static Future<T> _run<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException('No internet connection (${e.osError?.message ?? e.message})');
    } on HandshakeException {
      throw ApiException('Secure connection to server failed');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on TimeoutException {
      throw ApiException('Server took too long to respond');
    } on FormatException {
      throw ApiException('Server returned an invalid response');
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'Unexpected server response (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = (decoded is Map ? (decoded['error'] ?? decoded['msg']) : null)
        ?? 'Something went wrong';
    throw ApiException(message.toString(), statusCode: response.statusCode);
  }
}

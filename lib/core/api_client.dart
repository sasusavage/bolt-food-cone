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

  static Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  /// Multipart POST for image uploads (admin menu management)
  static Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields, {
    File? imageFile,
    String imageField = 'image',
  }) async {
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
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  static dynamic _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = (decoded is Map ? decoded['error'] : null) ?? 'Something went wrong';
    throw ApiException(message, statusCode: response.statusCode);
  }
}

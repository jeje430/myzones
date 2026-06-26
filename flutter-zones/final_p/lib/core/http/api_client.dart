import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../../data/repositories/auth_repository.dart';

/// Shared HTTP client for Laravel catalog APIs.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Map<String, String> get _headers => AuthRepository.instance.authHeaders;

  Map<String, String> get _multipartHeaders {
    final token = AuthRepository.instance.authToken;
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path').replace(
      queryParameters: query,
    );

    final response = await http.get(uri, headers: _headers);

    return _decodeResponse(response);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path');
    final response = await http.post(
      uri,
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<dynamic> postMultipart(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_multipartHeaders)
      ..files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    return _decodeResponse(response);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path');
    final response = await http.put(
      uri,
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.apiUrl}$path');
    final response = await http.delete(uri, headers: _headers);

    return _decodeResponse(response);
  }

  dynamic _decodeResponse(http.Response response) {
    final body = response.body.isEmpty
        ? null
        : jsonDecode(response.body) as dynamic;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map ? body['message'] as String? : null;
    throw ApiException(
      statusCode: response.statusCode,
      message: message ?? 'فشل الاتصال بالخادم (${response.statusCode})',
    );
  }
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

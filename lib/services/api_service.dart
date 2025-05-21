import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiService({
    required this.baseUrl,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });

  /// Perform a GET request to the given [endpoint].
  /// Optionally provide additional headers.
  Future<dynamic> get({
    required String endpoint,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.get(
        uri,
        headers: {...defaultHeaders, if (headers != null) ...headers},
      );

      return _processResponse(response);
    } catch (e) {
      debugPrint('GET request error: $e');
      rethrow;
    }
  }

  /// Perform a POST request to the given [endpoint] with optional JSON [body].
  /// Optionally provide additional headers.
  Future<dynamic> post({
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.post(
        uri,
        headers: {...defaultHeaders, if (headers != null) ...headers},
        body: body != null ? jsonEncode(body) : null,
      );

      return _processResponse(response);
    } catch (e) {
      debugPrint('POST request error: $e');
      rethrow;
    }
  }

  /// Handles the HTTP response, throws exception on error or returns JSON data
  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (statusCode == 400) {
      throw ApiException('Bad request (400)');
    } else if (statusCode == 401) {
      throw ApiException('Unauthorized (401)');
    } else if (statusCode == 403) {
      throw ApiException('Forbidden (403)');
    } else if (statusCode == 404) {
      throw ApiException('Not Found (404)');
    } else if (statusCode >= 500) {
      throw ApiException('Server error (${statusCode})');
    } else {
      throw ApiException('Unexpected error occurred. Status code: $statusCode');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

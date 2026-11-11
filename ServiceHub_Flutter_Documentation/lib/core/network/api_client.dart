import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// JSON client for the ServiceHub API.
///
/// Authenticated calls attach the stored JWT. A 401 on one of those calls
/// reports an expired session through [onUnauthorized]. Passwords and tokens
/// are never written to logs.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required http.Client client,
    required this.readToken,
    this.onUnauthorized,
  }) {
    _client = client;
  }

  final String baseUrl;
  late final http.Client _client;
  final Future<String?> Function() readToken;
  final void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 20);

  Future<Map<String, dynamic>> get(String path, {bool authenticated = true}) {
    return _send('GET', path, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('PUT', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _send('PATCH', path, body: body, authenticated: authenticated);
  }

  Future<void> delete(String path, {bool authenticated = true}) async {
    await _send('DELETE', path, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final token = authenticated ? await _readToken() : null;
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    late final http.Response response;
    try {
      response = await _dispatch(
        method,
        _uri(path),
        headers,
        body == null ? null : jsonEncode(body),
      ).timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
        message: 'The server took too long to respond. Try again.',
      );
    } on http.ClientException {
      throw ApiException(
        message:
            'Unable to reach the server. Check your connection and try again.',
      );
    }

    if (response.statusCode == 401 && authenticated) {
      onUnauthorized?.call();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _failure(response);
    }
    if (response.body.isEmpty) return <String, dynamic>{};
    final decoded = _decode(response);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    throw ApiException(
      message: 'The server returned an unexpected response.',
      statusCode: response.statusCode,
    );
  }

  Future<http.Response> _dispatch(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(uri, headers: headers, body: body);
      case 'PUT':
        return _client.put(uri, headers: headers, body: body);
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: body);
      case 'DELETE':
        return _client.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported method $method');
    }
  }

  Future<String?> _readToken() async {
    final token = await readToken();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  Uri _uri(String path) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final suffix = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$root$suffix');
  }

  Object? _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        message: 'The server returned an unexpected response.',
        statusCode: response.statusCode,
      );
    }
  }

  ApiException _failure(http.Response response) {
    var message = 'Something went wrong. Try again.';
    String? path;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final rawMessage = decoded['message'];
          if (rawMessage is String && rawMessage.trim().isNotEmpty) {
            message = rawMessage.trim();
          }
          final rawPath = decoded['path'];
          if (rawPath is String) path = rawPath;
        }
      } on FormatException {
        message = 'Something went wrong. Try again.';
      }
    }
    return ApiException(
      message: message,
      statusCode: response.statusCode,
      path: path,
    );
  }
}

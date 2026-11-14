import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    return _sendMap('GET', path, authenticated: authenticated);
  }

  Future<Object?> getJson(String path, {bool authenticated = true}) {
    return _send('GET', path, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _sendMap('POST', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _sendMap('PUT', path, body: body, authenticated: authenticated);
  }

  Future<Object?> putJson(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _send('PUT', path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _sendMap('PATCH', path, body: body, authenticated: authenticated);
  }

  Future<void> delete(String path, {bool authenticated = true}) async {
    await _sendMap('DELETE', path, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> _sendMap(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final response = await _send(
      method,
      path,
      body: body,
      authenticated: authenticated,
    );
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    throw ApiException(message: 'The server returned an unexpected response.');
  }

  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    required bool authenticated,
  }) async {
    final token = authenticated ? await _readToken() : null;
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final uri = _uri(path);
    final requestBody = body == null ? null : jsonEncode(body);
    _logRequest(method, uri, requestBody);

    late final http.Response response;
    try {
      response = await _dispatch(
        method,
        uri,
        headers,
        requestBody,
      ).timeout(_timeout);
      _logResponse(method, uri, response);
    } on TimeoutException {
      _logTransportError(method, uri, 'Request timed out');
      throw ApiException(
        message: 'The server took too long to respond. Try again.',
      );
    } on http.ClientException catch (error) {
      _logTransportError(method, uri, error.message);
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
    if (decoded is List) return decoded;
    throw ApiException(
      message: 'The server returned an unexpected response.',
      statusCode: response.statusCode,
    );
  }

  void _logRequest(String method, Uri uri, String? body) {
    if (!kDebugMode) return;
    debugPrint('[API] --> $method ${_uriForLog(uri)}');
    if (body != null) {
      debugPrint('[API] request body: ${_bodyForLog(body)}');
    }
  }

  void _logResponse(String method, Uri uri, http.Response response) {
    if (!kDebugMode) return;
    debugPrint('[API] <-- $method ${_uriForLog(uri)} (${response.statusCode})');
    if (response.body.isNotEmpty && response.statusCode != 401) {
      debugPrint('[API] response body: ${_bodyForLog(response.body)}');
    }
  }

  void _logTransportError(String method, Uri uri, String message) {
    if (!kDebugMode) return;
    debugPrint('[API] !! $method ${_uriForLog(uri)}: $message');
  }

  Uri _uri(String path) {
    final base = Uri.parse(baseUrl);
    final trimmedPath = path.startsWith('/') ? path.substring(1) : path;
    return base.resolve(trimmedPath);
  }

  String _uriForLog(Uri uri) {
    if (uri.path.contains('/auth/')) {
      return uri.replace(query: '...').toString();
    }
    return uri.toString();
  }

  String _bodyForLog(String body) {
    if (body.contains('password') || body.contains('token')) {
      return '{"email":"...","password":"[REDACTED]"}';
    }
    return body;
  }

  Future<http.Response> _dispatch(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) async {
    final request = http.Request(method, uri);
    request.headers.addAll(headers);
    if (body != null) {
      request.body = body;
    }
    return _client.send(request).then(http.Response.fromStream);
  }

  Object? _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        message: 'The server returned an unexpected response.',
        statusCode: response.statusCode,
      );
    }
  }

  ApiException _failure(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return ApiException(
            message: message,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (_) {}
    return ApiException(
      message: 'Server error (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }

  Future<String?> _readToken() async {
    return await readToken();
  }
}

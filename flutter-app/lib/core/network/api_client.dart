import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Thin HTTP wrapper around the AAURA Express backend.
///
/// Responsibilities:
///  - Prefix requests with [AppConfig.apiBaseUrl].
///  - Attach the current Supabase access token as a `Bearer` header.
///  - Unwrap the backend `{ message, data }` envelope and return `data`.
///  - Convert non-2xx responses / transport errors / timeouts into a typed
///    [ApiException].
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = _normalizeBase(baseUrl ?? AppConfig.apiBaseUrl);

  final http.Client _client;
  final String _baseUrl;

  static String _normalizeBase(String base) =>
      base.endsWith('/') ? base.substring(0, base.length - 1) : base;

  String? get _accessToken {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      // Supabase not initialized yet.
      return null;
    }
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{'Accept': 'application/json'};
    final token = _accessToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    if (jsonBody) headers['Content-Type'] = 'application/json';
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final suffix = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$suffix');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    Duration? timeout,
  }) =>
      _send(
        () => _client.get(_uri(path, query), headers: _headers()),
        timeout: timeout,
      );

  Future<dynamic> post(
    String path, {
    Object? body,
    Duration? timeout,
  }) =>
      _send(
        () => _client.post(
          _uri(path),
          headers: _headers(jsonBody: true),
          body: body == null ? null : jsonEncode(body),
        ),
        timeout: timeout,
      );

  Future<dynamic> patch(
    String path, {
    Object? body,
    Duration? timeout,
  }) =>
      _send(
        () => _client.patch(
          _uri(path),
          headers: _headers(jsonBody: true),
          body: body == null ? null : jsonEncode(body),
        ),
        timeout: timeout,
      );

  Future<dynamic> delete(
    String path, {
    Object? body,
    Duration? timeout,
  }) =>
      _send(
        () => _client.delete(
          _uri(path),
          headers: _headers(jsonBody: true),
          body: body == null ? null : jsonEncode(body),
        ),
        timeout: timeout,
      );

  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    Duration? timeout,
  }) async {
    http.Response res;
    try {
      res = await request().timeout(timeout ?? AppConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException(0, 'Request timed out.');
    } catch (e) {
      throw ApiException(0, 'Network error: $e');
    }
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final status = res.statusCode;
    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = res.body;
      }
    }

    if (status >= 200 && status < 300) {
      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    }

    final message = body is Map<String, dynamic> && body['message'] is String
        ? body['message'] as String
        : 'Request failed ($status).';
    throw ApiException(status, message, body);
  }

  void close() => _client.close();
}

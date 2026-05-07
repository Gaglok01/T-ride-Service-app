import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:t_ride_rider_app/core/config/api_urls.dart';

class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? ApiUrls.baseUrl,
        _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Uri _buildUri(String endpoint, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    final uri = _buildUri(endpoint, query);
    return _httpClient.get(uri, headers: headers);
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    Object? body,
  }) {
    final uri = _buildUri(endpoint, query);
    return _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    Object? body,
  }) {
    final uri = _buildUri(endpoint, query);
    return _httpClient.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    Object? body,
  }) {
    final uri = _buildUri(endpoint, query);
    return _httpClient.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      body: body == null ? null : jsonEncode(body),
    );
  }
}


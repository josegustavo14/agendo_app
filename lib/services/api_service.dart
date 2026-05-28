import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:9090';

  String? _token;

  /// Called when any authenticated request returns 401 (token expirado/inválido).
  VoidCallback? onUnauthorized;

  String? get token => _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  void _checkUnauthorized(http.Response response) {
    if (response.statusCode == 401 && _token != null) {
      debugPrint('[ApiService] 401 recebido — token inválido ou expirado');
      clearToken();
      onUnauthorized?.call();
    }
  }

  Future<http.Response> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.patch(uri, headers: _headers, body: jsonEncode(body ?? {}));
    _checkUnauthorized(response);
    return response;
  }

  Future<http.Response> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.delete(uri, headers: _headers);
    _checkUnauthorized(response);
    return response;
  }
}

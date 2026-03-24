import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:9090';

  String? _token;

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

  Future<http.Response> get(String path, {Map<String, String>? queryParams}) {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    return http.get(uri, headers: _headers);
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) {
    final uri = Uri.parse('$baseUrl$path');
    return http.post(uri, headers: _headers, body: jsonEncode(body));
  }

  Future<http.Response> patch(String path, {Map<String, dynamic>? body}) {
    final uri = Uri.parse('$baseUrl$path');
    return http.patch(uri, headers: _headers, body: jsonEncode(body ?? {}));
  }
}

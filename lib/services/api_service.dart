import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Helper function for [compute] to decode JSON in a background isolate
dynamic _parseJson(String text) {
  return jsonDecode(text);
}

class ApiService {
  final String baseUrl;
  String? _token;
  void Function()? onUnauthorized;

  ApiService({required this.baseUrl});

  Future<void> setToken(String token) async {
    debugPrint('DEBUG: [ApiService] setToken called. Token starts with: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> clearToken() async {
    debugPrint('DEBUG: [ApiService] clearToken called');
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String _cleanEndpoint(String endpoint) {
    return endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/${_cleanEndpoint(endpoint)}').replace(queryParameters: queryParams);
    debugPrint('DEBUG: [ApiService] GET $uri (Token present: ${token != null})');
    final response = await http.get(uri, headers: _headers(token));
    return _handleResponse(response, 'GET', uri.toString());
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';
    
    // Log body but hide passwords
    final logBody = Map<String, dynamic>.from(body ?? {});
    if (logBody.containsKey('password')) logBody['password'] = '********';
    debugPrint('DEBUG: [ApiService] POST $url | Body: $logBody | Token present: ${token != null}');

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, 'POST', url);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';
    
    debugPrint('DEBUG: [ApiService] PUT (spoofed POST) $url | Body: $body | Token present: ${token != null}');
    
    // Using POST with _method spoofing is often more reliable for Laravel controllers
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode({...?body, '_method': 'PUT'}),
    );
    return _handleResponse(response, 'PUT', url);
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';
    debugPrint('DEBUG: [ApiService] DELETE $url | Body: $body | Token present: ${token != null}');

    if (body != null) {
      // Consistent with PUT, use POST spoofing for DELETE with body
      final response = await http.post(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode({...?body, '_method': 'DELETE'}),
      );
      return _handleResponse(response, 'DELETE', url);
    }

    final response = await http.delete(
      Uri.parse(url),
      headers: _headers(token),
    );
    return _handleResponse(response, 'DELETE', url);
  }

  Future<dynamic> _handleResponse(http.Response response, String method, String url) async {
    debugPrint('DEBUG: [ApiService] Response from $method $url: Status ${response.statusCode}');
    
    if (response.body.isEmpty) return null;
    
    final dynamic decoded = await compute(_parseJson, response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      if (response.statusCode == 401) {
        debugPrint('DEBUG: [ApiService] 401 Unauthorized detected at $url. Content: ${response.body}');
        onUnauthorized?.call();
      }

      String errorMessage = decoded['message'] ?? 'API Error ${response.statusCode}';
      
      if (response.statusCode == 422 && decoded['errors'] != null) {
        debugPrint('DEBUG: [ApiService] Validation Error at $url: ${decoded['errors']}');
        final Map<String, dynamic> errors = decoded['errors'];
        final allErrors = errors.values.expand((e) => e as List).join(' ');
        if (allErrors.isNotEmpty) {
          errorMessage = allErrors;
        }
      }
      
      throw Exception(errorMessage);
    }
  }
}

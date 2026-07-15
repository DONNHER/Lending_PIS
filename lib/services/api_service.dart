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

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams, bool triggerUnauthorized = true}) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/${_cleanEndpoint(endpoint)}').replace(queryParameters: queryParams);
    final headers = _headers(token);
    debugPrint('DEBUG: [ApiService] Request GET $uri with token: ${token?.substring(0, 10)}...');
    final response = await http.get(uri, headers: headers);
    return _handleResponse(response, 'GET', uri.toString(), triggerUnauthorized: triggerUnauthorized);
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, bool triggerUnauthorized = true}) async {
    final token = await getToken();
    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';
    final headers = _headers(token);
    debugPrint('DEBUG: [ApiService] Request POST $url with token: ${token?.substring(0, 10)}...');
    
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response, 'POST', url, triggerUnauthorized: triggerUnauthorized);
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, bool triggerUnauthorized = true}) async {
    final token = await getToken();
    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';
    
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode({...?body, '_method': 'PUT'}),
    );
    return _handleResponse(response, 'PUT', url, triggerUnauthorized: triggerUnauthorized);
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body, bool triggerUnauthorized = true}) async {
    final token = await getToken();
    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';

    if (body != null) {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers(token),
        body: jsonEncode({...body, '_method': 'DELETE'}),
      );
      return _handleResponse(response, 'DELETE', url, triggerUnauthorized: triggerUnauthorized);
    }

    final response = await http.delete(
      Uri.parse(url),
      headers: _headers(token),
    );
    return _handleResponse(response, 'DELETE', url, triggerUnauthorized: triggerUnauthorized);
  }

  Future<dynamic> _handleResponse(http.Response response, String method, String url, {bool triggerUnauthorized = true}) async {
    // Log basic info for every response
    debugPrint('DEBUG: [ApiService] Response received for $method $url');
    debugPrint('DEBUG: [ApiService] Status Code: ${response.statusCode}');
    debugPrint('DEBUG: [ApiService] Content-Type: ${response.headers['content-type']}');
    debugPrint('DEBUG: [ApiService] Raw Body: ${response.body}');

    if (response.body.isEmpty) return null;

    final contentType = response.headers['content-type'] ?? '';
    
    if (!contentType.contains('application/json') && !response.body.startsWith('{') && !response.body.startsWith('[')) {
      debugPrint('DEBUG: [ApiService] WARNING: Non-JSON response detected');
      throw Exception('Server returned an error (${response.statusCode}).');
    }
    
    try {
      final dynamic decoded = await compute(_parseJson, response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else {
        if (response.statusCode == 401 && triggerUnauthorized) {
          onUnauthorized?.call();
        }

        // 🚀 SPECIAL HANDLING: Return full response for specific status codes (like 403 Forbidden for CAPTCHA/Lockout)
        if (response.statusCode == 403 && decoded is Map && decoded.containsKey('captcha_required')) {
          return decoded;
        }

        String errorMessage = 'API Error ${response.statusCode}';
        if (decoded is Map) {
          if (decoded.containsKey('errors') && decoded['errors'] is Map) {
            final Map<String, dynamic> errors = decoded['errors'];
            final firstErrorList = errors.values.first;
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              errorMessage = firstErrorList.first.toString();
            }
          } else if (decoded.containsKey('message')) {
            errorMessage = decoded['message'];
          }
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('DEBUG: [ApiService] JSON Parse Error: $e');
      throw Exception('Failed to parse server response.');
    }
  }
}

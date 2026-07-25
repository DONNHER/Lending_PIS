import 'dart:convert';
import 'dart:typed_data'; // 🎯 Required for Uint8List
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // 🎯 Required for MediaType
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
    debugPrint('DEBUG: [ApiService] Token saved successfully.');
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    debugPrint('DEBUG: [ApiService] Retrieved token from storage: ${_token != null ? "Found (${_token!.substring(0, 6)}...)" : "Null"}');
    return _token;
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    debugPrint('DEBUG: [ApiService] Token cleared.');
  }

  // 🚀 Updated to merge optional custom headers (like X-Supabase-User-Id)
  Map<String, String> _headers(String? token, Map<String, String>? customHeaders) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (customHeaders != null) ...customHeaders,
    };
  }

  String _cleanEndpoint(String endpoint) {
    return endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
  }

  // 🚀 Added optional {Map<String, String>? headers} parameter
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams, Map<String, String>? headers, bool triggerUnauthorized = true}) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/${_cleanEndpoint(endpoint)}').replace(queryParameters: queryParams);
    final requestHeaders = _headers(token, headers);
    debugPrint('DEBUG: [ApiService] Request GET $uri with token: ${token != null ? "${token.substring(0, 6)}..." : "NULL"}');
    final response = await http.get(uri, headers: requestHeaders);
    return _handleResponse(response, 'GET', uri.toString(), triggerUnauthorized: triggerUnauthorized);
  }

  // 🚀 Added optional {Map<String, String>? headers} parameter
  Future<dynamic> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
        bool triggerUnauthorized = true,
      }) async {

    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';

    String? token;

    // Do not attach Laravel Sanctum token when exchanging Supabase JWT
    if (_cleanEndpoint(endpoint) != 'login') {
      token = await getToken();
    }

    final requestHeaders = _headers(token, headers);

    debugPrint(
        'DEBUG: [ApiService] Request POST $url with token: ${token != null ? "${token.substring(0,6)}..." : "NULL"}'
    );

    final response = await http.post(
      Uri.parse(url),
      headers: requestHeaders,
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(
      response,
      'POST',
      url,
      triggerUnauthorized: triggerUnauthorized,
    );
  }


  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers, bool triggerUnauthorized = true}) async {
    final token = await getToken();
    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token, headers),
      body: jsonEncode({...?body, '_method': 'PUT'}),
    );
    return _handleResponse(response, 'PUT', url, triggerUnauthorized: triggerUnauthorized);
  }

  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers, bool triggerUnauthorized = true}) async {
    final token = await getToken();
    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';

    if (body != null) {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers(token, headers),
        body: jsonEncode({...body, '_method': 'DELETE'}),
      );
      return _handleResponse(response, 'DELETE', url, triggerUnauthorized: triggerUnauthorized);
    }

    final response = await http.delete(
      Uri.parse(url),
      headers: _headers(token, headers),
    );
    return _handleResponse(response, 'DELETE', url, triggerUnauthorized: triggerUnauthorized);
  }

  Future<dynamic> uploadFile(String endpoint, String filePath, {Map<String, String>? headers, bool triggerUnauthorized = true}) async {
    final token = await getToken();
    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (headers != null) ...headers,
    });

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response, 'POST (Multipart)', url, triggerUnauthorized: triggerUnauthorized);
  }

  Future<dynamic> uploadFileBytes({
    required String endpoint,
    required Uint8List bytes,
    required String fileName,
    Map<String, String>? headers,
    bool triggerUnauthorized = true,
  }) async {
    final token = await getToken();
    final url = '$baseUrl/${_cleanEndpoint(endpoint)}';

    debugPrint('DEBUG: [ApiService] Request POST (Multipart Bytes) $url with token: ${token != null ? "${token.substring(0, 6)}..." : "NULL"}');

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (headers != null) ...headers,
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType('application', 'octet-stream'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response, 'POST (Multipart Bytes)', url, triggerUnauthorized: triggerUnauthorized);
  }

  Future<dynamic> _handleResponse(http.Response response, String method, String url, {bool triggerUnauthorized = true}) async {
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
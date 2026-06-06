import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl;
  String? _token;

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

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  String _cleanEndpoint(String endpoint) {
    return endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/${_cleanEndpoint(endpoint)}').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers(token));
    return _handleResponse(response);
  }

  /// POST request with named body parameter
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/${_cleanEndpoint(endpoint)}'),
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// PUT request with named body parameter
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    // Laravel handles _method: PUT inside a POST request for multipart/compatibility
    final response = await http.post(
      Uri.parse('$baseUrl/${_cleanEndpoint(endpoint)}'),
      headers: _headers(token),
      body: jsonEncode({...?body, '_method': 'PUT'}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/${_cleanEndpoint(endpoint)}'),
      headers: _headers(token),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.body.isEmpty) return null;
    
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      String errorMessage = decoded['message'] ?? 'API Error ${response.statusCode}';
      
      // If it's a validation error (422), extract the specific field errors
      if (response.statusCode == 422 && decoded['errors'] != null) {
        final Map<String, dynamic> errors = decoded['errors'];
        // Flatten the errors into a single readable string
        final allErrors = errors.values.expand((e) => e as List).join(' ');
        if (allErrors.isNotEmpty) {
          errorMessage = allErrors;
        }
      }
      
      throw Exception(errorMessage);
    }
  }
}

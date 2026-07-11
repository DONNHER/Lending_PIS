import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post('/login', body: {
      'email': email,
      'password': password,
    });
    return response;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    final response = await _apiService.post('/register', body: {
      'username': username,
      'email': email,
      'password': password,
      'firstname': firstName,
      'lastname': lastName,
      'role': role.name,
    });
    return response;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/me');
      if (response != null && response['user'] != null) {
        return UserModel.fromJson(response['user']);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> logout() async {
    await _apiService.post('/logout');
    await _apiService.clearToken();
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    debugPrint('DEBUG: [AuthRepository] Calling /forgot-password for: $email');
    final response = await _apiService.post('/forgot-password', body: {
      'email': email,
    });
    return response;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final response = await _apiService.post('/reset-password', body: {
      'email': email,
      'code': code,
      'password': password,
    });
    return response;
  }
}

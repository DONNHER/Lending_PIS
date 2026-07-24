import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;
  final _supabase = Supabase.instance.client;

  AuthRepository(this._apiService);

  Map<String, String> get _supabaseHeaders {
    final userId = _supabase.auth.currentUser?.id;
    return {
      if (userId != null) 'X-Supabase-User-Id': userId,
    };
  }

  Future<Map<String, dynamic>> login(String email, {String? captchaToken}) async {
    final response = await _apiService.post('/login', body: {
      'email': email,
      if (captchaToken != null) 'captcha_token': captchaToken,
    });

    if (response['token'] != null) {
      await _apiService.setToken(response['token']);
    }

    return response;
  }

  Future<void> setToken(String token) async {
    await _apiService.setToken(token);
  }

  Future<String?> getToken() async {
    return await _apiService.getToken();
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    String? address,
    String? phone,
    String? idImageUrl,
    double? initialShare,
  }) async {
    final response = await _apiService.post('/register', body: {
      'username': username,
      'email': email,
      'password': password,
      'firstname': firstName,
      'lastname': lastName,
      'role': role.name,
      'address': address,
      'phone': phone,
      'id_image_url': idImageUrl,
      if (initialShare != null) 'initial_share': initialShare,
    });
    return response;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/user', headers: _supabaseHeaders);
      if (response != null) {
        return UserModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('DEBUG: [AuthRepository] Error fetching current user from API: $e');
      return null;
    }
    return null;
  }

  // 🚀 Fetch user profile directly by email from the Laravel backend
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _apiService.get('/user/by-email?email=$email');
      if (response != null) {
        return UserModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('DEBUG: [AuthRepository] Error fetching user by email: $e');
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> verifyMfa(String email) async {
    final response = await _apiService.post('/verify-mfa', body: {
      'email': email,
    });

    if (response['token'] != null) {
      await _apiService.setToken(response['token']);
    }

    return response;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String address,
    String? avatarUrl,
  }) async {
    final response = await _apiService.post('/user/profile',
      body: {
        'firstname': firstName,
        'lastname': lastName,
        'address': address,
        'avatar_url': avatarUrl,
      },
      headers: _supabaseHeaders,
    );
    return response;
  }

  Future<void> logout() async {
    await _apiService.post('/logout');
    await _apiService.clearToken();
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    debugPrint('DEBUG: [AuthRepository] Calling /forgot-password for: $email');
    try {
      final response = await _apiService.post('/forgot-password', body: {
        'email': email,
      });
      debugPrint('DEBUG: [AuthRepository] /forgot-password response success: $response');
      return response;
    } catch (e) {
      debugPrint('DEBUG: [AuthRepository] /forgot-password error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    debugPrint('DEBUG: [AuthRepository] Calling /reset-password for: $email');
    try {
      final response = await _apiService.post('/reset-password', body: {
        'email': email,
        'code': code,
        'password': password,
      });
      debugPrint('DEBUG: [AuthRepository] /reset-password response success: $response');
      return response;
    } catch (e) {
      debugPrint('DEBUG: [AuthRepository] /reset-password error: $e');
      rethrow;
    }
  }
}
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<Map<String, dynamic>> login(String email, String password, {String? captchaToken}) async {
    final response = await _apiService.post('/login', body: {
      'email': email,
      'password': password,
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
    double? initialShare, // <-- 1. Added initialShare parameter here
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
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser == null) return null;

      // Fetch the profile data directly from your Supabase database table
      final response = await Supabase.instance.client
          .from('users') // or 'admins' depending on your schema
          .select()
          .eq('id', supabaseUser.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching current user from Supabase: $e');
      return null;
    }
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
    final response = await _apiService.post('/user/profile', body: {
      'firstname': firstName,
      'lastname': lastName,
      'address': address,
      'avatar_url': avatarUrl,
    });
    return response;
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

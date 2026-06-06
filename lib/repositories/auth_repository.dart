import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required UserRole role,
    String? avatarUrl,
  }) async {
    try {
      final response = await _api.post('/register', body: {
        'username': username,
        'email': email,
        'password': password,
        'firstname': firstname,
        'lastname': lastname,
        'role': role.name,
        'avatar_url': avatarUrl,
      });

      if (response != null && response['success'] == true) {
        final String? token = response['token'];
        if (token != null) {
          await _api.setToken(token);
        }
        return UserModel.fromJson(response['user']);
      } else {
        throw Exception(response?['message'] ?? 'Registration failed');
      }
    } catch (e) {
      debugPrint('AuthRepo Register Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> login({required String email, required String password}) async {
    try {
      final response = await _api.post('/login', body: {
        'email': email,
        'password': password,
      });

      if (response != null && response['success'] == true) {
        if (response['mfa_required'] == true) {
          return {
            'mfa_required': true,
            'email': response['email'],
          };
        }
        
        final String token = response['token'];
        await _api.setToken(token);
        return {
          'user': UserModel.fromJson(response['user']),
          'token': token,
        };
      }
    } catch (e) {
      debugPrint('AuthRepo Login Error: $e');
      rethrow;
    }
    return null;
  }

  Future<UserModel?> verifyMfa({
    required String email,
    required String code,
    bool remember = false,
  }) async {
    try {
      final response = await _api.post('/verify-mfa', body: {
        'email': email,
        'code': code,
        'remember': remember,
      });

      if (response != null && response['success'] == true) {
        final String token = response['token'];
        await _api.setToken(token);
        return UserModel.fromJson(response['user']);
      }
    } catch (e) {
      debugPrint('AuthRepo verifyMfa Error: $e');
      rethrow;
    }
    return null;
  }

  Future<UserModel?> restoreSession() async {
    try {
      final token = await _api.getToken();
      if (token == null) return null;

      final response = await _api.get('/user');
      if (response != null) {
        return UserModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('Session restoration failed: $e');
      await _api.clearToken();
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } finally {
      await _api.clearToken();
    }
  }

  Future<UserModel> updateProfile({
    required String firstname,
    required String lastname,
    String? avatarUrl,
  }) async {
    try {
      final response = await _api.put('/user/profile', body: {
        'firstname': firstname,
        'lastname': lastname,
        'avatar_url': avatarUrl,
      });

      if (response != null && response['success'] == true) {
        return UserModel.fromJson(response['user']);
      } else {
        throw Exception(response?['message'] ?? 'Profile update failed');
      }
    } catch (e) {
      debugPrint('AuthRepo updateProfile Error: $e');
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _api.put('/user/change-password', body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      });

      return response != null && response['success'] == true;
    } catch (e) {
      debugPrint('AuthRepo changePassword Error: $e');
      rethrow;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await _api.post('/forgot-password', body: {'email': email});
      return response != null && response['success'] == true;
    } catch (e) {
      debugPrint('AuthRepo requestPasswordReset Error: $e');
      rethrow;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _api.post('/reset-password', body: {
        'email': email,
        'code': code,
        'password': newPassword,
        'password_confirmation': newPassword,
      });
      return response != null && response['success'] == true;
    } catch (e) {
      debugPrint('AuthRepo resetPassword Error: $e');
      rethrow;
    }
  }

  Future<UserModel> updateStatus(String userId, UserStatus status) async {
    try {
      final response = await _api.put('/admin/users/$userId/status', body: {
        'status': status.name,
      });

      if (response != null && response['success'] == true) {
        return UserModel.fromJson(response['user']);
      } else {
        throw Exception(response?['message'] ?? 'Status update failed');
      }
    } catch (e) {
      debugPrint('AuthRepo updateStatus Error: $e');
      rethrow;
    }
  }
}

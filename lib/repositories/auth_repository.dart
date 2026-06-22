import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _api;
  final _supabase = Supabase.instance.client;

  AuthRepository(this._api);

  // 🚀 CRITICAL: Removed Supabase session syncing with Laravel tokens.
  // Laravel tokens (Sanctum) are not valid Supabase session tokens.
  // Attempting to sync them causes Supabase to invalidate the session and sign out.

  Future<AuthMFAEnrollResponse> enrollMfa() async {
    try {
      return await _supabase.auth.mfa.enroll(factorType: FactorType.totp, issuer: 'EngrCanteen');
    } catch (e) {
      debugPrint('Mfa Enroll Error: $e');
      rethrow;
    }
  }

  Future<AuthMFAChallengeResponse> challengeMfa(String factorId) async {
    try {
      return await _supabase.auth.mfa.challenge(factorId: factorId);
    } catch (e) {
      debugPrint('Mfa Challenge Error: $e');
      rethrow;
    }
  }

  Future<void> verifyMfaChallenge({
    required String factorId,
    required String challengeId,
    required String code,
  }) async {
    try {
      await _supabase.auth.mfa.verify(
        factorId: factorId,
        challengeId: challengeId,
        code: code,
      );
    } catch (e) {
      debugPrint('Mfa Verify Error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> listMfaFactors() async {
    final res = await _supabase.auth.mfa.listFactors();
    return res.all;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
    String? avatarUrl,
    String? idImageUrl,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      // 1. Supabase Auth Registration
      try {
        debugPrint('DEBUG: [AuthRepository] signUp for: $normalizedEmail');
        await _supabase.auth.signUp(
          email: normalizedEmail,
          password: password,
        );
      } catch (e) {
        if (e is AuthApiException && e.code != 'user_already_exists') rethrow;
      }

      // 2. Laravel Database Registration
      final response = await _api.post('/register', body: {
        'username': username,
        'email': normalizedEmail,
        'password': password,
        'firstname': firstName,
        'lastname': lastName,
        'role': role.name,
        'avatar_url': avatarUrl,
        'id_image_url': idImageUrl,
      });

      if (response != null && response['success'] == true) {
        final String? token = response['token'] ?? 
                             response['access_token'] ?? 
                             (response['data'] is Map ? response['data']['token'] : null);
        
        if (token != null) {
          await _api.setToken(token);
        }
        
        return {
          'user': response['user'] != null ? UserModel.fromJson(response['user']) : null,
          'token': token,
          'mfa_required': response['mfa_required'] == true,
          'email': response['email'] ?? normalizedEmail,
          'supabase_mfa': response['supabase_mfa'] == true,
          'message': response['message'],
        };
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
        final String? token = response['token'] ?? 
                             response['access_token'] ?? 
                             (response['data'] is Map ? response['data']['token'] : null);

        if (token != null) {
          await _api.setToken(token);
          debugPrint('DEBUG: [AuthRepository] Laravel Token successfully set in ApiService.');
        }

        return {
          'user': response['user'] != null ? UserModel.fromJson(response['user']) : null,
          'token': token,
          'mfa_required': response['mfa_required'] == true,
          'email': response['email'],
          'supabase_mfa': response['supabase_mfa'] == true,
          'message': response['message'],
        };
      }
    } catch (e) {
      debugPrint('AuthRepo Login Error: $e');
      rethrow;
    }
    return null;
  }

  Future<bool> resendMfaCode(String email) async {
    try {
      final response = await _api.post('/resend-mfa', body: {'email': email});
      return response != null && response['success'] == true;
    } catch (e) {
      return false;
    }
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
        final String? token = response['token'] ?? (response['data'] is Map ? response['data']['token'] : null);
        if (token != null) await _api.setToken(token);
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
      await _supabase.auth.signOut();
    } finally {
      await _api.clearToken();
    }
  }

  Future<void> clearLocalSession() async {
    await _api.clearToken();
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
  }

  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    String? address,
    String? avatarUrl,
    String? idImageUrl,
  }) async {
    try {
      final response = await _api.put('/user/profile', body: {
        'firstname': firstName,
        'lastname': lastName,
        'address': address,
        'avatar_url': avatarUrl,
        'id_image_url': idImageUrl,
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

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _api.post('/forgot-password', body: {'email': email});
      return {
        'success': response != null && response['success'] == true,
        'message': response?['message'],
      };
    } catch (e) {
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
      rethrow;
    }
  }
}

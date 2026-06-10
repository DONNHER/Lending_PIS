import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _api;
  final _supabase = Supabase.instance.client;

  AuthRepository(this._api);

  /// Syncs the Laravel token with Supabase Auth so Storage policies work
  Future<void> _syncSupabaseSession(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _supabase.auth.setSession(token);
      debugPrint('DEBUG: [AuthRepository] Supabase session synced.');
    } catch (e) {
      debugPrint('DEBUG: [AuthRepository] Supabase session sync failed: $e');
    }
  }

  Future<AuthMFAEnrollResponse> enrollMfa() async {
    try {
      final res = await _supabase.auth.mfa.enroll(factorType: FactorType.totp, issuer: 'EngrCanteen');
      return res;
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
          await _syncSupabaseSession(token);
        }
        
        return {
          'user': UserModel.fromJson(response['user']),
          'token': token,
          'mfa_required': response['mfa_required'] == true,
          'email': response['email'],
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
        final userJson = response['user'];
        final user = userJson != null ? UserModel.fromJson(userJson) : null;
        final String? token = response['token'];

        if (token != null) {
          await _api.setToken(token);
          await _syncSupabaseSession(token);
        }

        return {
          'user': user,
          'token': token,
          'mfa_required': response['mfa_required'] == true,
          'email': response['email'],
          'supabase_mfa': response['supabase_mfa'] == true,
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
      debugPrint('DEBUG: Failed to resend Mfa code for: $email. Error: $e');
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
        final String token = response['token'];
        await _api.setToken(token);
        await _syncSupabaseSession(token);
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

      await _syncSupabaseSession(token);

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
    await _supabase.auth.signOut();
  }

  Future<UserModel> updateProfile({
    required String firstname,
    required String lastname,
    String? address,
    String? avatarUrl,
    String? idImageUrl,
  }) async {
    try {
      final response = await _api.put('/user/profile', body: {
        'firstname': firstname,
        'lastname': lastname,
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

  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await _api.post('/forgot-password', body: {'email': email});
      return response != null && response['success'] == true;
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

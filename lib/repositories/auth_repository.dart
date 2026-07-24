import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  AuthRepository();

  Future<Map<String, dynamic>> login(String email, {String? password, String? captchaToken}) async {
    // If using Supabase Auth password sign in:
    if (password != null) {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return {
        'user': response.user,
        'session': response.session,
      };
    }

    // Fallback to OTP / Magic Link if password isn't provided
    await _supabase.auth.signInWithOtp(
      email: email,
      // data: if you need to pass captcha token, use emailRedirectTo or options
    );

    return {'message': 'OTP sent successfully'};
  }

  Future<void> setToken(String token) async {
    // Supabase manages its own session tokens locally,
    // but you can set the session manually if needed:
    // await _supabase.auth.setSession(token);
  }

  Future<String?> getToken() async {
    return _supabase.auth.currentSession?.accessToken;
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
    // 1. Sign up with Supabase Auth
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'firstname': firstName,
        'lastname': lastName,
        'role': role.name,
      },
    );

    final userId = authResponse.user?.id;

    if (userId != null) {
      // 2. Insert corresponding record directly into your users table
      final profileData = {
        'id': userId,
        'username': username,
        'email': email,
        'firstname': firstName,
        'lastname': lastName,
        'role': role.name,
        'address': address,
        'phone': phone,
        'id_image_url': idImageUrl,
        if (initialShare != null) 'initial_share': initialShare,
      };

      await _supabase.from('users').upsert(profileData);
    }

    return {
      'user': authResponse.user,
      'session': authResponse.session,
    };
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final email = _supabase.auth.currentUser?.email;

      if (email == null) return null;


      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();


      if (response != null) {
        return UserModel.fromJson(response);
      }


      debugPrint(
        'DEBUG: No profile found for email: $email',
      );

    } catch (e) {
      debugPrint(
        'DEBUG: [AuthRepository] Error fetching user by email: $e',
      );
    }

    return null;
  }


  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

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
    // Handled natively by Supabase Auth (e.g. OTP verification)
    // Example for verifying an OTP token:
    // final response = await _supabase.auth.verifyOTP(email: email, token: code, type: OtpType.signup);
    return {'message': 'MFA verification should use supabase.auth.verifyOTP'};
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String address,
    String? avatarUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('No authenticated user found.');

    final updateData = {
      'firstname': firstName,
      'lastname': lastName,
      'address': address,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    final response = await _supabase
        .from('users')
        .update(updateData)
        .eq('id', userId)
        .select()
        .single();

    return response;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    debugPrint('DEBUG: [AuthRepository] Calling Supabase resetPasswordForEmail for: $email');

    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://lendingpis-production.up.railway.app/PIS/',
      );

      return {
        'success': true,
        'message': 'Password reset email sent.',
      };
    } catch (e) {
      debugPrint('DEBUG: [AuthRepository] forgotPassword error: $e');
      rethrow;
    }
  }


  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    debugPrint('DEBUG: [AuthRepository] Calling Supabase updateUser password');
    try {
      // Note: Typically Supabase handles recovery via a deep link session,
      // but if using a custom token/code verification:
      await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.recovery,
      );

      final response = await _supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      return {'success': true, 'user': response.user};
    } catch (e) {
      debugPrint('DEBUG: [AuthRepository] resetPassword error: $e');
      rethrow;
    }
  }
}
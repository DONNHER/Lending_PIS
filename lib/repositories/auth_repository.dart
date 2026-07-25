import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';


class AuthRepository {

  final SupabaseClient _supabase =
      Supabase.instance.client;

  final ApiService _api;


  AuthRepository(this._api);



  // ===========================
  // LOGIN
  // Supabase -> Laravel Sanctum
  // ===========================

  // ===========================
  // LOGIN (Conditional: Pending -> OTP, Else -> Password)
  // Supabase -> Laravel Sanctum
  // ===========================

  Future<Map<String, dynamic>> login(
      String email, {
        String? password,
        String? captchaToken,
      }) async {

    // 1. First, check the user's details via your backend or database route to verify status
    UserModel? userProfile = await getUserByEmail(email);

    if (userProfile == null) {
      throw Exception("User account not found");
    }

    // Check if user status is pending (adjust depending on how your model handles status values)
    bool isPending = userProfile.status == UserStatus.pending;

    AuthResponse supabaseResponse;

    if (isPending) {
      // 2A. If pending, trigger passwordless OTP sign-in via Supabase
      await _supabase.auth.signInWithOtp(
        email: email,
        captchaToken: captchaToken,
      );

      return {
        'success': true,
        'requiresOtp': true, // Signal to the viewmodel/UI that an OTP code must be entered next
        'message': 'Account is pending. OTP sent to your email.',
      };
    } else {
      // 2B. If not pending, password is required for normal sign-in
      if (password == null || password.isEmpty) {
        throw Exception("Password required");
      }

      supabaseResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
        captchaToken: captchaToken,
      );
    }

    final session = supabaseResponse.session;

    if (session == null) {
      throw Exception("Supabase authentication failed");
    }

    // 3. Get Supabase JWT
    final supabaseJwt = session.accessToken;

    // 4. Exchange JWT for Laravel Sanctum Token
    final response = await _api.post(
      '/login',
      body: {
        'email': email,
        'supabase_token': supabaseJwt,
        if (captchaToken != null) 'captcha_token': captchaToken,
      },
    );

    if (response == null || response['token'] == null) {
      throw Exception("Laravel authentication failed");
    }

    // 5. Store Laravel Sanctum token
    final sanctumToken = response['token'];
    await setToken(sanctumToken);

    return {
      'success': true,
      'requiresOtp': false,
      'user': response['user'],
      'token': sanctumToken,
      'session': session,
    };
  }





  // ===========================
  // TOKEN HANDLING
  // ===========================


  Future<void> setToken(
      String token
      ) async {

    await _api.setToken(token);

  }



  Future<String?> getToken()
  async {

    return await _api.getToken();

  }



  Future<void> clearToken()
  async {

    await _api.clearToken();

  }





  // ===========================
  // REGISTER
  // ===========================

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

    final response = await _api.post(
      '/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
        'firstname': firstName,
        'lastname': lastName,
        'role': role.name,
        'address': address,
        'phone': phone,
        'id_image_url': idImageUrl,
        'initial_share': initialShare,
      },
    );

    return response;
  }





  // ===========================
  // CURRENT USER
  // FROM LARAVEL
  // ===========================


  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _api.get('/user');

      debugPrint("========== /user ==========");
      debugPrint(response.toString());
      debugPrint("===========================");

      if (response != null) {
        return UserModel.fromJson(response);
      }
    } catch (e) {
      debugPrint("getCurrentUser error: $e");
    }

    return null;
  }





  // ===========================
  // USER BY EMAIL
  // ===========================


  Future<UserModel?> getUserByEmail(
      String email
      ) async {


    try {


      final response =
      await _api.get(
        '/user/by-email',
        queryParams: {

          'email':email

        },
      );


      if(response != null){

        return UserModel.fromJson(
            response
        );

      }


    }
    catch(e){

      debugPrint(
          "getUserByEmail error: $e"
      );

    }


    return null;

  }







  // ===========================
  // UPDATE PROFILE
  // ===========================


  Future<Map<String,dynamic>>
  updateProfile({

    required String firstName,

    required String lastName,

    required String address,

    String? avatarUrl,


  }) async {



    final response =
    await _api.post(

      '/user/profile',

      body: {


        'firstname':
        firstName,


        'lastname':
        lastName,


        'address':
        address,


        if(avatarUrl != null)

          'avatar_url':
          avatarUrl,


      },

    );


    return response;

  }





  // ===========================
  // FORGOT PASSWORD
  // Supabase handles email
  // ===========================


  Future<Map<String,dynamic>>
  forgotPassword(
      String email
      ) async {



    await _supabase.auth
        .resetPasswordForEmail(

      email,


      redirectTo:
      'https://lendingpis-production.up.railway.app/PIS/',

    );



    return {


      'success':true,


      'message':
      'Password reset email sent'


    };


  }







  // ===========================
  // RESET PASSWORD
  // ===========================


  Future<Map<String,dynamic>>
  resetPassword({

    required String email,

    required String code,

    required String password,


  }) async {



    await _supabase.auth.verifyOTP(

      email:email,

      token:code,

      type:OtpType.recovery,

    );



    final result =
    await _supabase.auth.updateUser(

      UserAttributes(

        password:password,

      ),

    );



    return {


      'success':true,


      'user':
      result.user,


    };

  }





  // ===========================
  // LOGOUT
  // ===========================


  Future<void> logout()
  async {


    try {


      await _api.post(
          '/logout'
      );


    }
    catch(e){

      debugPrint(
          "Laravel logout error: $e"
      );

    }



    await _supabase.auth.signOut();



    await clearToken();


  }



}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final SupabaseClient _client;

  const AuthRepository(this._client);

  /// Register a new user via Supabase Auth.
  /// The trigger handle_new_user() automatically inserts the profile
  /// row into public.users using the metadata passed here.
  /// Returns the created UserModel on success.
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
    required String firstname,
    required String lastname,
    required String middlename,
    required UserRole role,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'firstname': firstname,
          'lastname': lastname,
          'middlename': middlename,
          'role': role.name,
        },
      );

      if (response.user == null) {
        throw const AuthException('Registration failed. Please try again.');
      }

      // The trigger may take a brief moment — fetch the profile row
      return await _fetchProfile(response.user!.id);
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(_parseAuthError(e.message));
    } catch (e) {
      throw AuthException('Registration failed: $e');
    }
  }

  /// Login with email and password.
  /// Returns the UserModel from public.users linked via auth_id.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('Login failed. Please check your credentials.');
      }

      return await _fetchProfile(response.user!.id);
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(_parseAuthError(e.message));
    } catch (e) {
      throw AuthException('Login failed: $e');
    }
  }

  /// Sign out the current user
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Check if username is already taken
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _client
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      return response == null;
    } catch (e) {
      throw const AuthException('Failed to check username availability.');
    }
  }

  /// Fetch the public.users profile row for the given auth UUID.
  /// Retries with backoff because the handle_new_user() trigger fires
  /// asynchronously — the profile row may not exist the instant signUp returns.
  Future<UserModel> _fetchProfile(String authId) async {
    const maxAttempts = 6;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      await Future.delayed(Duration(milliseconds: 300 * attempt));
      try {
        final data = await _client
            .from('users')
            .select()
            .eq('auth_id', authId)
            .maybeSingle();

        if (data != null) return UserModel.fromJson(data);
      } catch (_) {
        // row not ready yet — keep retrying
      }
    }
    throw const AuthException(
        'Profile setup took too long. Please try logging in.');
  }

  /// Restore session on app launch — returns UserModel if a valid
  /// session already exists (user was previously logged in).
  Future<UserModel?> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchProfile(user.id);
    } catch (_) {
      return null;
    }
  }

  String _parseAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('User already registered')) {
      return 'This email is already registered.';
    }
    if (message.contains('Password should be')) {
      return 'Password must be at least 6 characters.';
    }
    return message;
  }
}
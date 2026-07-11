import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:capstone_application/models/user_model.dart';
import 'package:capstone_application/repositories/auth_repository.dart';
import 'package:capstone_application/repositories/activity_log_repository.dart';
import 'package:capstone_application/repositories/storage_repository.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  mfaRequired,
}

class AuthViewModel extends ChangeNotifier {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final AuthRepository _authRepository;
  final ActivityLogRepository _activityLogRepository;
  final _supabase = Supabase.instance.client;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _rememberedEmail;
  bool _isMfaRequired = false;
  String? _pendingMfaEmail;
  bool _agreeToTerms = false;

  Uint8List? _avatarBytes;
  bool _removeAvatarRequested = false;

  AuthViewModel(
    this._authRepository,
    this._activityLogRepository,
    StorageRepository storageRepository,
  );

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;
  String? get rememberedEmail => _rememberedEmail;
  bool get isMfaRequired => _isMfaRequired;
  String? get pendingMfaEmail => _pendingMfaEmail;
  bool get agreeToTerms => _agreeToTerms;

  Uint8List? get avatarBytes => _avatarBytes;
  bool get removeAvatarRequested => _removeAvatarRequested;

  AuthStatus get status {
    if (!_isInitialized) return AuthStatus.uninitialized;
    if (_isMfaRequired) return AuthStatus.mfaRequired;
    return _currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  String? get dashboardRoute {
    if (_currentUser == null) return null;
    switch (_currentUser!.role) {
      case UserRole.admin:
        return '/dashboard';
      case UserRole.cashier:
        return '/dashboard';
      case UserRole.shareholder:
        return '/shareholder-dashboard';
    }
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void setAgreeToTerms(bool value) {
    _agreeToTerms = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> pickAvatar() async {
    // Logic to pick avatar image and set _avatarBytes
    notifyListeners();
  }

  void removeAvatar() {
    _avatarBytes = null;
    _removeAvatarRequested = true;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authRepository.getCurrentUser();
    } catch (e) {
      _currentUser = null;
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _isMfaRequired = false;
    notifyListeners();

    try {
      final response = await _authRepository.login(email, password);
      
      if (response['mfa_required'] == true) {
        await _supabase.auth.signInWithOtp(email: email);
        _isMfaRequired = true;
        _pendingMfaEmail = email;
        return false;
      }

      if (response['token'] != null && response['user'] != null) {
        // 1. Set the user locally immediately
        _currentUser = UserModel.fromJson(response['user']);
        
        // 2. Log activity but don't let it block login if it fails
        try {
          await _activityLogRepository.logActivity(
            action: 'Login',
            details: 'User ${_currentUser!.email} logged in',
          );
        } catch (e) {
          debugPrint('DEBUG: [AuthViewModel] Activity logging failed but login proceeding: $e');
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('DEBUG: [AuthViewModel] Login Error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );
      
      // Trigger Supabase Verification Email
      await _supabase.auth.signInWithOtp(email: email);
      
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyMfa(String email, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Verify with Supabase
      final res = await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.signup,
      );

      if (res.session != null) {
        // 2. Tell Laravel that MFA is complete and get the Laravel token
        final response = await _authRepository.verifyMfa(email);
        if (response['success'] == true) {
          _currentUser = UserModel.fromJson(response['user']);
          _isMfaRequired = false;
          return true;
        }
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use Supabase to send the reset email
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Verify OTP with Supabase
      await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.recovery,
      );

      // 2. Update password in Supabase
      await _supabase.auth.updateUser(UserAttributes(password: password));
      
      // 3. Sync with Laravel
      await _authRepository.resetPassword(
        email: email,
        code: code,
        password: password,
      );
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // In a real app, you'd call a repository method here
      await Future.delayed(const Duration(seconds: 1));
      // Update local user model
      if (_currentUser != null) {
        _currentUser = UserModel(
          id: _currentUser!.id,
          username: _currentUser!.username,
          email: _currentUser!.email,
          firstName: firstName,
          lastName: lastName,
          role: _currentUser!.role,
          status: _currentUser!.status,
          address: address,
          avatarUrl: _currentUser!.avatarUrl,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update in Supabase
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      await _authRepository.logout();
    } finally {
      _currentUser = null;
      notifyListeners();
    }
  }

  void handleUnauthorized() {
    _currentUser = null;
    _errorMessage = 'Session expired. Please login again.';
    notifyListeners();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

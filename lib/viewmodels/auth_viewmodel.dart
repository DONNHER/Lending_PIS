import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final StorageRepository _storageRepository;
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
  bool _isCaptchaRequired = false;
  bool _isCaptchaVerified = false;

  Uint8List? _avatarBytes;
  bool _removeAvatarRequested = false;

  // 🚀 Impersonation State
  UserModel? _originalAdminUser;
  String? _originalAdminToken;

  // 🛑 Guard to prevent infinite logout/401 loops
  bool _isLoggingOut = false;

  AuthViewModel(
    this._authRepository,
    this._activityLogRepository,
    this._storageRepository,
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
  bool get isCaptchaRequired => _isCaptchaRequired;
  bool get isCaptchaVerified => _isCaptchaVerified;
  String? get pendingMfaEmail => _pendingMfaEmail;
  bool get agreeToTerms => _agreeToTerms;

  Uint8List? get avatarBytes => _avatarBytes;
  bool get removeAvatarRequested => _removeAvatarRequested;

  bool get isImpersonating => _originalAdminUser != null;
  UserModel? get originalAdminUser => _originalAdminUser;

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

  void setCaptchaVerified(bool value) {
    _isCaptchaVerified = value;
    notifyListeners();
  }

  Future<void> pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      
      if (image != null) {
        _avatarBytes = await image.readAsBytes();
        _removeAvatarRequested = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Error picking avatar: $e');
    }
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

  String _mapAuthError(Object e) {
    if (e is AuthException) {
      final message = e.message.toLowerCase();
      if (message.contains('invalid') || message.contains('incorrect') || message.contains('not match')) {
        return 'The verification code is incorrect. Please check your email and try again.';
      }
      if (message.contains('expired')) {
        return 'The verification code has expired. Please request a new one.';
      }
      if (message.contains('too many')) {
        return 'Too many attempts. Please wait a moment before trying again.';
      }
      if (message.contains('network') || message.contains('connection')) {
        return 'Connection error. Please check your internet and try again.';
      }
      return e.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  Future<void> resendVerificationEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      _errorMessage = 'Verification email resent successfully. Please check your inbox.';
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Manual resend error: $e');
      _errorMessage = 'Failed to resend verification email: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, {bool isAdminLogin = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _isMfaRequired = false;
    notifyListeners();

    try {
      final response = await _authRepository.login(
        email, 
        password,
        captchaToken: _isCaptchaVerified ? 'verified' : null,
      );
      
      debugPrint('DEBUG: [AuthViewModel] Login response: $response');

      if (response['captcha_required'] == true) {
        _isCaptchaRequired = true;
        _isCaptchaVerified = false;
        _errorMessage = 'Security check required. Please complete the CAPTCHA.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (response['mfa_required'] == true) {
        // 🚀 STRICT CHECK: Ensure account is confirmed in Supabase
        try {
          debugPrint('DEBUG: [AuthViewModel] Checking Supabase confirmation for: $email');
          
          final authRes = await _supabase.auth.signInWithPassword(email: email, password: password);
          
          debugPrint('DEBUG: [AuthViewModel] Supabase Sign-In Success. User ID: ${authRes.user?.id}');
          debugPrint('DEBUG: [AuthViewModel] Email Confirmed At: ${authRes.user?.emailConfirmedAt}');
          
          await _supabase.auth.signOut();
          
        } on AuthException catch (e) {
          debugPrint('DEBUG: [AuthViewModel] Supabase Auth Error: ${e.message}');
          debugPrint('DEBUG: [AuthViewModel] Supabase Error Code: ${e.statusCode}');

          if (e.message.toLowerCase().contains('email not confirmed')) {
            debugPrint('DEBUG: [AuthViewModel] Email not confirmed. Triggering resend...');
            
            try {
              await _supabase.auth.resend(
                type: OtpType.signup,
                email: email,
              );
              _errorMessage = 'Account not verified. A new verification link has been sent to your email. Please check your inbox.';
            } catch (resendError) {
              debugPrint('DEBUG: [AuthViewModel] Resend failed: $resendError');
              _errorMessage = 'Account not verified. We tried to send a new link but failed. Please try again later.';
            }

            _isLoading = false;
            notifyListeners();
            return false;
          }
          
          _errorMessage = _mapAuthError(e);
          _isLoading = false;
          notifyListeners();
          return false;
        } catch (unexpected) {
          debugPrint('DEBUG: [AuthViewModel] Unexpected Supabase Error: $unexpected');
          _errorMessage = 'Account synchronization error. Please try again later.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        try {
          debugPrint('DEBUG: [AuthViewModel] Triggering OTP via Supabase...');
          await _supabase.auth.signInWithOtp(email: email);
          debugPrint('DEBUG: [AuthViewModel] OTP successfully sent.');
          _isMfaRequired = true;
          _pendingMfaEmail = email;
          _isLoading = false;
          notifyListeners();
          return false;
        } catch (otpError) {
          debugPrint('DEBUG: [AuthViewModel] OTP Send Error: $otpError');
          _errorMessage = _mapAuthError(otpError);
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (response['token'] != null && response['user'] != null) {
        final user = UserModel.fromJson(response['user']);
        
        if (isAdminLogin) {
          if (user.role != UserRole.admin) {
            _errorMessage = 'Access denied. This login is for Administrators only.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else {
          if (user.role == UserRole.admin) {
            _errorMessage = 'Administrators must use the secure Admin Login portal.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }

        _currentUser = user;
        
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
    String? address,
    String? phone,
    String? idImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('DEBUG: [AuthViewModel] Registering in Supabase...');
      try {
        await _supabase.auth.signUp(email: email, password: password);
        debugPrint('DEBUG: [AuthViewModel] Supabase signUp success.');
      } on AuthException catch (e) {
        if (e.message.toLowerCase().contains('already registered') || 
            e.message.toLowerCase().contains('already been registered')) {
          debugPrint('DEBUG: [AuthViewModel] User already in Supabase, proceeding to Laravel sync...');
        } else {
          rethrow;
        }
      }

      debugPrint('DEBUG: [AuthViewModel] Registering in Laravel...');
      await _authRepository.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
        address: address,
        phone: phone,
        idImageUrl: idImageUrl,
      );
      
      debugPrint('DEBUG: [AuthViewModel] Registration complete.');
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('DEBUG: [AuthViewModel] Registration Error: $_errorMessage');
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
      debugPrint('DEBUG: [AuthViewModel] Attempting MFA verification for $email...');
      
      AuthResponse? res;
      try {
        res = await _supabase.auth.verifyOTP(
          email: email,
          token: code,
          type: OtpType.signup,
        );
        debugPrint('DEBUG: [AuthViewModel] Signup OTP verification success.');
      } catch (e) {
        debugPrint('DEBUG: [AuthViewModel] Signup OTP failed, trying Magiclink OTP...');
        res = await _supabase.auth.verifyOTP(
          email: email,
          token: code,
          type: OtpType.magiclink,
        );
        debugPrint('DEBUG: [AuthViewModel] Magiclink OTP verification success.');
      }

      if (res.session != null) {
        final response = await _authRepository.verifyMfa(email);
        if (response['success'] == true) {
          _currentUser = UserModel.fromJson(response['user']);
          _isMfaRequired = false;
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] All MFA verification attempts failed: $e');
      _errorMessage = _mapAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendMfa(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.auth.signInWithOtp(email: email);
      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
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
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://lendingpis-production.up.railway.app/PIS/#/change-password',
      );

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to send reset email. Please try again.';
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
      final effectiveUser = isImpersonating ? _originalAdminUser : _currentUser;
      String? avatarUrl = effectiveUser?.avatarUrl;

      if (_avatarBytes != null) {
        debugPrint('DEBUG: [AuthViewModel] Uploading new avatar...');
        avatarUrl = await _storageRepository.uploadBytes(
          bucket: 'avatars',
          path: 'users',
          fileName: 'avatar.jpg',
          bytes: _avatarBytes!,
        );
      } else if (_removeAvatarRequested) {
        avatarUrl = null;
      }

      final response = await _authRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        address: address,
        avatarUrl: avatarUrl,
      );

      if (response['success'] == true) {
        final updatedUser = UserModel.fromJson(response['user']);
        if (isImpersonating) {
          _originalAdminUser = updatedUser;
        } else {
          _currentUser = updatedUser;
        }
        _avatarBytes = null;
        _removeAvatarRequested = false;
        notifyListeners();
        return true;
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

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final email = _supabase.auth.currentUser?.email;

      if (email == null) {
        _errorMessage = 'No authenticated user.';
        return false;
      }

      await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      await _supabase.auth.signOut();

      return true;
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        _errorMessage = 'Current password is incorrect.';
      } else {
        _errorMessage = e.message;
      }
      return false;
    } catch (_) {
      _errorMessage = 'Unable to change password.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Supabase SignOut error: $e');
    }

    try {
      await _authRepository.logout();
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Backend logout error (ignored): $e');
    } finally {
      _currentUser = null;
      _originalAdminUser = null;
      _originalAdminToken = null;
      _isMfaRequired = false;
      _pendingMfaEmail = null;
      
      _isLoading = false;
      _isLoggingOut = false;
      notifyListeners();

      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void handleUnauthorized() {
    if (_currentUser == null || _isLoggingOut) return;
    logout();
  }

  Future<void> startImpersonation(Map<String, dynamic> response) async {
    if (_currentUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      _originalAdminUser = _currentUser;
      _originalAdminToken = await _authRepository.getToken();

      if (response['token'] != null && response['user'] != null) {
        final targetUser = UserModel.fromJson(response['user']);
        await _authRepository.setToken(response['token']);
        _currentUser = targetUser;
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Start Impersonation Error: $e');
      _errorMessage = 'Failed to start impersonation session.';
      _originalAdminUser = null;
      _originalAdminToken = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> stopImpersonation() async {
    if (_originalAdminUser == null || _originalAdminToken == null) return;

    _currentUser = _originalAdminUser;
    await _authRepository.setToken(_originalAdminToken!);

    _originalAdminUser = null;
    _originalAdminToken = null;

    notifyListeners();
  }
}

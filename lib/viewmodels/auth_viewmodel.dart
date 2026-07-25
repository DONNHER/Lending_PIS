import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // 🛑 Guard to prevent infinite logout/401 loops
  bool _isLoggingOut = false;

  AuthViewModel(
      this._authRepository,
      this._activityLogRepository,
      this._storageRepository,
      ) {
    // 🚀 Automatically load remembered credentials on initialization
    _loadRememberedPreference();
  }

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

  // 🚀 Load saved email and flag from SharedPreferences
  Future<void> _loadRememberedPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool('remember_me_flag') ?? false;
      if (_rememberMe) {
        _rememberedEmail = prefs.getString('remembered_email_value');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Error loading remembered preference: $e');
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

      final token = await _authRepository.getToken();

      if (token != null) {

        _currentUser =
        await _authRepository.getCurrentUser();

      } else {

        _currentUser = null;

      }

    } catch (e) {

      debugPrint(
        'DEBUG: [AuthViewModel] Session restoration failed: $e',
      );

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

  Future<bool> login(String email, String password, {String? captchaToken, bool isAdminLogin = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _isMfaRequired = false;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me_flag', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('remembered_email_value', email);
        _rememberedEmail = email;
      } else {
        await prefs.remove('remembered_email_value');
        _rememberedEmail = null;
      }

      debugPrint('DEBUG: [AuthViewModel] Attempting Supabase sign-in for email: $email (isAdminLogin: $isAdminLogin)');

      // 1. Authenticate directly against Supabase Auth
      final loginResult = await _authRepository.login(
        email,
        password: password,
        captchaToken: captchaToken,
      );
      if (loginResult['requiresOtp'] == true) {
        _currentUser = null;
        _pendingMfaEmail = email;
        _isMfaRequired = true;

        _isLoading = false;
        notifyListeners();

        return true;
      }

      debugPrint('==============================');
      debugPrint('LOGIN SUCCESS');
      debugPrint('Login User    : ${loginResult['user']}');
      debugPrint('Login Session : ${loginResult['session']}');
      debugPrint('Supabase ID   : ${_supabase.auth.currentUser?.id}');
      debugPrint('Supabase Email: ${_supabase.auth.currentUser?.email}');
      debugPrint('==============================');

      if (loginResult['user'] != null && loginResult['session'] != null) {
        UserModel? user = await _authRepository.getCurrentUser();
        if (user?.status == UserStatus.pending) {
          debugPrint(
              'DEBUG: [AuthViewModel] User account is pending verification.');

          _pendingMfaEmail = user?.email;
          _isMfaRequired = true;
          _errorMessage = null;

          await logout(); // optional, see note below

          return true;
        }

        if (user == null) {
          debugPrint(
            'DEBUG: [AuthViewModel] Error: User profile data could not be retrieved.',
          );

          _errorMessage =
          'User profile data could not be retrieved.';

          await logout();

          return false;
        }


        debugPrint('DEBUG: [AuthViewModel] User role resolved: ${user.role}. Validating permissions...');

      // Role validation checks...
        if (isAdminLogin) {
          if (user.role != UserRole.admin) {
            debugPrint(
              'DEBUG: [AuthViewModel] Access denied: Non-admin tried entering Admin Portal.',
            );

            _errorMessage =
            'Access denied. This login is for Administrators only.';

            await logout();

            return false;
          }
        }
        else {
          if (user.role == UserRole.admin) {
            debugPrint(
              'DEBUG: [AuthViewModel] Access denied: Admin tried logging in via regular portal.',
            );

            _errorMessage =
            'Administrators must use the secure Admin Login portal.';

            await logout();

            return false;
          }
        }


        _currentUser = user;
        _isCaptchaRequired = false; // Clear on success
        debugPrint('DEBUG: [AuthViewModel] Login completed successfully for user: ${user.email}');
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Supabase AuthException caught: ${e.message} (StatusCode: ${e.statusCode})');
      _errorMessage = e.message;
      return false;
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] General login exception caught: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
      debugPrint('DEBUG: [AuthViewModel] Supabase registration success.');

      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      debugPrint('DEBUG: [AuthViewModel] Registration AuthException: $_errorMessage');
      return false;
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

      final res = await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );

      if (res.session != null) {
        final userModel = await _authRepository.getCurrentUser();
        if (userModel != null) {
          _currentUser = userModel;
          _isMfaRequired = false;
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] MFA verification failed: $e');
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
      debugPrint('DEBUG: [AuthViewModel] Resend MFA error: $e');
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
      debugPrint('DEBUG: [AuthViewModel] Requesting password reset for: $email');

      final response = await _authRepository.forgotPassword(email);
      debugPrint('DEBUG: [AuthViewModel] Password reset request successful: $response');

      return true;
    } on AuthException catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Forgot password AuthException: ${e.message}');
      _errorMessage = e.message;
      return false;
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Forgot password error: $e');
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

      if (response != null) {
        final updatedUser = UserModel.fromJson(response);
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
      debugPrint('DEBUG: [AuthViewModel] Profile update error: $e');
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
        debugPrint('DEBUG: [AuthViewModel] Change password error: No authenticated user.');
        _errorMessage = 'No authenticated user.';
        return false;
      }

      debugPrint('DEBUG: [AuthViewModel] Authenticating user in Supabase to change password...');
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
      debugPrint('DEBUG: [AuthViewModel] Change password AuthException: ${e.message}');
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        _errorMessage = 'Current password is incorrect.';
      } else {
        _errorMessage = e.message;
      }
      return false;
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Change password error: $e');
      _errorMessage = 'Unable to change password: ${e.toString().replaceAll('Exception: ', '')}';
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
      await _authRepository.logout();
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Supabase SignOut error: $e');
    } finally {
      _currentUser = null;
      _originalAdminUser = null;
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

  Future<void> startImpersonation(UserModel targetUser) async {
    if (_currentUser == null || _currentUser!.role != UserRole.admin) return;

    try {
      _isLoading = true;
      notifyListeners();

      // 🔧 Refetch full profile (with shareholder relation) instead of trusting
      // the partial UserModel from the admin's user list
      final fullUser = await _authRepository.getUserByEmail(targetUser.email) ?? targetUser;

      debugPrint("========== IMPERSONATION ==========");
      debugPrint("User ID: ${fullUser.id}");
      debugPrint("Shareholder ID: ${fullUser.shareholder?.id}");
      debugPrint("===================================");

      _originalAdminUser = _currentUser;
      _currentUser = fullUser;

      notifyListeners();
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Start Impersonation Error: $e');
      _errorMessage = 'Failed to start impersonation session.';
      _originalAdminUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> stopImpersonation() async {
    if (_originalAdminUser == null) return;

    _currentUser = _originalAdminUser;
    _originalAdminUser = null;

    notifyListeners();
  }
}
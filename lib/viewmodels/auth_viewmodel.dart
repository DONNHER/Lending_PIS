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

  Uint8List? _avatarBytes;
  bool _removeAvatarRequested = false;

  // 🚀 Impersonation State
  UserModel? _originalAdminUser;
  String? _originalAdminToken;

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

  Future<bool> login(String email, String password, {bool isAdminLogin = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _isMfaRequired = false;
    notifyListeners();

    try {
      final response = await _authRepository.login(email, password);
      
      if (response['mfa_required'] == true) {
        // 🚀 STRICT CHECK: Ensure account is confirmed in Supabase
        try {
          debugPrint('DEBUG: [AuthViewModel] Checking Supabase confirmation for: $email');
          
          // Attempt a silent sign-in to check confirmation status
          final authRes = await _supabase.auth.signInWithPassword(email: email, password: password);
          
          debugPrint('DEBUG: [AuthViewModel] Supabase Sign-In Success. User ID: ${authRes.user?.id}');
          debugPrint('DEBUG: [AuthViewModel] Email Confirmed At: ${authRes.user?.emailConfirmedAt}');
          
          // If we reach here, password is correct and account IS confirmed.
          await _supabase.auth.signOut();
          
        } on AuthException catch (e) {
          debugPrint('DEBUG: [AuthViewModel] Supabase Auth Error: ${e.message}');
          debugPrint('DEBUG: [AuthViewModel] Supabase Error Code: ${e.statusCode}');

          // Block if email is not confirmed
          if (e.message.toLowerCase().contains('email not confirmed')) {
            _errorMessage = 'Account not verified. Please check your inbox and click "Verify this email" in your welcome email first.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
          
          // Improved error message to show actual Supabase error for debugging
          _errorMessage = 'Verification Error: ${e.message}';
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

        // ONLY if the above check passed (no exception thrown), we send the OTP
        try {
          debugPrint('DEBUG: [AuthViewModel] Triggering OTP via Supabase...');
          await _supabase.auth.signInWithOtp(email: email);
          debugPrint('DEBUG: [AuthViewModel] OTP successfully sent.');
          _isMfaRequired = true;
          _pendingMfaEmail = email;
          return false;
        } catch (otpError) {
          debugPrint('DEBUG: [AuthViewModel] OTP Send Error: $otpError');
          _errorMessage = 'Failed to send verification code. Please try again.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (response['token'] != null && response['user'] != null) {
        final user = UserModel.fromJson(response['user']);
        
        // 🚀 ROLE-BASED LOGIN BLOCKING
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

        // 1. Set the user locally immediately
        _currentUser = user;
        
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
    String? address,
    String? phone,
    String? idImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 🚀 1. REGISTER IN SUPABASE FIRST
      debugPrint('DEBUG: [AuthViewModel] Registering in Supabase...');
      try {
        await _supabase.auth.signUp(email: email, password: password);
        debugPrint('DEBUG: [AuthViewModel] Supabase signUp success.');
      } on AuthException catch (e) {
        // If user already exists in Supabase, we can proceed to sync with Laravel
        if (e.message.toLowerCase().contains('already registered') || 
            e.message.toLowerCase().contains('already been registered')) {
          debugPrint('DEBUG: [AuthViewModel] User already in Supabase, proceeding to Laravel sync...');
        } else {
          rethrow;
        }
      }

      // 🚀 2. REGISTER IN LARAVEL
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
      
      // 🚀 TRY SIGNUP OTP FIRST (for new accounts)
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
        // 🚀 TRY MAGICLINK OTP SECOND (for existing confirmed accounts)
        res = await _supabase.auth.verifyOTP(
          email: email,
          token: code,
          type: OtpType.magiclink,
        );
        debugPrint('DEBUG: [AuthViewModel] Magiclink OTP verification success.');
      }

      if (res != null && res.session != null) {
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
      debugPrint('DEBUG: [AuthViewModel] All MFA verification attempts failed: $e');
      _errorMessage = e.toString();
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
      String? avatarUrl = _currentUser?.avatarUrl;

      // 1. Handle Avatar Upload
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

      // 2. Sync with Laravel
      final response = await _authRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        address: address,
        avatarUrl: avatarUrl,
      );

      if (response['success'] == true) {
        _currentUser = UserModel.fromJson(response['user']);
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

  Future<void> startImpersonation(Map<String, dynamic> response) async {
    if (response['token'] == null || response['user'] == null) return;

    // 1. Save original admin state
    _originalAdminUser = _currentUser;
    _originalAdminToken = await _authRepository.getToken();

    // 2. Switch to target user
    _currentUser = UserModel.fromJson(response['user']);
    await _authRepository.setToken(response['token']);

    notifyListeners();
  }

  Future<void> stopImpersonation() async {
    if (_originalAdminUser == null || _originalAdminToken == null) return;

    // 1. Restore original admin state
    _currentUser = _originalAdminUser;
    await _authRepository.setToken(_originalAdminToken!);

    // 2. Clear impersonation data
    _originalAdminUser = null;
    _originalAdminToken = null;

    notifyListeners();
  }
}

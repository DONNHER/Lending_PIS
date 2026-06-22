import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:capstone_application/models/user_model.dart';
import 'package:capstone_application/models/activity_log_model.dart';
import 'package:capstone_application/repositories/auth_repository.dart';
import 'package:capstone_application/repositories/activity_log_repository.dart';
import 'package:capstone_application/repositories/storage_repository.dart';
import 'package:capstone_application/services/authorization_service.dart';
import 'package:capstone_application/services/role_based_router.dart';
import 'package:capstone_application/services/local_cache_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  mfaRequired,
  mfaEnrollment, 
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  final ActivityLogRepository? _activityLogRepo;
  final StorageRepository? _storageRepository;
  final LocalCacheService _cacheService = LocalCacheService();
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  String? _pendingMfaEmail;
  OtpType _pendingOtpType = OtpType.email; 
  bool _isSyncing = false;
  bool _isInitialized = false;
  bool _isPasswordRecoveryMode = false;

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _rememberMe = false;
  String? _rememberedEmail;
  
  Uint8List? _avatarBytes;
  Uint8List? _idImageBytes;

  // Supabase MFA State
  AuthMFAEnrollResponse? _mfaEnrollResponse;
  List<dynamic> _mfaFactors = [];

  AuthViewModel(this._repository, [this._activityLogRepo, this._storageRepository]) {
    _pendingOtpType = OtpType.email; // 🚀 Force initialization
    _initSupabaseListener();
    _checkInitialUrl();
    _loadRememberedEmail();
  }

  // 🚀 Step 1: URL detection (Optional if using OTP, but kept for compatibility)
  Future<void> _checkInitialUrl() async {
    if (kIsWeb) {
      final uri = Uri.base;
      debugPrint('DEBUG: [AuthViewModel] --- STARTUP URL CHECK ---');
      debugPrint('DEBUG: [AuthViewModel] Link: $uri');
      
      final code = uri.queryParameters['code'];
      final type = uri.queryParameters['type'];
      final isRecoveryFragment = uri.fragment.contains('type=recovery');

      if (code != null || type == 'recovery' || isRecoveryFragment) {
        debugPrint('DEBUG: [AuthViewModel] User confirmed the link in email: confrimurl');
        debugPrint('DEBUG: [AuthViewModel] Detection: YES');
        
        _isPasswordRecoveryMode = true;
        notifyListeners();

        if (code != null) {
          try {
            debugPrint('DEBUG: [AuthViewModel] Manually exchanging PKCE code for session...');
            await _supabase.auth.exchangeCodeForSession(code);
            debugPrint('DEBUG: [AuthViewModel] PKCE code exchange SUCCESS.');
          } catch (e) {
            debugPrint('DEBUG: [AuthViewModel] Code exchange redundant or failed: $e');
          }
        }
      }
    }
  }

  void _initSupabaseListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      debugPrint('DEBUG: [AuthViewModel] --- SUPABASE AUTH EVENT ---');
      debugPrint('DEBUG: [AuthViewModel] Event: $event');
      
      if (event == AuthChangeEvent.signedOut || event == AuthChangeEvent.userDeleted) {
        if (_currentUser != null && !_isPasswordRecoveryMode) {
          handleUnauthorized();
        }
      } else if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('DEBUG: [AuthViewModel] User confirmed recovery flow.');
        _isPasswordRecoveryMode = true;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedIn && session != null) {
        // Automatically sync with Laravel if user is already in MFA mode and verifies via link
        if (_status == AuthStatus.mfaRequired && _pendingMfaEmail != null) {
          debugPrint('DEBUG: [AuthViewModel] Auto-verifying via Supabase session event.');
          _syncVerificationWithLaravel('link_verification');
        }
      }
    });
  }

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get pendingMfaEmail => _pendingMfaEmail;
  bool get isPasswordRecoveryMode => _isPasswordRecoveryMode;

  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isMfaRequired => _status == AuthStatus.mfaRequired;
  bool get isInitialized => _isInitialized;
  bool get obscurePassword => _obscurePassword;
  bool get agreeToTerms => _agreeToTerms;
  bool get rememberMe => _rememberMe;
  String? get rememberedEmail => _rememberedEmail;
  Uint8List? get avatarBytes => _avatarBytes;
  Uint8List? get idImageBytes => _idImageBytes;

  AuthMFAEnrollResponse? get mfaEnrollResponse => _mfaEnrollResponse;
  List<dynamic> get mfaFactors => _mfaFactors;

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = isAuthenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final email = await _cacheService.getData('remembered_email');
      if (email != null && email is String) {
        _rememberedEmail = email;
        _rememberMe = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading remembered email: $e');
    }
  }

  Future<void> logActivity(String action, String description) async {
    if (_currentUser != null && _activityLogRepo != null && isAuthenticated) {
      try {
        final log = ActivityLogModel(
          id: '', userId: _currentUser!.id, action: action,
          ipAddress: 'Local Device', createdAt: DateTime.now(), description: description,
        );
        await _activityLogRepo!.logActivity(log);
      } catch (e) {
        debugPrint('Suppressed ActivityLog Error: $e');
      }
    }
  }

  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      if (kIsWeb && Uri.base.queryParameters.containsKey('code')) {
        await Future.delayed(const Duration(milliseconds: 2000)); 
      }

      final session = _supabase.auth.currentSession;
      if (session != null && session.user.appMetadata['recovery'] == true) {
        _isPasswordRecoveryMode = true;
      }

      final user = await _repository.restoreSession();
      if (user != null) {
        if (user.status != UserStatus.active) {
          if (!_isPasswordRecoveryMode) {
            // 🚀 Handle pending status verification during restoration
            if (user.status == UserStatus.pending) {
              debugPrint('DEBUG: [AuthViewModel] Session restored for pending user. Requiring OTP/MFA.');
              _pendingMfaEmail = user.email;
              
              // 🚀 Trigger Supabase OTP for restored pending session
              try {
                await _supabase.auth.signInWithOtp(email: _pendingMfaEmail!);
                _pendingOtpType = OtpType.email;
              } catch (e) {
                debugPrint('DEBUG: [AuthViewModel] Supabase OTP trigger failed: $e');
              }

              _status = AuthStatus.mfaRequired;
              notifyListeners();
              return;
            }

            await logout();
            _errorMessage = 'Your account is ${user.status.name}.';
            _status = AuthStatus.error;
            return;
          }
        }
        _currentUser = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
       _status = AuthStatus.unauthenticated;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final normalizedEmail = email.trim().toLowerCase();
      try {
        await _supabase.auth.signInWithPassword(email: normalizedEmail, password: password);
      } on AuthApiException catch (e) {
        if (e.message.toLowerCase().contains('email not confirmed')) {
          try {
            await _supabase.auth.resend(type: OtpType.signup, email: normalizedEmail);
            _pendingOtpType = OtpType.signup;
            _errorMessage = 'Email not confirmed. Check inbox.';
          } catch (_) {
            _errorMessage = 'Email not confirmed. Please verify your email.';
          }
          _pendingMfaEmail = normalizedEmail;
          _status = AuthStatus.mfaRequired;
          notifyListeners();
          return false;
        }
      }

      final result = await _repository.login(email: normalizedEmail, password: password);
      if (result != null) {
        if (_rememberMe) {
          await _cacheService.saveData('remembered_email', normalizedEmail);
          _rememberedEmail = normalizedEmail;
        } else {
          await _cacheService.clearCache('remembered_email');
          _rememberedEmail = null;
        }

        UserModel? user = result['user'] as UserModel?;
        
        // 🚀 CRITICAL: Check if MFA is required OR account is still pending verification
        if (result['mfa_required'] == true || user?.status == UserStatus.pending) {
          debugPrint('DEBUG: [AuthViewModel] MFA required or Account Pending. Triggering Supabase OTP.');
          _pendingMfaEmail = result['email'] ?? normalizedEmail;
          
          // 🚀 Trigger Supabase OTP instead of using Laravel's OTP delivery
          try {
            await _supabase.auth.signInWithOtp(email: _pendingMfaEmail!);
            _pendingOtpType = OtpType.email; 
          } catch (e) {
            debugPrint('DEBUG: [AuthViewModel] Supabase signInWithOtp Error: $e');
          }

          _status = AuthStatus.mfaRequired;
          notifyListeners();
          return false; // Return false so LoginPage navigates to MfaPage
        }

        _currentUser = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Invalid email or password.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_currentUser != null) {
        try {
          await _repository.updateStatus(_currentUser!.id, UserStatus.inactive);
        } catch (_) {}
        await _repository.logout();
      }
      // Don't use clearAll() because we want to keep remembered_email
      await _cacheService.clearCache('auth_token'); 
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Logout Error: $e');
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      _isPasswordRecoveryMode = false;
      notifyListeners();
    }
  }

  void handleUnauthorized() {
    if (_isPasswordRecoveryMode) return;

    if (_status != AuthStatus.unauthenticated) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _repository.clearLocalSession();
      // Only clear cache related to session
      _cacheService.clearCache('auth_token');
      notifyListeners();
    }
  }

  Future<bool> register({required String username, required String email, required String password, required String firstName, required String lastName, required UserRole role}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.register(username: username.trim(), email: email.trim().toLowerCase(), password: password, firstName: firstName.trim(), lastName: lastName.trim(), role: role);
      
      UserModel? user = result['user'] as UserModel?;
      
      if (result['mfa_required'] == true || user?.status == UserStatus.pending) {
         debugPrint('DEBUG: [AuthViewModel] Registration successful. Switching to MFA mode.');
         _pendingMfaEmail = result['email'] ?? email.trim().toLowerCase();
         _pendingOtpType = OtpType.signup; // signUp already triggered OTP in repository
         _status = AuthStatus.mfaRequired;
         notifyListeners();
         return false; // Return false to navigate to MFA page
      }

      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyMfa(String code) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final email = _pendingMfaEmail!.trim().toLowerCase();
      final token = code.trim();
      
      // 🚀 Exhaustive verification type attempt
      final typesToTry = [
        _pendingOtpType,   
        OtpType.email,      
        OtpType.signup,     
        OtpType.magiclink,  
      ].toSet().toList();

      AuthResponse? response;
      dynamic lastError;

      for (final type in typesToTry) {
        try {
          debugPrint('DEBUG: [AuthViewModel] Attempting Supabase Verification (Type: $type) for $email');
          response = await _supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: type,
          );
          if (response.session != null) {
            debugPrint('DEBUG: [AuthViewModel] Supabase OTP Verification SUCCESS ($type).');
            break;
          }
        } catch (e) {
          lastError = e;
          debugPrint('DEBUG: [AuthViewModel] Supabase OTP Verification FAILED ($type): $e');
        }
      }

      if (response?.session != null) {
        return await _syncVerificationWithLaravel(token);
      }
      
      _status = AuthStatus.mfaRequired;
      if (lastError is AuthApiException) {
        _errorMessage = lastError.message;
        if (lastError.code == 'otp_expired' || lastError.message.contains('expired')) {
          _errorMessage = 'The verification code has expired. Please request a new one.';
        }
      } else {
        _errorMessage = 'Invalid or expired verification code.';
      }
      
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Unexpected Verification Error: $e');
      _status = AuthStatus.mfaRequired;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> _syncVerificationWithLaravel(String code) async {
    if (_isSyncing) return true;
    _isSyncing = true;
    
    try {
        debugPrint('DEBUG: [AuthViewModel] Syncing verification with Laravel Backend.');
        UserModel? user = await _repository.verifyMfa(
          email: _pendingMfaEmail!, 
          code: code
        );
        
        if (user != null) {
          _currentUser = user;
          _status = AuthStatus.authenticated;
          _pendingMfaEmail = null;
          notifyListeners();
          return true;
        }
        throw Exception('Failed to synchronize session with server.');
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Laravel Sync Error: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.mfaRequired;
      notifyListeners();
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> resendMfaCode(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      debugPrint('DEBUG: [AuthViewModel] Resending Supabase OTP to $normalizedEmail (Mode: $_pendingOtpType)');
      
      if (_pendingOtpType == OtpType.signup) {
         await _supabase.auth.resend(type: OtpType.signup, email: normalizedEmail);
      } else {
         await _supabase.auth.signInWithOtp(email: normalizedEmail);
         _pendingOtpType = OtpType.email;
      }
      return true;
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Failed to resend Supabase OTP: $e');
      return false;
    }
  }

  Future<void> startMfaEnrollment() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      _mfaEnrollResponse = await _repository.enrollMfa();
      _status = AuthStatus.mfaEnrollment;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> finalizeMfaEnrollment(String code) async {
    if (_mfaEnrollResponse == null) return false;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final challenge = await _repository.challengeMfa(_mfaEnrollResponse!.id);
      await _repository.verifyMfaChallenge(
        factorId: _mfaEnrollResponse!.id,
        challengeId: challenge.id,
        code: code,
      );
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.mfaEnrollment;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('DEBUG: [AuthViewModel] Requesting password reset OTP for: $email');
      await _supabase.auth.resetPasswordForEmail(email.trim().toLowerCase());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // 🚀 NEW: verifyRecoveryCode for OTP-based reset
  Future<bool> verifyRecoveryCode(String email, String code) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint('DEBUG: [AuthViewModel] Verifying Recovery OTP for $email');
      final response = await _supabase.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: code.trim(),
        type: OtpType.recovery,
      );
      
      if (response.session != null) {
        debugPrint('DEBUG: [AuthViewModel] Recovery OTP Verified. Session established.');
        _isPasswordRecoveryMode = true;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('DEBUG: [AuthViewModel] Recovery OTP Verification Failed: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Invalid or expired verification code.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({required String email, required String code, required String newPassword}) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final success = await _repository.resetPassword(email: email, code: code, newPassword: newPassword);
      if (success) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePasswordOnly(String newPassword) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      int retries = 0;
      while (_supabase.auth.currentSession == null && retries < 5) {
        await Future.delayed(const Duration(milliseconds: 1000));
        retries++;
      }

      if (_supabase.auth.currentSession == null) {
         throw Exception('Session not found. Please verify your code again.');
      }

      final email = _supabase.auth.currentSession?.user.email ?? '';

      // 1. Update Supabase
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      
      // 2. Update Laravel Backend
      final backendSuccess = await _repository.resetPassword(
        email: email,
        code: 'recovery_link', 
        newPassword: newPassword,
      );

      if (!backendSuccess) {
        throw Exception('Password updated in Auth service but failed to sync with backend. Please contact support.');
      }
      
      _isPasswordRecoveryMode = false;
      _status = AuthStatus.unauthenticated; // Set to unauthenticated so they have to login
      
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.authenticated; 
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    if (_currentUser == null) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    try {
      final success = await _repository.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return success;
    } catch (e) {
      _status = AuthStatus.authenticated;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? address,
    String? avatarUrl,
    String? idImageUrl,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      String? finalAvatarUrl = avatarUrl;
      
      // 🚀 Handle avatar upload if bytes are present
      if (_avatarBytes != null && _storageRepository != null) {
        final fileName = 'avatar_${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        finalAvatarUrl = await _storageRepository!.uploadFile(
          fileBytes: _avatarBytes!,
          fileName: fileName,
          folder: 'avatars',
        );
        _avatarBytes = null; // Clear bytes after upload
      }

      final updatedUser = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        address: address,
        avatarUrl: finalAvatarUrl,
        idImageUrl: idImageUrl,
      );
      _currentUser = updatedUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      _avatarBytes = await image.readAsBytes();
      notifyListeners();
    }
  }

  Future<void> pickIdImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      _idImageBytes = await image.readAsBytes();
      notifyListeners();
    }
  }

  void togglePasswordVisibility() => notifyListeners(_obscurePassword = !_obscurePassword);
  void setAgreeToTerms(bool value) => notifyListeners(_agreeToTerms = value);
  void setRememberMe(bool value) => notifyListeners(_rememberMe = value);

  void reset() {
    _status = AuthStatus.initial;
    _currentUser = null;
    _isPasswordRecoveryMode = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void notifyListeners([dynamic _]) => super.notifyListeners();
  AuthorizationService? get authorizationService => _currentUser == null ? null : AuthorizationService(_currentUser!.role);
  String? get dashboardRoute => _currentUser == null ? null : RoleBasedRouter.getDashboardRoute(_currentUser!.role);
}

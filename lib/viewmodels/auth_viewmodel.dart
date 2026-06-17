import 'package:flutter/foundation.dart';
import 'dart:io';
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
import 'package:capstone_application/services/email_service.dart';

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
  final EmailService _emailService;
  final ActivityLogRepository? _activityLogRepo;
  final StorageRepository? _storageRepository;
  final LocalCacheService _cacheService = LocalCacheService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  String? _successMessage; 
  String? _pendingMfaEmail;
  bool _isInitialized = false;

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _rememberMe = false;
  
  Uint8List? _avatarBytes;
  String? _avatarName;

  Uint8List? _idImageBytes;
  String? _idImageName;

  AuthMFAEnrollResponse? _mfaEnrollResponse;
  List<dynamic> _mfaFactors = [];

  AuthViewModel(this._repository, this._emailService, [this._activityLogRepo, this._storageRepository]);

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage; 
  String? get pendingMfaEmail => _pendingMfaEmail;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isMfaRequired => _status == AuthStatus.mfaRequired;
  bool get isInitialized => _isInitialized;
  bool get obscurePassword => _obscurePassword;
  bool get agreeToTerms => _agreeToTerms;
  bool get rememberMe => _rememberMe;
  Uint8List? get avatarBytes => _avatarBytes;
  Uint8List? get idImageBytes => _idImageBytes;

  List<dynamic> get mfaFactors => _mfaFactors;
  AuthMFAEnrollResponse? get mfaEnrollResponse => _mfaEnrollResponse;

  String? get dashboardRoute {
    if (_currentUser == null) return null;
    return RoleBasedRouter.getDashboardRoute(_currentUser!.role);
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setAgreeToTerms(bool value) => _agreeToTerms = value;
  void setRememberMe(bool value) => _rememberMe = value;

  Future<void> logActivity(String action, String description) async {
    if (_currentUser != null && _activityLogRepo != null && _status == AuthStatus.authenticated) {
      try {
        final log = ActivityLogModel(
          id: '',
          userId: _currentUser!.id,
          action: action,
          ipAddress: kIsWeb ? 'Web Client' : 'Mobile App',
          createdAt: DateTime.now(),
          description: description,
        );
        await _activityLogRepo.logActivity(log);
      } catch (e) {
        debugPrint('DEBUG: [AuthViewModel] Background log failed (ignored): $e');
      }
    }
  }

  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await _repository.restoreSession();
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _mfaFactors = await _repository.listMfaFactors();
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
    _successMessage = null;
    notifyListeners();
    
    try {
      final result = await _repository.login(email: email.trim(), password: password);

      if (result != null) {
        UserModel? user = result['user'] as UserModel?;
        _successMessage = result['message'];

        if (user != null && (user.status == UserStatus.rejected || user.status == UserStatus.blocked)) {
          _status = AuthStatus.error;
          _errorMessage = 'Your account is ${user.status.name}.';
          notifyListeners();
          return false;
        }

        if (result['mfa_required'] == true) {
          _pendingMfaEmail = result['email'] ?? email;
          _currentUser = user; 
          _status = AuthStatus.mfaRequired;
          
          // 🚀 Trigger Email via dedicated EmailService
          if (_successMessage != null && (_successMessage!.contains('Code:') || _successMessage!.contains('Verification'))) {
             _emailService.sendNotification(
               email: _pendingMfaEmail!,
               subject: 'Login Verification Code',
               message: _successMessage!,
             );
          }
          
          notifyListeners();
          return false;
        }

        if (user == null) {
           _status = AuthStatus.error;
           _errorMessage = 'User profile not found.';
           notifyListeners();
           return false;
        }

        _currentUser = user;
        _status = AuthStatus.authenticated;
        _mfaFactors = await _repository.listMfaFactors();
        Future.microtask(() => logActivity('LOGIN', 'User logged in successfully'));
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

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      await logActivity('LOGOUT', 'User logged out');
      await _repository.logout();
      _cacheService.clearAll();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  void handleUnauthorized() {
    if (_status == AuthStatus.authenticated) {
      debugPrint('DEBUG: [AuthViewModel] Global 401 session clear.');
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Session expired. Please log in again.';
      _repository.clearLocalSession();
      _cacheService.clearAll();
      notifyListeners();
    }
  }

  Future<bool> verifyMfa(String code) async {
    if (_pendingMfaEmail == null) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _repository.verifyMfa(email: _pendingMfaEmail!, code: code, remember: _rememberMe);
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _pendingMfaEmail = null;
        _mfaFactors = await _repository.listMfaFactors();
        logActivity('MFA_VERIFIED', 'Verification successful');
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

  Future<bool> resendMfaCode(String email) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final success = await _repository.resendMfaCode(email);
      _status = AuthStatus.mfaRequired;
      notifyListeners();
      return success;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
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
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final result = await _repository.register(
        username: username.trim(),
        email: email.trim(),
        password: password,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        role: role,
      );

      _successMessage = result['message'];
      
      // 🚀 Trigger Email via dedicated EmailService
      if (_successMessage != null && (_successMessage!.contains('Code:') || _successMessage!.contains('Password:'))) {
        _emailService.sendNotification(
          email: email.trim(),
          subject: 'Welcome to PIL - Account Details',
          message: _successMessage!,
        );
      }

      if (result['mfa_required'] == true) {
        _pendingMfaEmail = result['email'];
        _status = AuthStatus.mfaRequired; 
        _currentUser = result['user'];
        notifyListeners();
        return true;
      }
      
      if (result.containsKey('user')) {
        _currentUser = result['user'];
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
      final updatedUser = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        address: address,
        avatarUrl: avatarUrl,
        idImageUrl: idImageUrl,
      );
      _currentUser = updatedUser;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.authenticated; // Keep authenticated even on error
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final success = await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return success;
    } catch (e) {
      _status = AuthStatus.authenticated;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> startMfaEnrollment() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _mfaEnrollResponse = await _repository.enrollMfa();
      _status = AuthStatus.mfaEnrollment;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.authenticated;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> finalizeMfaEnrollment(String code) async {
    if (_mfaEnrollResponse == null) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final challenge = await _repository.challengeMfa(_mfaEnrollResponse!.id);
      await _repository.verifyMfaChallenge(
        factorId: _mfaEnrollResponse!.id,
        challengeId: challenge.id,
        code: code,
      );
      _mfaFactors = await _repository.listMfaFactors();
      _mfaEnrollResponse = null;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.mfaEnrollment;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final result = await _repository.requestPasswordReset(email);
      _successMessage = result['message'];
      
      // 🚀 Trigger Email Notification via dedicated EmailService
      if (_successMessage != null && _successMessage!.contains('Code:')) {
        _emailService.sendNotification(
          email: email.trim(),
          subject: 'Password Reset Code',
          message: _successMessage!,
        );
      }
      
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return result['success'];
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({required String email, required String code, required String newPassword}) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final success = await _repository.resetPassword(email: email, code: code, newPassword: newPassword);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return success;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_status == AuthStatus.error) {
      _status = _currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _status = AuthStatus.initial;
    _currentUser = null;
    _errorMessage = null;
    _successMessage = null;
    _pendingMfaEmail = null;
    _isInitialized = false;
    notifyListeners();
  }
}

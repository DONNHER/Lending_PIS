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

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  String? _pendingMfaEmail;
  bool _isInitialized = false;

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _rememberMe = false;
  
  Uint8List? _avatarBytes;
  String? _avatarName;

  Uint8List? _idImageBytes;
  String? _idImageName;

  // Supabase MFA State
  AuthMFAEnrollResponse? _mfaEnrollResponse;
  List<dynamic> _mfaFactors = [];

  AuthViewModel(this._repository, [this._activityLogRepo, this._storageRepository]);

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
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

  AuthMFAEnrollResponse? get mfaEnrollResponse => _mfaEnrollResponse;
  List<dynamic> get mfaFactors => _mfaFactors;

  AuthorizationService? get authorizationService {
    if (_currentUser == null) return null;
    return AuthorizationService(_currentUser!.role);
  }

  String? get dashboardRoute {
    if (_currentUser == null) return null;
    return RoleBasedRouter.getDashboardRoute(_currentUser!.role);
  }

  bool canAccessRoute(String routeName) {
    if (_currentUser == null) return false;
    return RoleBasedRouter.hasAccess(_currentUser!.role, routeName);
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setAgreeToTerms(bool value) {
    _agreeToTerms = value;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<String> _getDeviceIp() async {
    try {
      if (kIsWeb) return 'Web Client';
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
      return 'Unknown IP';
    } catch (e) {
      return 'Error detecting IP';
    }
  }

  Future<void> logActivity(String action, String description) async {
    if (_currentUser != null && _activityLogRepo != null && _status == AuthStatus.authenticated) {
      try {
        final ip = await _getDeviceIp();
        final log = ActivityLogModel(
          id: '',
          userId: _currentUser!.id,
          action: action,
          ipAddress: ip,
          createdAt: DateTime.now(),
          description: description,
        );
        await _activityLogRepo.logActivity(log);
      } catch (e) {
        debugPrint('Suppressed ActivityLog Error: $e');
      }
    }
  }

  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await _repository.restoreSession();
      if (user != null) {
        if (user.status != UserStatus.active) {
          await logout();
          _errorMessage = 'Your account is ${user.status.name}.';
          _status = AuthStatus.error;
          return;
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
      final result = await _repository.login(
        email: email.trim(),
        password: password,
      );

      if (result != null) {
        UserModel? user = result['user'] as UserModel?;

        if (user != null && (user.status == UserStatus.rejected || user.status == UserStatus.blocked)) {
          _status = AuthStatus.error;
          _errorMessage = 'Your account is ${user.status.name}. Please contact administration.';
          notifyListeners();
          return false;
        }

        if (result['mfa_required'] == true) {
          bool shouldShowVerification = user == null || user.status != UserStatus.active || result['supabase_mfa'] == true;
          
          if (shouldShowVerification) {
            _pendingMfaEmail = result['email'] ?? email;
            _currentUser = user; 
            _status = AuthStatus.mfaRequired;
            if (result['supabase_mfa'] == true) {
               _mfaFactors = await _repository.listMfaFactors();
            }
            notifyListeners();
            return false;
          }
        }

        if (user == null) {
           _status = AuthStatus.error;
           _errorMessage = 'Login succeeded but user profile was not found.';
           notifyListeners();
           return false;
        }

        if (user.status == UserStatus.inactive) {
          try {
            user = await _repository.updateStatus(user.id, UserStatus.active);
          } catch (e) {
            debugPrint('Failed to activate user: $e');
          }
        }
        
        _currentUser = user;
        _status = AuthStatus.authenticated;
        await logActivity('LOGIN', 'User logged in successfully');
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
      if (_status == AuthStatus.authenticated && _currentUser != null) {
        try {
          await _repository.updateStatus(_currentUser!.id, UserStatus.inactive);
        } catch (e) {
          debugPrint('Failed to set status to inactive on logout: $e');
        }
        await logActivity('LOGOUT', 'User logged out');
        await _repository.logout();
      } else if (_status == AuthStatus.authenticated) {
        await _repository.logout();
      }
      await _cacheService.clearAll();
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void handleUnauthorized() {
    if (_status == AuthStatus.authenticated) {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Session expired. Please log in again.';
      _repository.clearLocalSession();
      _cacheService.clearAll();
      notifyListeners();
    }
  }

  Future<AuthMFAEnrollResponse?> startMfaEnrollment() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      _mfaEnrollResponse = await _repository.enrollMfa();
      _status = AuthStatus.mfaEnrollment;
      notifyListeners();
      return _mfaEnrollResponse;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
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
      await logActivity('MFA_SETUP', 'User successfully set up TOTP MFA');
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.mfaEnrollment;
      _errorMessage = 'Invalid TOTP code. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyMfa(String code) async {
    if (_pendingMfaEmail == null) return false;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      if (_mfaFactors.isNotEmpty) {
        final dynamic factor = _mfaFactors.firstWhere((f) => (f as dynamic).status.toString().contains('verified'));
        final challenge = await _repository.challengeMfa(factor.id);
        await _repository.verifyMfaChallenge(
          factorId: factor.id,
          challengeId: challenge.id,
          code: code,
        );
        _status = AuthStatus.authenticated;
        _pendingMfaEmail = null;
        notifyListeners();
        return true;
      }

      final user = await _repository.verifyMfa(
        email: _pendingMfaEmail!,
        code: code,
        remember: _rememberMe,
      );

      if (user != null) {
        if (user.status != UserStatus.active) {
          _status = AuthStatus.error;
          _errorMessage = 'Your account is ${user.status.name}.';
          _pendingMfaEmail = null;
          notifyListeners();
          return false;
        }

        _currentUser = user;
        _status = AuthStatus.authenticated;
        _pendingMfaEmail = null;
        await logActivity('MFA_VERIFIED', 'MFA verification successful');
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.mfaRequired;
        _errorMessage = 'Invalid MFA code.';
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
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
    notifyListeners();
    try {
      final result = await _repository.register(
        username: username.trim(),
        email: email.trim(),
        password: password,
        firstname: firstName.trim(),
        lastname: lastName.trim(),
        role: role,
      );

      if (result['mfa_required'] == true) {
        _pendingMfaEmail = result['email'];
        _status = AuthStatus.mfaRequired; 
        if (result.containsKey('user')) {
           _currentUser = result['user'];
        }
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

  Future<void> pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        _avatarBytes = await image.readAsBytes();
        _avatarName = image.name;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
    }
  }

  Future<void> pickIdImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        _idImageBytes = await image.readAsBytes();
        _idImageName = image.name;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking ID image: $e');
    }
  }

  Future<bool> updateProfile({
    required String firstName, 
    required String lastName,
    String? address,
  }) async {
    if (_currentUser == null) return false;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      String? avatarUrl = _currentUser!.avatarUrl;
      if (_avatarBytes != null && _storageRepository != null) {
        avatarUrl = await _storageRepository!.uploadFile(
          fileBytes: _avatarBytes!,
          fileName: 'avatar_${_currentUser!.id}.jpg',
          folder: 'avatars',
        );
        avatarUrl = '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      String? idImageUrl = _currentUser!.idImageUrl;
      if (_idImageBytes != null && _storageRepository != null) {
        idImageUrl = await _storageRepository!.uploadFile(
          fileBytes: _idImageBytes!,
          fileName: 'id_${_currentUser!.id}.jpg',
          folder: 'id-images',
        );
        idImageUrl = '$idImageUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }
      
      final updatedUser = await _repository.updateProfile(
        firstname: firstName,
        lastname: lastName,
        address: address,
        avatarUrl: avatarUrl,
        idImageUrl: idImageUrl,
      );
      
      _currentUser = updatedUser;
      _avatarBytes = null;
      _avatarName = null;
      _idImageBytes = null;
      _idImageName = null;
      _status = AuthStatus.authenticated;
      await logActivity('PROFILE_UPDATE', 'User updated their profile information');
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final success = await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _status = AuthStatus.authenticated;
      if (success) {
        await logActivity('PASSWORD_CHANGE', 'User successfully changed their password');
      }
      notifyListeners();
      return success;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final success = await _repository.requestPasswordReset(email);
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

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final success = await _repository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
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
    _pendingMfaEmail = null;
    _isInitialized = false;
    _mfaEnrollResponse = null;
    _mfaFactors = [];
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/activity_log_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/activity_log_repository.dart';
import '../repositories/storage_repository.dart';
import '../services/authorization_service.dart';
import '../services/role_based_router.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  mfaRequired,
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  final ActivityLogRepository? _activityLogRepo;
  final StorageRepository? _storageRepository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  String? _pendingMfaEmail;

  bool _obscurePassword = true;
  bool _agreeToTerms = false;
  bool _rememberMe = false;
  
  Uint8List? _avatarBytes;
  String? _avatarName;

  AuthViewModel(this._repository, [this._activityLogRepo, this._storageRepository]);

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get pendingMfaEmail => _pendingMfaEmail;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isMfaRequired => _status == AuthStatus.mfaRequired;
  bool get obscurePassword => _obscurePassword;
  bool get agreeToTerms => _agreeToTerms;
  bool get rememberMe => _rememberMe;
  Uint8List? get avatarBytes => _avatarBytes;

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
    if (_currentUser != null && _activityLogRepo != null) {
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
    }
  }

  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final user = await _repository.restoreSession();
    if (user != null) {
      _currentUser = user;
      _status = AuthStatus.authenticated;
      await logActivity('SESSION_RESTORED', 'User session was automatically restored');
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
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
        if (result['mfa_required'] == true) {
          _pendingMfaEmail = result['email'];
          _status = AuthStatus.mfaRequired;
          notifyListeners();
          return false; // Not fully logged in yet
        }
        
        _currentUser = result['user'];
        _status = AuthStatus.authenticated;
        final ip = await _getDeviceIp();
        final platform = kIsWeb ? 'Chrome/Web' : Platform.operatingSystem;
        await logActivity('LOGIN', 'Logged in via $platform (IP: $ip)');
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

  Future<bool> verifyMfa(String code) async {
    if (_pendingMfaEmail == null) return false;

    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final user = await _repository.verifyMfa(
        email: _pendingMfaEmail!,
        code: code,
        remember: _rememberMe,
      );

      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _pendingMfaEmail = null;
        final ip = await _getDeviceIp();
        await logActivity('MFA_VERIFIED', 'MFA verification successful (IP: $ip)');
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
      _currentUser = await _repository.register(
        username: username.trim(),
        email: email.trim(),
        password: password,
        firstname: firstName.trim(),
        lastname: lastName.trim(),
        role: role,
      );

      if (_currentUser != null) {
        _status = AuthStatus.authenticated;
        await logActivity('REGISTER', 'New user account created for $firstName $lastName');
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
    await logActivity('LOGOUT', 'User logged out');
    await _repository.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
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

  Future<bool> updateProfile({required String firstName, required String lastName}) async {
    if (_currentUser == null) return false;
    
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      String? avatarUrl = _currentUser!.avatarUrl;

      if (_avatarBytes != null && _storageRepository != null) {
        avatarUrl = await _storageRepository!.uploadFile(
          fileBytes: _avatarBytes!,
          fileName: 'avatar_${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          folder: 'avatars',
        );
      }

      final updatedUser = await _repository.updateProfile(
        firstname: firstName,
        lastname: lastName,
        avatarUrl: avatarUrl,
      );

      _currentUser = updatedUser;
      _avatarBytes = null;
      _avatarName = null;
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
    _obscurePassword = true;
    _agreeToTerms = false;
    _rememberMe = false;
    _avatarBytes = null;
    _avatarName = null;
    _pendingMfaEmail = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/authorization_service.dart';
import '../services/role_based_router.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  AuthViewModel(this._repository);

  // ─── Getters ───────────────────────────────────────────────────────────
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get obscurePassword => _obscurePassword;
  bool get agreeToTerms => _agreeToTerms;

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

  // ─── UI State ──────────────────────────────────────────────────────────
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setAgreeToTerms(bool value) {
    _agreeToTerms = value;
    notifyListeners();
  }

  // ─── Session Restore ───────────────────────────────────────────────────
  /// Call this on app launch to resume a previous session automatically.
  /// If a valid Supabase session exists, the user won't need to log in again.
  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final user = await _repository.restoreSession();
    if (user != null) {
      _currentUser = user;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ─── Login ─────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repository.login(
        email: email.trim(),
        password: password,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred.';
      notifyListeners();
      return false;
    }
  }

  // ─── Register ──────────────────────────────────────────────────────────
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String middleName,
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
        middlename: middleName.trim(),
        role: role,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred.';
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _repository.logout(); // signs out from Supabase Auth
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────
  void clearError() {
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
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
    notifyListeners();
  }
}